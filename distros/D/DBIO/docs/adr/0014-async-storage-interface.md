# ADR 0014 — Async storage interface (Future-returning, sync-degrading)

- Status: accepted
- Date: 2026-06-19
- Tags: async, future, storage, pool, drivers, backfill

## Context

DBIx::Class is synchronous: every storage operation blocks. DBIO wants
non-blocking storage for event-loop applications, but without splitting the API
into two incompatible worlds (one for blocking code, one for Future-returning
code) and without forcing every storage to depend on an event loop. The
constraint that shapes the design: the same `*_async` call must be writable
against *any* storage, returning a Future, and must still work — degrading to an
immediately-resolved Future — on plain synchronous storage that has no event loop
at all.

## Decision

Provide a storage-agnostic, Future-returning async interface that degrades
cleanly to synchronous storage; ship the abstract contract, the sync-degrade
behaviour and a default synchronous Future in core; keep the real non-blocking
drivers as separate distributions.

- **`DBIO::Future` is the interface contract.** `lib/DBIO/Future.pm` is a
  duck-typed contract document (explicitly *not* a base class): it specifies the
  methods a DBIO-compatible Future must implement — `then`, `catch`, `get`,
  `is_ready`, `is_failed` — plus a `validate` runtime checker. Async drivers bring
  their own Future implementation (`Future`, `Mojo::Promise`, …) satisfying this.
- **`DBIO::Test::Future` is the default `future_class`.** `lib/DBIO/Test/Future.pm`
  is a minimal *synchronous*, immediately-resolved Future implementing the
  contract. The base `DBIO::Storage::future_class`
  (`lib/DBIO/Storage.pm:876-879`) defaults to it. So on sync storage, the async
  API works with no event loop.
- **`*_async` degrades on sync storage.** On `DBIO::Storage`
  (`lib/DBIO/Storage.pm:787-866`) each `*_async` runs the sync op in `eval` and
  wraps the result: `$@ ? $fc->fail($@) : $fc->done(@r)`. Methods:
  `select_async`, `select_single_async`, `insert_async`, `update_async`,
  `delete_async`, `txn_do_async`. The identical pattern is on `DBIO::ResultSet`
  (`lib/DBIO/ResultSet.pm:1877-1950`): `all_async`, `first_async`, `single_async`,
  `count_async`, `create_async`.
- **`DBIO::Storage::Async` is the abstract base.** `lib/DBIO/Storage/Async.pm`
  croaks `"Subclass must override …"` for every async op (and feature-not-supported
  for optional `pipeline`/`listen`). It defines the contract a real non-blocking
  driver implements; it is not itself a working async storage.
- **Pool tier.** `DBIO::Storage::Pool` (`lib/DBIO/Storage/Pool.pm`) is the
  abstract pool interface (all methods croak); `DBIO::Storage::PoolBase`
  (`lib/DBIO/Storage/PoolBase.pm:106-161`) is the concrete pool — idle-list plus
  waiter-queue checkout/checkin, capacity-bounded connection creation, shutdown —
  shared by async drivers.
- **Real non-blocking drivers are separate, already-implemented dists.**
  `dbio-postgresql-async` and `dbio-mysql-async` each ship a working
  `Async::Storage` / `Async::Pool` / `Async::TransactionContext` /
  `Async::ConnectInfo` over a real non-blocking client (PostgreSQL via `EV::Pg`:
  pipeline mode, prepared-statement cache, LISTEN/NOTIFY, COPY, pooled with txn
  pinning), with integration and listen-notify tests. They are implementations,
  not stubs.

## Rationale

One API that returns Futures everywhere is worth more than two parallel APIs. By
making `*_async` a thin sync-degrade by default (`eval` the sync op, wrap in
`future_class->done/fail`) and putting the abstract non-blocking contract in
`DBIO::Storage::Async` for real drivers to implement, application code can be
written once against the Future-returning API and run unchanged on synchronous
storage (resolving immediately) or on a non-blocking driver (resolving when the
event loop completes the IO). The split — contract + sync-degrade + default Future
in core, real event-loop drivers as separate dists — keeps core free of any
event-loop dependency while still making the whole API Future-shaped. Heritage
calls this "Phase 1 + 2" (`lib/DBIO/Manual/Heritage.pod:421-438`): the
storage-agnostic async interface whose queries return `Future` objects, with two
concrete non-blocking drivers.

This is shipped and test-pinned, hence **accepted**, not proposed.
`t/test/09_async.t` asserts the default `future_class` is `DBIO::Test::Future`,
that `*_async` on sync storage returns an `is_ready` Future, and that it resolves
to the same value as the sync call (e.g. `txn_do_async`'s sub result via `get`).

**Smell, recorded deliberately.** The *production* default `future_class` is a
class named `DBIO::Test::Future` (`Storage.pm:876-879`). This is intentional and
documented — it mirrors `DBIO::Test::Storage`: a fake, immediately-resolving
Future that lets the async API run without an event loop — but the `Test::` name
on a production default is a genuine smell worth flagging, not an accident.

## Consequences

- The async API is universal: every `*_async` works on any storage. Sync storage
  resolves immediately (`DBIO::Test::Future`); a non-blocking driver resolves on
  the event loop. Application code is written once.
- Real async support is a driver concern, isolated to separate dists
  (`dbio-postgresql-async`, `dbio-mysql-async`); core carries no event-loop
  dependency. New async drivers implement `DBIO::Storage::Async` and reuse
  `DBIO::Storage::PoolBase` for pooling.
- The `DBIO::Test::Future` production default is a documented smell; if it is ever
  renamed (e.g. to `DBIO::Future::Immediate`), `t/test/09_async.t`'s
  `future_class` assertion and any driver overriding it must move with it.

## Future architecture work (tracked cross-repo, not here)

- **Async storage as a CredentialSource consumer.** CONTEXT.md:58 records async
  as a "planned-but-unwired second" consumer of the AccessBroker seam (ADR 0013).
  The core abstract `DBIO::Storage::Async` indeed references no broker. But the
  concrete async *driver* dists already wire it: `dbio-postgresql-async`
  (`Async/Storage.pm:82-112`) and `dbio-mysql-async` (`Async/Storage.pm:78-108`)
  call `set_access_broker` / `current_access_broker_connect_info` — the same hooks
  `Storage::DBI` uses, available because they live on base `DBIO::Storage`
  (ADR 0013). So the seam is *consumed at the driver level* but *not promoted into
  the core async interface*, and CONTEXT.md is stale on this point. Closing it —
  lift broker consumption into `DBIO::Storage::Async`, refresh CONTEXT.md — cuts
  across the core seam and both async driver dists; it is cross-repo work, owned
  with ADR 0013's seam, not resolved in this ADR.
