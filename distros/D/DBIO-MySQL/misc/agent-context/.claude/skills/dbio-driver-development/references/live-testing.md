# Live testing — resource discipline

Binding in every DBIO distribution; cited as *live-testing rule N*. Live/integration tests
run against real databases, which a suite is handed through its `DBIO_TEST_*` variables.
Every driver gets its live database itself; the maintainer's own infrastructure is the
last section, *Maintainer-only live infrastructure*.

The suites run on the development machine, which several agent sessions may share. Two
things need protecting: a database from two runs at once, and that machine from a run
that takes more than its share (rule 9).

1. **One run per database at a time.** Several databases may be up and under test at
   once, and one session may start several suites at the same time (maintainer's
   decision 2026-10-09) — the resource caps bound that (rule 4), not a count, and every run
   goes through `capped-test` (rule 9). What must not overlap is two runs against the
   *same* database: a suite works in the one database it is given, so a second run
   against it fails both, with errors that read like driver bugs. A pod can hold
   several databases: on the shared PostgreSQL every repo works in a database of its
   own (core: `dbio_core`), never in the shared default `dbio_test`, so the
   suites of different repos may run side by side. Within one repo and one database
   the rule stands. This holds across sessions and subagents, and no tool checks it
   for you: never fan out agents that each drive a suite against the same database.
2. **Never parallelise the harness** on live suites: no `prove -j`, no
   `HARNESS_OPTIONS=j<N>` with N>1. The files of a suite share its database; running
   them side by side is rule 1 broken inside a single run.
3. **The standing databases stay up; what a run starts itself, it removes.** A standing
   database is not a run's to start and delete; it is left up when the run is done. A run
   that needs a pod of its own removes what it created; an interrupted one leaves it
   holding quota, and rule 7 finds it.
4. **Every DB container carries a cpu AND memory cap** — `resources.limits`
   in a k8s manifest, `mem_limit` + `cpus` in a compose file (`deploy.resources`
   is silently ignored outside swarm, so a file using it looks capped and runs
   unbounded). Every checked-in spec in the family does; `DBIO::Test::Kubernetes`
   refuses to build a container without one rather than defaulting quietly. A database
   under Docker has nothing but its own file. Never `kubectl run` or `docker run` an unlimited DB.
5. **No background waiter / poll loops.** No backgrounded `kubectl wait`, no
   sleep-poll loop, no `run_in_background` test left spinning. Check once, act on
   the result; a bounded foreground `kubectl wait` is fine.
6. Offline mock tests (`prove -lr t/`, no `DBIO_TEST_*` DSN) touch no database and
   are the default. They run on the same shared machine, so rule 9 applies to them
   too; several suites may run at once, each under its own cap. Rules 1–5 and 7 are
   specifically for runs against real databases.
7. **Run `maint/live-preflight` (in core) before a live suite on the maintainer's
   cluster.** It refuses the run when a container carries no cap, when a database is not
   Ready, when an interrupted run has left objects behind, or when the route to the
   project address is broken; exit 2 means it could not look at all and is not a pass.
   It reads only; every finding names the command that deals with it.
8. **Fan-out of background agents across repos is bounded too, for non-DB work.**
   Many parallel `Agent` calls, each ending in its own `karr move`/`karr handoff`/
   `karr sync` (or any other mutating git/network operation) at roughly the same time,
   OOM-rebooted the host (confirmed 2026-07-14: 8 concurrent cross-repo fix agents each
   calling `karr move ... review`). The single command is cheap (`karr handoff` alone:
   ~46MB RSS, ~18s); N of them landing together is not — concurrency is the danger.
   When a task fans out across repos (e.g. rolling one fix out to every DBIO driver),
   keep the *implementation* parallel if you like, but serialize the `karr` mutation
   step afterward: collect the results, then call `karr move`/`handoff`/`sync` for
   each ticket one at a time in a single sequential loop.
9. **Run every suite through `maint/capped-test` (in core)** — live *and* offline
   mock, from every repo. Like `live-preflight` it lives in core only and needs no
   per-repo copy: it wraps a command in the current directory, so a driver dist
   calls it by path (`../dbio/maint/capped-test dzil test`). It puts the run in a
   systemd scope with `MemoryMax` (default 2G, raise per-run with
   `DBIO_TEST_MEMMAX=4G`), `MemorySwapMax=0`, `CPUQuota=200%`, and nice/ionice, and it
   refuses to start at all — exit 99, never 1 or 2 — if the cap cannot be established.
   It does not take systemd's word for that: the command is started only after
   `memory.max` and `memory.swap.max` have been read back inside the scope. Where
   `live-preflight` asks "are the databases fit to run against", this asks "and what
   may the run consume on this machine". Use it as a plain prefix:

   ```
   maint/capped-test                            # in core: prove -lr t/
   ../dbio/maint/capped-test dzil test          # in a driver dist
   maint/live-preflight && maint/capped-test prove -lr t/    # live run: both
   ```

   The reason is not that the suites are heavy — measured 2026-08-21, core's full
   226 files / 28021 tests peak at **183 MB**, under a third of one agent process.
   It is that "the tests are innocent" is enforced by the kernel rather than
   re-established by forensics after every freeze. The host has 15 GB RAM
   **and ~14 GB swap** (part of it zram), so the cap covers both. RAM alone is
   not a cap here: a runaway run is then not killed at its limit but paged out —
   on 2026-10-07 one sat at exactly its 2G while 2.9G of it went to swap, zram
   filled to 98% and the whole machine stalled until the run was killed by hand
   (karr k323). With swap at 0 the kernel's OOM killer ends the offending process
   at the limit; under `prove` that is the one test file, which fails with wait
   status 9 while the rest of the suite runs on, and the closing line of
   capped-test says the run hit the cap. A run that needs more room gets it as RAM
   (`DBIO_TEST_MEMMAX`), never as swap. Each run also prints its own peak. The freeze
   on 2026-08-21 14:19 was an rke2 crash-loop (1663 restarts, 2.7 GB peak each) plus
   six concurrent agent sessions (rule 8); no DBIO test was running at all.

## Maintainer-only live infrastructure

Applies to the maintainer's own setup only. Otherwise each driver gets its live database
itself, through the `DBIO_TEST_*` variables, and the live-testing rules hold unchanged.

Live/integration tests run against real databases that stand in the HQ cluster `cihq`,
in the project namespace `dev-dbio`, each behind a LoadBalancer service on the one
project address `dbio.dev.cihq` — no port-forward. `dbio-db` manages them, from the
manifests the driver repos carry, and hands a suite its `DBIO_TEST_*`:

```
# <cihq-ocp> = your checkout of the cihq-ocp repo (next to the DBIO family directory: ../../cihq-ocp from a DBIO repo)
<cihq-ocp>/umgebungen/dbio/dbio-db list | up <db>… | env <db> | down <db>…
eval "$(<cihq-ocp>/umgebungen/dbio/dbio-db env <db>)"
```

The access is `~/.kube/cihq-dev-dbio.yaml`; its token lasts seven days and is renewed
with `<cihq-ocp>/bin/cihq-dev token dbio`. It is confined to the namespace — role
`edit`, pod security `baseline`, a ResourceQuota and a LimitRange — and can neither
create a namespace nor see nodes or other namespaces. Db2 is not there: it needs a
privileged container, which `baseline` refuses, and runs under Docker on `pikachu`.
The workers on `kaiser` are x86-64-v2 (no AVX2); an image that needs v3 has to run on
`raichu`.

In `dev-dbio` the cluster holds the line on caps (rule 4) as well: the LimitRange gives a
container that names no limit a default one, and the ResourceQuota bounds what the
namespace holds in total.

**Standing databases (rule 3).** The databases in `dev-dbio` are managed through
`dbio-db` and are left up when the run is done. A run that needs a pod of its own puts
it into `dev-dbio` as well, through `DBIO::Test::Kubernetes` with `existing_namespace`
(`xbin/k8s-test --existing-namespace dev-dbio`, in core): the account cannot create a
namespace, and in a shared one every object must carry the id of its run, which is what
that mode does. Such a run removes what it created; an interrupted one leaves it
holding quota, and rule 7 finds it.

**Preflight (rule 7).** It looks at the project namespace with the project access and
refuses the run when a container carries no cap, when a database is not Ready, when an
interrupted `DBIO::Test::Kubernetes` run has left objects behind, or when the route from
this machine to the project address goes into a local docker bridge. That last one is
invisible from the database side — a docker network whose range covers the address
takes the route, and every database looks dead from here while it is fine. It lists the
databases that are up and prints the quota; whether somebody else is running against a
database (rule 1) it cannot see. Exit 2 means it could not look at all — no access,
token expired — and is not a pass. It reads only; every finding names the command that
deals with it.
