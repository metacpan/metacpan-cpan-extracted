---
name: dbio-coordination
description: Use when work in one DBIO repo touches another — which repo owns what, and how to hand a ticket to another repo's board.
user-invocable: false
allowed-tools: Read, Bash, Glob
model: sonnet
---

# DBIO Cross-Repo Coordination

The DBIO family is **many independent CPAN distributions**, each its own Git repo. There is no central workspace. Coordination happens two ways: `karr` tickets pushed to repo remotes and picked up by the receiving repo's agent, or — for a block of dependent work that needs one head — by starting a Claude inside the target repo directly (see *Direct cross-repo execution*).

## Repo ownership

| Concern | Owning repo |
|---------|-------------|
| Schema, ResultSet, Row, Cursor, SQLMaker core | `dbio` |
| Test infrastructure (`DBIO::Test::Storage`, mocks) | `dbio` |
| Storage::DBI base class, Storage::Async base | `dbio` |
| Driver registration, capability system docs | `dbio` |
| Driver-specific Storage (Pg/MySQL/SQLite/…) | `dbio-<driver>` |
| Driver-specific SQLMaker (JSONB ops, CONNECT BY) | `dbio-<driver>` |
| DB-version capability detection per driver | `dbio-<driver>` |
| Cake driver flags (`cake_defaults`) | `dbio-<driver>` |
| Shared Future::IO async base (`DBIO::Async::Storage`, the `future_io` mode) | `dbio-async` |
| `future_io` adapter `DBIO::<Driver>::Storage::Async` | `dbio-<driver>` |
| Native `ev` transport `DBIO::<Driver>::EV` (Pg, MySQL) | `dbio-<driver>-ev` |
| `forked` mode (`DBIO::Forked`) | `dbio-forked` |
| Dist::Zilla bundle `[@DBIO]` | `dbio-dzil` |
| Family skills (this one included), house rules, shared agents | `dbio` (skilletor source `dbio-core`; every other repo installs them) |
| Shared DDL case table `DBIO::Test::Conformance`, `AsyncHarness`, `StorageLayer`, `Kubernetes`, `maint/capped-test`, `maint/live-preflight` | `dbio` |
| Driver's conformance subclass `DBIO::<Driver>::Test::Conformance` (ADR 0060) | `dbio-<driver>` |
| Extensions over a driver (AGE, PostGIS, GraphQL) | `dbio-postgresql-age`, `dbio-postgresql-postgis`, `dbio-graphql` |
| Tombstones of retired module names | `dbio-deprecated` |

## Decision rule when a ticket arrives

```
ticket is about SQL gen abstraction / Storage API / Schema / Test::Storage
  → keep in dbio
ticket is about DB-specific bug / feature / capability
  → push to dbio-<driver>
ticket is about release tooling / dist.ini bundle
  → push to dbio-dzil
ticket needs change in both core + driver
  → split into two tickets, link via tags, set-refs or karr's native `--needs BOARD#ID`
  a driver case for the shared case table
  → one card in core (the case) plus one card per driver
```

## Cross-repo handoff via karr

There is **no shared karr board**. Each repo has its own `refs/karr/*`. Cross-repo handoff = create a ticket in another repo's remote and let its agent pick it up.

### Posting a ticket to another repo

From inside repo A, to post a ticket to repo B:

```bash
# Option 1: CD into the other repo locally (fast, no network)
( cd ../dbio-postgresql \
  && karr create "Add JSONB @? operator" \
       --priority high \
       --body "Originated from dbio core ticket k42. Needed by SQLMaker test t/sqlmaker/json.t." \
  && karr sync --push )

# Option 2: If remote-only (other repo not checked out)
git push <other-repo-remote> refs/karr/tasks/<new-id>/data
```

The receiving agent picks it up on its next `karr-foundation` run via `karr sync --pull`.

### Loop prevention

Loops would only happen if agents ping-pong tickets back and forth. Prevent by:

1. **Always read existing tickets first** — `karr list` shows all open work and includes prior cross-repo notes. If a ticket already exists pointing to this work, comment on it via `karr edit` instead of creating a new one.
2. **Tag cross-repo tickets** with `from:<source-repo>` and the originating ticket ID — receiving agent can see the chain.
3. **Use `karr set-refs` for shared plan documents** that several agents need to read without each creating a new ticket.
4. **One agent claims the chain end-to-end** when feasible — fewer handoff hops = less drift.

### Handoff back

When repo B completes the work:

```bash
karr handoff <id> --claim "$(karr agentname)" \
  --note "Done. Commit abc123 in dbio-postgresql." \
  --timestamp

# Optionally notify origin repo
( cd ../dbio \
  && karr edit <originating-ticket-id> \
       -a -t "Resolved downstream in dbio-postgresql ticket kN (commit abc123)" )
```

## Direct cross-repo execution — one block, one head

Ticket-and-wait works for independent work. It does not work for a **block**: one head
ticket (usually in core) plus the driver-side tickets that depend on it. Split across
detached agents, nobody holds the connection between them and the block drifts. For a
block, the coordinating agent drives every repo in one pass.

The rule here was never "no cross-repo work". It is **no _unbriefed_ cross-repo work** —
this repo's agent, carrying this repo's context, must not edit a driver repo whose
conventions it was never briefed on. That prohibition stands unchanged. What is new is
that a briefed path exists: **start a Claude inside the target repo.** It comes up with
that repo's `CLAUDE.md`, its house rules under `.claude/rules/`, its agents and its skills —
fully briefed, which a subagent spawned from here never is.

**Who does this:** the coordinating main agent — the one holding the block and its
context. A worker agent never starts a target-repo Claude: when it needs downstream
work it files a ticket, exactly as before.

### The call

Spawn Claude headless inside the target repo:

```bash
( cd ../dbio-mysql-ev \
  && claude -p "$PROMPT" \
       --model <exact-id> \
       --permission-mode bypassPermissions \
       --max-turns 40 ) 2>&1 \
    | tee <scratchpad>/xrepo-dbio-mysql-ev.log
```

Three flags matter:

- `--model <exact-id>` — the exact ID from the system prompt, not a family alias. A
  child claude does not inherit the parent session's model; without `--model` it reads
  the user default from the user's Claude settings. `--model` defaults to the model
  this session runs on; deviate only on the maintainer's explicit instruction (house rules).
- `--permission-mode bypassPermissions` — print mode cannot ask for permission, so
  unapproved tool calls deny. Only run inside the target-repo working tree.
- `--max-turns 40` — bound the runaway; tune per task.

The limits therefore come from the prompt and from the scope below, not from the
permission layer. Log to the scratchpad, not into the repo (`.karr.log` belongs to
karr-foundation).

### The prompt

Name all four or the run drifts:

1. **The ticket** — its ID *on the target repo's board*. `karr show <id>` is the run's first move.
2. **Why it exists** — the head ticket, its repo, and what was decided there. The target
   agent cannot see the coordinating conversation; anything it needs must be in the prompt.
3. **The scope** — implement, test, commit locally; do NOT `git push`, do NOT release.
4. **Who does it** — the repo's own worker (`dbio-worker-<db>`), so the local briefing applies.

### Scope of a target-repo run

Allowed: read, implement, run the offline suite, `git commit` locally, and move its karr
ticket (`karr move` / `karr handoff` — board mutations auto-sync, and that is fine: the
board is coordination state, not code).

Not allowed: `git push`, `dzil release`, any CPAN upload and any Codeberg action. Code leaves the machine only on the maintainer's decision, after the
block report.

**Report the suite, not your own file.** A run reports the result of the whole recursive
suite — including failures it did not cause. A pre-existing red test is a finding to hand
back, never something to pass over because "my change is green". The coordinating agent
re-runs the suite anyway, so a run that claimed green while `Result: FAIL` stood spends the
trust the whole arrangement rests on, and buys nothing. Establish whether a failure predates
the run before reporting it — a throwaway worktree on the previous commit settles it in a
minute:

```bash
git worktree add -q --detach "$TMPDIR/wt-prev" HEAD~1
( cd "$TMPDIR/wt-prev" && prove -l t/the-failing-file.t )   # same failure = not yours
git worktree remove --force "$TMPDIR/wt-prev"
```


### Running a block

1. **Core first.** Finish the head ticket, verify with `prove -lr t/` (recursive!), then
   `dzil install` so the drivers pull the current core.
2. **One repo at a time, serially.** Never two target-repo Claudes at once — same
   discipline as live testing, same reason: concurrent runs have OOM-rebooted this box.
3. **Live suites follow the live-testing rules**: one run per database at a time (every repo
   has its own database on the shared PostgreSQL, so runs of different repos may overlap),
   the harness serial, every run through `maint/capped-test`.
4. **On failure, keep going.** A failed repo does not stop the others: mark it with
   `karr edit <id> --block "<reason>"` and move on. Dependents of the failed repo are
   skipped; siblings are not.
5. **Report at the end** — per repo: what landed (commit ids), what is blocked and why,
   what still needs a push. Never call a block done while any part of it is blocked.

## Shared plan storage via set-refs

For plans / specs that multiple repos need to consult but shouldn't be a ticket:

```bash
karr set-refs dbio/plan/jsonb-operators.md <<'EOF'
# JSONB operator addition plan
...
EOF

# Other repos pull:
karr get-refs dbio/plan/jsonb-operators.md
```

Pushes via `karr sync --push`. Other repos see it after their `karr sync --pull`.

## Multi-machine / distributed teams — karr-foundation

Each maintainer's machine has its own clone of each DBIO repo. karr refs are synced via Git remotes. `karr-foundation` (ships with App::karr) is a single-shot CLI that scans configured boards, pulls, and **drains** each board that changed or has open work — it runs the configured headless agent command repeatedly until no actionable task remains. Invoke from cron/timer or manually; with a token-budgeted subscription, deliberate manual runs are the intended cadence.

```bash
karr-foundation --status              # read-only overview of every board, never runs agents
karr-foundation                       # scan, then drain boards with changes/open work
karr-foundation --dry-run --verbose   # preview without executing
```

Config: the user-level karr-foundation `config.yml` — `dirs:` (explicit repos) and/or `scan:` (parent dirs; every child with a `.karr` file or karr refs counts). Agent execution is opt-in per repo via its `.karr` file: `claude: true` synthesizes the canonical headless call (`claude -p "$PROMPT" --permission-mode bypassPermissions --max-turns N`), `prompt:` sets the instruction, `command:` overrides entirely. Each run is classified (progress / stall / common-error / idle): stalled tasks are auto-blocked after `max_attempts`, API/network errors put the repo in exponential cooldown, a lock file keeps concurrent runs safe.

Caveat: a global `default_command` in config.yml wins over every repo's `.karr` and turns EVERY discovered board into an agent board — a repo cannot opt out. Prefer per-repo `.karr` files and leave boards that must not be touched without agent config. A board can also opt out in its own karr state: `karr disable --reason "…"` writes `foundation.enabled` to `refs/karr/config`, so it syncs with the board and every foundation instance honours it — it wins over `--command`, `default_command`, the `.karr` `command` and `claude: true`, and `--force` does not override it.

## What NOT to do

- ❌ Edit another repo's files yourself — by hand or through a subagent spawned here. A subagent carries *this* repo's briefing, not the target's. Start a Claude **in** the target repo instead (see *Direct cross-repo execution*), or file a ticket.
- ❌ Run several target-repo Claudes at once. One repo at a time, serially.
- ❌ Push code out of a target-repo run. Local commit is the end of its scope; the push is the maintainer's call.
- ❌ Create a ticket without first checking if one already exists for the same work.
- ❌ Hold a claim across long-running cross-repo waits — release the claim and let the originating agent pick it up again when downstream is done.
- ❌ Treat the directory that holds the DBIO checkouts as a workspace root. It only holds the independent checkouts side by side — no shared repo, no shared board. Each repo is independent.
- ❌ Edit a file skilletor installed — `.claude/agents/.local.*`, `.claude/rules/.local.*`, a skill dir carrying a `.gitignore`. The next `skilletor sync` overwrites it. Change it in its source repo (family skills, house rules and shared agents: `dbio` core), then `skilletor sync` where it is installed; from a driver that is a ticket on core's board.
- ❌ Assume a fresh clone is briefed. The installed skills, the house rules and the shared agents are git-ignored; they exist only after `skilletor sync`.
