---
name: dbio-async-core
description: Load before changing code, tests or ADRs of the DBIO::Async distribution itself — its architecture, vocabulary, hard boundaries, invariants, known limits, test layout.
user-invocable: false
---

# DBIO::Async — working on the distribution

For those who change this dist. What a driver author or user needs — the seam
hooks, activation, transport behaviour, broker answers, the `Future::IO`
implementation limits — is in skill `dbio-async`; this skill adds the rest and
does not repeat it.

## Architecture

```
core DBIO::Storage::Async   concrete Model-B orchestration (CRUD runner, txn and
        ↑                   pipeline pinning, generic contexts) -- core's, ADR 0030 §4
DBIO::Async::Storage        Future::IO transport base: _query_async, _await_* seam,
        ↑                   future_class, pool, flights, listen watch
DBIO::<DB>::Storage::Async  driver adapter: DB-specific seam hooks only
```

- `DBIO::Async::Storage` is the thin transport over core's orchestration. Behaviour
  that is orchestration (`_run_crud`, `txn_do_async`, `pipeline`, the contexts,
  sync `->get` wrappers) is changed in core, not here.
- `DBIO::Async::Pool` extends core `PoolBase`; `DBIO::Async::Future` is the pool's
  waiter (`Pool::_new_waiter`), whose `await` drives `Future::IO`;
  `DBIO::Async::TransactionContext` is a thin subclass of core's.
- The adapter is resolved by convention (`ref($storage) . '::Async'`); this dist
  registers no mode and declares no `async_backend`.
- `future_class` is `'Future'`.

## Vocabulary

- **seam**: a hook the driver overrides; unimplemented ones croak `Subclass must
  override …`. Table in `dbio-async`.
- **watcher seam**: the `_await_*` methods. `_await_conn_ready` and
  `_await_query_result` both go through the one `_await_readable`
  (`Future::IO->poll($fh, POLLIN)` on `_conn_poll_fh`, a per-connection dup).
- **flight**: a statement on the wire, held in the storage's register
  (`_flight_register`) until its Future settles; the caller holds a Future of its
  own.
- **pinned queue**: the statement queue under `_dbio_async_queue` on a pinned
  connection hashref (`_queue_*`).
- **retire**: report a connection dead to the pool (`_mark_connection_dead`).
- **let go**: give up a poll or Future (`_let_go`).

## Hard boundaries

- **No DB-specific code.** Driver glue here couples the dist to every DBD
  (ADR 0004). The skeleton loads and works with `Future` / `Future::IO` and core
  DBIO alone; `t/16` holds it.
- **No event loop is a hard require** (core ADR 0014). The dist loads no
  `Future::IO::Impl::*`; the user picks the loop.
- **Dependencies live in this cpanfile only** (`Future`, `Future::IO`, core
  `DBIO`; `recommends` IO::Async + `Future::IO::Impl::IOAsync`; `suggests` the
  AnyEvent / Mojo / UV / Glib impls). A sync-only driver pulls no async deps.
- `@ISA` / `use base` changes of the storage classes are an architecture change:
  ticket and ADR.
- The `_await_*` seam stays isolated, so a driver's native async client can rework
  it without rebuilding the skeleton (ADR 0004).

## Invariants

- **One place makes a poll** (`_await_readable`), **one place gives up** (`_let_go`).
  `t/13` pins both, and the list of methods that own each step.
- `_await_readable` returns a Future chained off the poll, continuing only in the
  process that made it (`_in_this_process_cb`); a flight inherited across a fork
  never reaches `_collect_result` in the child.
- **No completion builds a pool.** Completions talk to the pool the statement was
  dispatched with (`_built_pool`, possibly none), never `pool()`:
  `_abandon_on_cancel($conn, $pool)`, `_mark_dead_on_fail($conn, $pool)`,
  `_release_on_ready($conn, $pool, $caller)`.
- A pooled connection is back in the pool before the caller's callbacks run; a
  pinned connection is idle before its statement's callbacks run.
- `_query_async` does not consult pipeline state (ADR 0003 amendment).
- `shutdown`, `release`, `disconnect` stay core's. The pool's
  `_shutdown_connection` calls `_abandon_flights_on` before
  `_shutdown_pool_connection` (ADR 0007).
- `_withdraw_waiter` runs for a blocking wait that dies; no wrapper around core's
  queue, no heuristic refusal (ADR 0008).
- Every shipped `.pm` under `lib/` carries a literal `our $VERSION`, all the same
  (`@Git::VersionManager` bumps them in lockstep). cpanfile entries name the
  family version; the release run sets it. Skill `dbio-perl-syntax`.

## Known limits

- The `Future::IO` implementation behaviours (built-in round dies on a poll
  cancelled from another poll's callback; IOAsync keeps a cancelled poll's
  watch; IOAsync's read handler is not reentrant) are described in
  `dbio-async`. **Nothing in `lib/` works around them.** Working around, reporting
  upstream or leaving documented is undecided; a workaround is not built in
  passing.
- `t/33` (built-in) and `t/34` (IO::Async) hold them as `TODO` on what the caller
  is owed, with the transport's own part asserted hard beside it. A `TODO passed`
  means upstream changed. One implementation per file, because a process loads
  only one.
- A synchronous statement issued from a callback behind statements still waiting
  on the same pinned connection cannot complete.
- A connection that is no hashref gets no pinned queue and no closed-mark; the
  driver serialises and refuses.

## Testing

```bash
../dbio/maint/capped-test prove -lr t/00-load.t   # skeleton, no DB, no loop
../dbio/maint/capped-test prove -lr t/            # full suite
```

Test with the family's local checkouts on `PERL5LIB` (not `~/perl5`). Live tests
skip cleanly without `DBIO_TEST_*` or a loop; driver-specific live tests (PG,
LISTEN/NOTIFY, COPY) belong in the driver dist. One run per database, no
`prove -j`. Skill `dbio-driver-development`, `references/live-testing.md`.

The suite is offline and covers the generic seam contract, txn pinning, pool
readiness and:

| Area | Files |
|------|-------|
| load, API, boundary, seam ownership | `t/00`, `t/01`, `t/13`, `t/16` |
| future class, transport, resolution contracts | `t/11`, `t/12`, `t/15` |
| async mode, insert shape, dialect shaping | `t/07`, `t/08` |
| bind release, on-connect replay, deploy | `t/04`, `t/10`, `t/17` |
| broker answers, detach / switch | `t/02`, `t/20`, `t/29` |
| pool: readiness, queue, wait, lease | `t/03`, `t/06`, `t/35`, `t/36`, `t/37` |
| transactions, contexts, pipeline | `t/05`, `t/09`, `t/14`, `t/18` |
| listen seams | `t/19` |
| dispatch dies, dead connection, idle check | `t/21`, `t/22`, `t/23`, `t/28` |
| pinned queue, cancel, sync in callback | `t/24`, `t/25`, `t/26` |
| acquire cancelled while connecting | `t/27` |
| flights: disconnect, dropped Future | `t/30`, `t/31`, `t/32` (IO::Async) |
| `Future::IO` implementation limits | `t/33`, `t/34` (IO::Async) |
| trace through the debug object | `t/38` |
| no-reset retirement | `t/39` |
| `statement_timeout`, `max_pending_pinned` | `t/40`, `t/41` |
| core's pool limits through the pool | `t/42` |

`t/32`, `t/34` and `t/36` skip without `Future::IO::Impl::IOAsync`.

## ADRs (`docs/adr/`)

- 0001 sync methods block via `->get`; 0002 transaction pinning; 0003 pipeline
  bracketing; 0004 the generic Future::IO layer (split, dependencies, isolation
  principle). Their implementation is core's since core ADR 0030 §4.
- 0005 listen seams live here once (core ADR 0056).
- 0006 the driver says when a connection is dead (core ADR 0047 addenda).
- 0007 the transport holds its statements in flight.
- 0008 a blocking call waits for a pool connection.
- 0009 the trace runs through the owner storage's debug object and the
  `redact_bind_value` hook (core ADR 0025): `DBIO_TRACE=1` the SQL, from `=2`
  the binds, redacted and cut to 32 characters; the transport only calls core's
  `_debug_query`.
- 0010 a statement on the wire and a pinned queue are bounded (core ADR 0078):
  `statement_timeout` cancels the statement and retires its connection,
  `max_pending_pinned` fails the statement over the limit at once; both are
  declared through `async_option_names`. Core's `acquire_timeout`,
  `max_waiters`, `txn_timeout` and `reset_timeout` pass through the pool.

A new decision of this kind is an ADR in this format; skill `dbio-adr`.
