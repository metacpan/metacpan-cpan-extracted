# CLAUDE.md — DBIO::Async

This distribution tracks only what is its own — `.claude/skilletor.json`, its
`dbio-async` skill and its worker agent. The family skills, the shared agents and
the shared `.claude/rules/` are installed from the `dbio` core repo by skilletor;
everything named here refers to those. The family-wide house rules (discipline,
delegation, release) live in `.claude/rules/.local.dbio-rules.md` — auto-loaded by
Claude Code for the main agent and all subagents.

**Fresh clone or new worktree: run `skilletor sync` first.** The installed skills,
rules and agents are git-ignored and exist only after that sync — before you rely on
a briefing, and before `dzil build`. It needs the skilletor CLI or plugin and network
access to github.com/Getty/skills, github.com/Getty/karr and codeberg.org/dbio/dbio.
Never edit an installed copy; change the source in core and sync again.

## Delegation

Delegate behavior-relevant async-layer code (the `DBIO::Async::Storage` skeleton,
`Pool`, `TransactionContext`, the `Future::IO` watcher seam, tests) to this repo's
`dbio-worker-async` instead of touching it yourself. Lane and principle:
`.claude/rules/.local.dbio-rules.md`. Working on the dist: skill `dbio-async-core`
(architecture, invariants, limits, tests); the driver-facing contract is
`dbio-async`. Repo agents: `dbio-worker-async` (default),
`dbio-adr-auditor`, `dbio-release-manager`, `karr-coordinator`.

## Core Concept: Shared, loop-agnostic async layer

`DBIO::Async` is the **middle layer** of the DBIO async stack — the Future-bearing,
DB-agnostic plumbing every async driver needs, in one shared dist. It sits between
core (which holds the loop-free contracts: `DBIO::Storage::Async`, `PoolBase`,
`DBIO::Future`) and the DB-specific drivers (which subclass the skeleton and
supply only seam hooks).

```
core DBIO::Storage::Async  (CONCRETE Model-B orchestration: CRUD runner,
        ↑ subclass          txn + pipeline pinning, generic Transaction/Pipeline
                            contexts)
DBIO::Async::Storage        (Future::IO transport base: _query_async +
        ↑ subclass          _await_* watcher seam, future_class, pool)  <-- THIS DIST
DBIO::PostgreSQL::Storage::Async  (driver adapter: DB-specific seam hooks only)
```

Since core ADR 0030 §4 the Model-B orchestration is **concrete in core**;
`DBIO::Async::Storage` is now the thin Future::IO transport base over it. The
per-driver adapter is **resolved by convention** — `connect(..., { async =>
'future_io' })` on a `DBIO::PostgreSQL::Storage` schema loads
`DBIO::PostgreSQL::Storage::Async` (core resolver, `ref($storage).'::Async'`, ADR
0030 refinement / karr k65). There is **no** `async_backend` declaration and no
generic registration; a driver with no adapter croaks early. **Installing
`dbio-async` provides the shared transport base** — a sync-only driver pulls no
async deps.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::Async` | Dist entry point (loadable, no behaviour) |
| `DBIO::Async::Storage` | Future::IO transport base (extends core `DBIO::Storage::Async`; orchestration inherited, only transport seams here) |
| `DBIO::Async::Pool` | Generic pool (extends core `DBIO::Storage::PoolBase`) |
| `DBIO::Async::Future` | The pool's waiter (`Pool::_new_waiter`): a `Future` whose `await` drives `Future::IO`; a dying blocking wait withdraws it (ADR 0008) |
| `DBIO::Async::TransactionContext` | Thin subclass of core's generic `DBIO::Storage::Async::TransactionContext` |

## The watcher seam is `Future::IO`

The loop-agnostic fd-watcher seam is **concentrated in the `_await_*` methods**:
`_await_conn_ready` and `_await_query_result` both go through the single
`_await_readable`, which calls `Future::IO->poll($fh, POLLIN)` on a per-connection
dup of the driver-supplied socket fd (`_conn_poll_fh` — `Future::IO` needs a real
filehandle, and a per-poll one is closed before the loop unwatches it). `Future::IO`
runs on its built-in impl (a plain `select` loop of its own, no event loop) until
an impl is **loaded** -- `use Future::IO::Impl::IOAsync;` (likewise AnyEvent /
Mojo / UV / Glib) or `Future::IO->load_best_impl` in the main program; installing
a `Future::IO::Impl::*` alone changes nothing, and this dist loads none. **The
user picks the loop; no event loop is a hard require** (core ADR 0014). The seam is isolated on purpose so spike findings
(dbio-postgresql k21 DBD::Pg-native async) can rework the `_await_*` hooks
punctually without rebuilding the skeleton (ADR 0004 isolation principle).

What an implementation does with a poll on the way is its own, and three
behaviours reach a caller (POD `FUTURE::IO IMPLEMENTATIONS`; Future::IO 0.23,
Future::IO::Impl::IOAsync 0.805): the built-in one's round dies when a poll is
cancelled from the callback of a poll in front of it (karr k37); IOAsync keeps
a cancelled poll's watch and dup until the socket next turns readable (karr
k38), and kills a `->get` made in a poll's callback when that socket turns
readable again — every synchronous statement of a `txn_do` block. **Nothing in
`lib/` works around them**; `t/33` and `t/34` hold them as `TODO`. Whether to
work around, report upstream or leave documented is the maintainer's decision
(karr k37) — do not build a workaround in passing.

## Transport behaviour a driver relies on

Decided in `DBIO::Async::Storage`, documented in its POD; the skill carries the
driver-facing detail.

- **Pinned statement queue** (karr k33 / k34): `_query_async_pinned` sends the
  statements on one pinned connection one after the other, queued under the
  reserved key `_dbio_async_queue` on the connection hashref. A connection that
  is not a hashref gets no queue — the driver serialises. The connection is idle
  once its statement has settled, before that statement's callbacks run; a
  synchronous statement issued from a callback behind statements still waiting
  cannot complete.
- **Cancel retires** (karr k29): a query cancelled in flight, pooled or pinned,
  has its connection reported dead to the pool (`_mark_connection_dead` — by
  `_abandon_on_cancel` pooled, by the statement queue pinned) — never drained,
  `_conn_error_is_fatal` not asked. A cancel while still waiting for the pool
  retires nothing.
- **Flights are held** (karr k46 / k39, ADR 0007): the storage keeps every
  statement on the wire in a register until it settles, and the caller gets a
  Future of its own. A Future the caller drops (not cancels) is carried
  through: collected, connection handed back once. A connection the pool
  closes — `disconnect`, `shutdown`, a retirement — ends the flight on it
  through `DBIO::Async::Pool::_shutdown_connection` →
  `_abandon_flights_on`: the caller's Future fails there ("whether it took
  effect is unknown"), the poll is let go of, nothing is read off the closed
  connection, a pinned queue refuses unsent. A hashref connection the pool
  closed gets nothing more handed to `_submit_query`, with or without a
  statement in flight. `_collect_result` is not called for such a statement,
  nor in a forked child for a flight it inherited: a poll made in another
  process continues into nothing (`_await_readable`). No completion asks `pool()`; `_let_go` is the one
  place a poll is given up, as `_await_readable` is the one that makes it.
- **No Future, no query** (karr k35): a dispatch seam (`_await_query_result`)
  that dies or returns no Future fails the query through core's `_seam_future`;
  a pooled connection is still released.
- **Broker answers** (karr k27 / k43 / k44): `_async_broker_conninfo` reads a
  DBI-form arrayref, a hashref of connection parameters (DSN built by the owning
  sync storage; a `dbname` that is a whole DSN needs no owner, and refuses
  `host` / `port` beside it) and the transport's own connect info. Anything else
  croaks naming the shape, never the values; so does a call with no broker
  attached.

## Hard boundary

This dist ships **no** DB-specific code. Pulling driver glue in here couples it to
every DBD — rejected (ADR 0004). The skeleton must load and work without any
concrete DBD installed (only `Future` / `Future::IO` + core DBIO).

## Dependencies

- `Future` (production `future_class`)
- `Future::IO` (loop-agnostic fd-watcher seam; built-in impl is a `select` loop, no event loop)
- `recommends IO::Async` + `Future::IO::Impl::IOAsync`
- `suggests` AnyEvent / Mojo / UV / Glib `Future::IO::Impl::*`
- `DBIO` core

No event loop is a hard require. DB-specific DBDs are the driver's concern, not
here. The `Future` / `Future::IO` requirements live in **this** cpanfile — the
single home — so a sync-only driver pulls no async deps.

## Version policy

**Every** shipped `.pm` under `lib/` carries a literal `our $VERSION`, all of them
the same value — bare `[@DBIO]`, versioned via `@Git::VersionManager`, whose
RewriteVersion/BumpVersionAfterRelease run `global = 1` over `[:InstallModules]`
and so rewrite and bump every module in lockstep. Do not strip one from a skeleton
module. Do not copy a `$VERSION` from another DBIO repo into the cpanfile — a
repo's `$VERSION` is ahead of its last release; pin to the latest released
version via `cpanm --info`. The one exception is release staging: for a
coordinated release the whole family is pinned ahead to the version it will be
released as. That is the state now — `requires 'DBIO', '0.900004'` is staged;
do not "correct" it back to the released number. Rule and exception: skill
`dbio-perl-syntax`, § *cpanfile versioning*.

## ADRs

- 0001 — sync methods block via `->get`
- 0002 — transaction pinning via `TransactionContext`
- 0003 — pipeline as generic bracketing over driver seam hooks (amended: the
  block is handed a pinned `PipelineContext` from core, so batching is
  structural and not a per-driver obligation — karr k7/k6)
- 0004 — dbio-async is the generic Future::IO-based async layer (split, dependency
  posture, isolation principle; relationship to core ADR 0014)
- 0005 — the Future::IO listen seams live here once (core ADR 0056, karr k22):
  `_listen_delay`, one watch loop behind `_listen_watch` / `_listen_unwatch`
  (socket- or timer-driven via `_listen_poll_interval`), the pooled
  `_notify_send`; a driver supplies `_listen_drain`, `_notify_sql`, the
  connection seams and its own `listen` / `notify` capabilities
- 0006 — the driver says when a connection is dead (core ADR 0047 addenda, karr
  k26 / k28): `_conn_error_is_fatal` is asked on every failed query and reported
  to the pool before the release (a throw counts as dead and goes to `on_error`;
  a transaction's connection goes back through core's finalizer);
  `DBIO::Async::Pool` delegates core's `_idle_connection_alive` to the adapter
- 0007 — the transport holds its statements in flight (core ADR 0047 k258 as
  precedent, karr k46 / k39): a register on the storage, a Future of the
  caller's own, a dropped Future carried through, a flight ended where the
  pool closes its connection (`_abandon_flights_on`, called from the pool's
  `_shutdown_connection` — `shutdown` / `disconnect` stay core's), a closed
  connection refused by the transport, an inherited flight inert in a forked
  child, no pool built by a completion, `_let_go` as the one place a poll is
  given up
- 0008 — a blocking call waits for a pool connection (core k256, karr k30;
  refines 0001): the pool's waiter is a `DBIO::Async::Future` whose `await`
  drives `Future::IO`; a blocking wait that dies withdraws its waiter
  (`_withdraw_waiter`); no heuristic refusal, no wrapper around core's queue
- 0009 — the trace runs through the owner storage's debug object and the
  `redact_bind_value` hook (core ADR 0025, karr k53): `DBIO_TRACE=1` the SQL,
  from `=2` the binds, redacted and cut to 32 characters, no `warn`; since
  core k402 the rule is core's `_debug_query` (the hook gets column name and
  bind attributes, `query_end` runs), the transport only calls it
- 0010 — a statement on the wire and a pinned queue are bounded (core ADR 0078,
  karr k54): `statement_timeout` (cancel path, connection retired),
  `max_pending_pinned` (fail at once, queue unchanged), both declared through
  `async_option_names`; core's `acquire_timeout` / `max_waiters` / `txn_timeout`
  / `reset_timeout` pass through

0001–0004 carry a 2026-09-05 addendum (karr k14): the decisions stand, but their
implementation is **core's** since ADR 0030 §4, `future_io` registers nothing (the
adapter is resolved by convention, core k65/k67), the watcher call is `poll`, and
0003's "sequential degrade" and 0004's "the EV dists are then retired" never
described anything real. Core ADR 0028, cited throughout 0004, no longer exists —
ADR 0030 replaced 0028 and 0029.

See `.claude/skills/dbio-async/SKILL.md` for the full subclass contract and seam
hook table.

## Testing

```bash
# Unit / skeleton tests (no DB, no loop)
../dbio/maint/capped-test prove -lr t/00-load.t

# Full suite — live tests skip cleanly without DBIO_TEST_* / a loop
../dbio/maint/capped-test prove -lr t/
```

Driver-specific live tests (PG, LISTEN/NOTIFY, COPY) belong in the driver dist,
not here. This dist's tests cover the generic seam contract, txn-pinning logic,
sync `->get` fallback, `future_class='Future'`, and pool readiness — plus,
offline as well: the listen seams, the AccessBroker answer shapes, release after
a dispatch that dies, dead-connection retire, the idle-connection check, the
pinned statement queue, cancel in flight, a synchronous statement from a
callback, an acquire cancelled while connecting, a seam returning no Future, a
broker detached or switched, a query Future dropped in flight or while queued,
and disconnect / shutdown with a statement in flight (pooled, pinned, queued,
in a transaction, on an idle connection, in a forked child that tears down or
turns its own loop, in global destruction; a transaction that ends after
the disconnect builds no new pool -- core hands its connection back to the
pool it came from, dbio 4aa01dc67). `t/27` also holds a connection retired
while it comes up (karr k49): its readiness poll is let go of, the waiting
acquire fails, the slot goes on. `t/32`
runs the dropped and torn-down cases on IO::Async and skips without
`Future::IO::Impl::IOAsync`. `t/33` (built-in implementation) and `t/34`
(IO::Async, skips like `t/32`) hold what the `Future::IO` implementations do
with the transport's polls: a race of two pooled queries and a disconnect in a
callback, a cancelled poll's watch, a synchronous statement in a callback, in
a `txn_do` block and in a channel callback. Their `TODO`s are upstream's (karr
k37, k38): red today, `TODO passed` the day upstream changes.
