---
name: dbio-async
description: "DBIO::Async — shared loop-agnostic async layer: generic Future::IO storage skeleton, pool, TransactionContext, driver seam contract"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# DBIO::Async

Shared, loop-agnostic async layer for DBIO drivers. `DBIO::Async::Storage` is a
concrete, DB-agnostic skeleton subclassing core `DBIO::Storage::Async`; a
DB-specific driver subclasses it and supplies only the DB-specific seam hooks.
The Future / Future::IO requirements live here, not in each driver — a sync-only
driver pulls no async deps.

## Activation — the `future_io` async mode (ADR 0030/0031)

Loading `DBIO::Async` provides the shared abstract Future::IO transport base
`DBIO::Async::Storage`; it registers **no** generic `future_io` mode. The mode is
selected per connection via `connect(..., { async => 'future_io' })` (ADR 0030 —
explicit, no auto-fallback) and its transport class is **resolved by convention**:
the core resolver derives `ref($storage) . '::Async'` off the concrete driver
storage — `DBIO::PostgreSQL::Storage` → `DBIO::PostgreSQL::Storage::Async` — and
croaks early if a driver ships no such adapter (ADR 0030 refinement / karr #65).
The adapter is a concrete subclass of `DBIO::Async::Storage` that supplies the
seam hooks below; the Model-B orchestration (CRUD runner, txn pinning, pipeline)
is inherited from core (ADR 0030 §4). Its `insert_async` resolves the
returned-columns hashref that sync `insert` returns (ADR 0031 §3), not raw
RETURNING rows.

## Namespace

| Class | Purpose |
|-------|---------|
| `DBIO::Async` | Dist entry point (loadable, no behaviour) |
| `DBIO::Async::Storage` | Abstract Future::IO transport base (extends core `DBIO::Storage::Async`; orchestration inherited) |
| `DBIO::Async::Pool` | Generic pool (extends core `DBIO::Storage::PoolBase`) |
| `DBIO::Async::TransactionContext` | Thin subclass of core's generic `DBIO::Storage::Async::TransactionContext` |

## Subclass contract — seam hooks a driver supplies

A driver's adapter (convention name `DBIO::PostgreSQL::Storage::Async`) does
`use base 'DBIO::Async::Storage'` and overrides the DB-specific hooks. The
unimplemented ones croak `"Subclass must override …"`.

| Hook | Driver supplies |
|------|-----------------|
| `_submit_query($conn, $sql, $bind)` | submit an async query, return a Future |
| `_collect_result($conn)` | read the ready result off the connection |
| `_conn_fileno($conn)` | the socket fd to watch with `Future::IO->ready_for_read` |
| `_transform_sql($sql)` | SQL rewrite the driver needs (e.g. `?`→`$N`, or identity) |
| `_post_insert_sql($sql)` | append to INSERT (e.g. `RETURNING *`, or none) |
| `_normalize_conninfo($ci)` | driver's connect-info shape |
| `_create_pool_connection($ci)` | build a pooled connection |
| `_shutdown_pool_connection($conn)` | tear one down |
| `_conn_ready($conn)` | Future done when the connection is ready (or `done($conn)` if immediate) |
| `_txn_context_class` | the driver's TransactionContext subclass |
| `_txn_conn_accessor` | the pinned-handle accessor name (default `txn_conn`) |
| `_pipeline_enter` / `_pipeline_sync` / `_pipeline_exit` | optional pipeline primitives (capability-gated; croak/degrade if absent) |

Everything else — `_run_crud`, `txn_do_async`, the `pipeline` bracketing, the
sync `->get` fallbacks, AccessBroker wiring, pool idle-list/waiter-queue — is
generic and lives here.

## Architecture

- Returns **Future.pm** objects from all async methods; `future_class` is `'Future'`.
- Sync methods (`select`, `insert`, …) are one-line wrappers `return $self->..._async(@_)->get` (ADR 0001).
- Transactions pin one connection via `TransactionContext` + the core `PoolBase->acquire_txn` seam (ADR 0002).
- Pipeline is a generic `pipeline(\&coderef)` bracketing over driver seam hooks; capability-gated when the driver's client has no pipeline binding (ADR 0003).
- The **watcher seam is `Future::IO`**: `_await_conn_ready` / `_await_query_result` drive `Future::IO->ready_for_read($fh)` on the driver-supplied socket fd. Loop-agnostic: default impl is `IO::Poll` (core, no event loop); auto-routes through IO::Async / AnyEvent / Mojo / UV / Glib via the matching `Future::IO::Impl::*`. The user picks the loop; no event loop is a hard require (core ADR 0014).

## Isolation principle

The `Future::IO` watcher seam is **concentrated in the `_await_*` methods**. The
seam is rework-bar: spike findings (e.g. the #21 DBD::Pg-native spike) can adjust
the `_await_*` hooks and socket-fd contract without rebuilding the generic
machinery. See ADR 0004.

## Connection / AccessBroker

The skeleton inherits the AccessBroker hooks (`set_access_broker` /
`current_access_broker_connect_info`) from core `DBIO::Storage`; `connect_info`
has the same broker-vs-direct branch as the drivers. A driver's
`_normalize_conninfo` turns the broker's connect info into the shape its client
needs.

## Dependencies

- `Future` (production `future_class`)
- `Future::IO` (loop-agnostic fd-watcher seam; default impl `IO::Poll`)
- `recommends IO::Async` + `Future::IO::Impl::IOAsync`
- `suggests` AnyEvent / Mojo / UV / Glib Impl modules
- `DBIO` core

No event loop is a hard require. DB-specific DBDs (EV::Pg, DBD::Pg, …) are the
driver's concern, not here.

## Testing

```bash
# Unit / skeleton tests (no DB, no loop)
prove -lr t/00-load.t

# Full suite — live tests skip cleanly without DBIO_TEST_* / a loop
prove -lr t/
```

Driver-specific live tests (PG, LISTEN/NOTIFY, COPY) belong in the driver dist,
not here. This dist's tests cover the generic seam contract, txn-pinning logic,
sync `->get` fallback, `future_class='Future'`, and pool readiness.

## ADRs

- 0001 — sync methods block via `->get`
- 0002 — transaction pinning via `TransactionContext`
- 0003 — pipeline as generic bracketing over driver seam hooks
- 0004 — dbio-async is the generic Future::IO-based async layer (split, dependency posture, isolation principle; relationship to core ADR 0014/0028)

## Important notes

- This dist ships **no** DB-specific code. Pulling driver glue in here couples it
  to every DBD — rejected (ADR 0004 boundary).
- The skeleton must load and work without any concrete DBD installed.
- `$VERSION` lives only in `lib/DBIO/Async.pm` (bare `[@DBIO]`, versioned via
  `@Git::VersionManager`); the skeleton modules carry no `$VERSION`.
