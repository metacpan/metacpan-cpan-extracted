# CLAUDE.md — DBIO::Forked

This distribution tracks only its own `dbio-forked` skill and `dbio-worker-forked` agent;
the family skills, the shared agents and `.claude/rules/` are installed from core through
skilletor. The family-wide house rules (discipline, delegation, release) live in
`.claude/rules/.local.dbio-rules.md` — auto-loaded by Claude Code for the main agent and
all subagents.

**Fresh clone or worktree: run `skilletor sync` first.** Everything installed (skills,
rules, shared agents) is git-ignored, so none of it exists until the sync has run; it
needs the skilletor plugin/CLI and network access to github.com (`Getty/skills`,
`Getty/karr`) and codeberg.org (`dbio/dbio`). Never edit an installed copy — change it in
core and sync again.

## Delegation

Delegate behaviour-relevant code (the `DBIO::Forked::Storage` fork-per-query
backend, `DBIO::Forked::Future`, tests) to this repo's `dbio-worker-forked`
instead of touching it yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-forked` (default),
`dbio-adr-auditor`, `dbio-release-manager`, `karr-coordinator`.

## Core Concept: generic fork-per-query async backend

`DBIO::Forked` makes **any** sync DBIO driver async without an async-capable
client and without an event loop. It is a **sibling** of `dbio-async`, not a
layer over it: both fulfil the core `DBIO::Storage::Async` contract, but —

- `dbio-async` = `Future::IO` + an async client (PG/MySQL native async).
  Efficient; only for drivers with a non-blocking client.
- `dbio-forked` = `fork()` + pipe + the ordinary sync driver run in a child.
  Universal — covers the ~13 drivers that will never get a native async client
  (Oracle, db2, Sybase, SQLite, …).

```
core DBIO::Storage::Async  (abstract contract, loop-free)
        ↑ subclass                         ↑ subclass
DBIO::Async::Storage          DBIO::Forked::Storage
(Future::IO + async client)   (fork + pipe, dependency-free)   <-- THIS DIST
```

## Activation — the explicit `forked` async mode (core ADR 0030)

Loading the module registers a generic `forked` async mode on the core base
storage class (`DBIO::Storage::DBI->register_async_mode`), so every driver
inherits it; a connection opts in explicitly at `connect` time with
`{ async => 'forked' }`. Nothing is auto-wired and nothing degrades silently:
without the mode a connection stays fully synchronous (its `*_async` methods
croak), there is no fallback chain, and asking for `forked` without
`dbio-forked` installed croaks loudly.

## How Model A runs a query

`*_async` → `_run_forked`: `pipe` + `fork`; the **child** runs the inherited
primary sync storage's ordinary sync CRUD (`$schema->storage->$op`), whose
inherited `_verify_pid` fork handling reconnects fresh (through the AccessBroker
too) — so Forked rebuilds no SQL, touches no DBI handle, replays no connect_info,
and calls the **sync** method (no re-fork). Rows are `Storable`-frozen over the
pipe; the parent returns a `DBIO::Forked::Future`. That same reconnect also
re-runs `on_connect_do` / `on_connect_call` in the child (`_connect` →
`_run_connection_actions`) — free, no code here, ADR 0002 addendum.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::Forked` | Dist entry point (loadable, no behaviour) |
| `DBIO::Forked::Storage` | Fork-per-query async backend (extends core `DBIO::Storage::Async`) |
| `DBIO::Forked::Future` | Loop-free, pipe-backed Future; full `DBIO::Future::Immediate`-compatible `future_class` surface (`done`/`fail`/`needs_all`/`and_then` + the minimal `DBIO::Future` contract) |

## Hard boundary + dependencies

Ships **no** DB-specific code, re-implements **no** SQL — the real driver does it
in the child. **Dependency-free**: only core Perl (`fork`, `pipe`, `Storable`,
`IO::Select`) + DBIO core. No `Future` / `Future::IO`, no event loop. That is the
whole point: a driver gets fork-based async without pulling the async ecosystem.

## Known limits (Model A)

- Pipe-buffer ceiling (~64 KB): large result blobs block the child until the
  parent reads. Argument for a future Model B (worker pool + streaming).
- No pool, no transaction pinning across separate `*_async` calls.
  `txn_do_async` runs a whole transaction in one child; its body must return
  serializable data (not live Row objects — caught as a failed Future) and must
  be sync-only (no `*_async` inside, which would re-fork).
- **No transport capability a layer could require — by intent, not a gap.** Model
  A overrides the six `*_async` directly and runs sync CRUD in the child, so
  there is no `_query_async` seam for an async storage layer to wrap. Core's
  capability gate therefore croaks for any layer that declares a requirement in
  `required_transport_capabilities` and for any that declares nothing at all
  (only an explicit empty list exempts a layer), and that is correct: the layer
  would compose and then silently do nothing. Never "fix" it by advertising a
  capability (least of all `on_connect_replay`, which names a pool-transport
  promise). A forked-aware layer would need its own capability axis — a
  core/family decision.
  POD: `DBIO::Forked::Storage`, "TRANSPORT CAPABILITIES AND ASYNC LAYERS".
- **Exactly one capability, read by core: `broker_connect_options`** (core k243).
  It lets a broker-backed connection carry DBD attributes and `pool_size` beside
  the broker — `connect($broker, { async => 'forked', … })` — instead of being
  refused at first async use. Kept with no code: the child's connection is the
  owner storage's own, reconnected through the broker with the options joined
  in; `pool_size` sizes nothing (no pool). No layer asks for it, so it is no
  precedent for the point above. ADR 0002 addendum 2026-10-04,
  `t/06-broker-connect-options.t`.
- **Rotating broker, expired lease in the parent: every forked query refreshes.**
  A refresh in the child dies with the child. If the parent holds an expired
  lease and issues only `*_async`, each query makes its child read the vault and
  take a new lease (one read per query with `DBIO::AccessBroker::Vault`); the
  parent's broker stays unchanged until the parent itself reconnects, after
  which its children inherit the new lease. With a good lease nobody reads.
  Follows from Model A; pinned in `t/09-broker-in-child.t` section 3. Having the
  parent refresh before it forks is not implemented. POD:
  `DBIO::Forked::Storage`, "ROTATING BROKERS AND AN EXPIRED LEASE".
- Unix fork only.

## Version policy

**Every** shipped `.pm` under `lib/` carries a literal `our $VERSION`, all of them
the same value — bare `[@DBIO]`, versioned via `@Git::VersionManager`, whose
RewriteVersion/BumpVersionAfterRelease run `global = 1` over `[:InstallModules]`
and so rewrite and bump every module in lockstep. Do not strip one from a
skeleton module. **No `heritage`** in dist.ini — new code, not
DBIx::Class-derived (like `dbio-postgresql-async` / `dbio-mysql-async`).

## ADRs

- 0001 — generic fork-per-query async backend (+ addendum: its activation model,
  core ADR 0028/0029, is superseded by the explicit `forked` mode of core ADR
  0030; the decision itself stands)
- 0002 — the forked child reuses the inherited sync storage (+ addendum: the
  child's reconnect re-runs the connection actions; why that is not
  `on_connect_replay`; + addendum: the one declared capability,
  `broker_connect_options`, read by core)
- 0003 — loop-free pipe-backed Future, EOF-framed, and its size limit
  (+ addendum: the premise of the full `future_class` surface changed — the
  withdrawn core ADR 0029 chain — the decision itself stands;
  `DBIO::Test::Future` is now `DBIO::Future::Immediate`)

See `.claude/skills/dbio-forked/SKILL.md` for the full architecture.

## Testing

Offline is the default and the whole suite without a DSN: no database server, no event
loop. `t/05-sqlite-live.t` and the SQLite part of `t/11-live-transport.t` run a real
DBD::SQLite file database and skip without the driver. Live: `t/11-live-transport.t`
also drives PostgreSQL when `DBIO_TEST_PG_DSN` (+ `_USER`/`_PASS`) is set; this repo's
database on the shared server is `dbio_forked`, never the default `dbio_test`. Where the
database comes from is the live-testing section of the house rules. Run recursively,
always through the wrapper (house rule 9):

```bash
../dbio/maint/capped-test prove -lr t/
```

(`prove -l t/` is not recursive and skips subdirectories; use it only on a single file.)

Tests cover the fork-per-query roundtrip via a mock sync storage, the loop-free
Future contract (EOF-clean `is_ready`, blocking `get`, lazy `then`/`catch`, error
propagation, no zombies), and load. Further offline files: `t/04` the full
`future_class` surface; `t/05-sqlite-live.t` real SQLite handle (skips without
DBD::SQLite); `t/06` connect options beside a broker; `t/07` the transport
paths (all six `*_async`, `txn_do_async` failure modes); `t/08` `fork()`/`pipe()`
failure; `t/09` the AccessBroker in the child (dry or rotating broker, expired
lease, `*_async` inside a `txn_do_async` body); `t/10` exit status: reaping
leaves `$?`, `$!`, `$@` alone.
