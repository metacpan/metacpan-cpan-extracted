# ADR 0014 — Async storage interface (Future-returning, sync-degrading)

- Status: accepted — binding model superseded in part by [ADR 0030](0030-async-explicit-per-connection-mode.md)
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
  their own Future implementation (`Future`, …) satisfying this.
- **The default `future_class` is a sync, immediately-resolved Future.**
  `DBIO::Future::Immediate` (`lib/DBIO/Future/Immediate.pm`) is a minimal
  *synchronous*, immediately-resolved Future implementing the contract. The base
  `DBIO::Storage::future_class` (in `lib/DBIO/Storage.pm`) defaults to it. So on
  sync storage, the async API works with no event loop. (Originally shipped under
  the name `DBIO::Test::Future`; since renamed — see the Smell note below.)
- **`*_async` degrades on sync storage.** On `DBIO::Storage`
  (in `lib/DBIO/Storage.pm`) each `*_async` runs the sync op in `eval` and
  wraps the result: `$@ ? $fc->fail($@) : $fc->done(@r)`. Methods:
  `select_async`, `select_single_async`, `insert_async`, `update_async`,
  `delete_async`, `txn_do_async`. The identical pattern is on `DBIO::ResultSet`
  (in `lib/DBIO/ResultSet.pm`): `all_async`, `first_async`, `single_async`,
  `count_async`, `create_async`.
- **`DBIO::Storage::Async` is the abstract base.** `lib/DBIO/Storage/Async.pm`
  croaks `"Subclass must override …"` for every async op (and feature-not-supported
  for optional `pipeline`/`listen`). It defines the contract a real non-blocking
  driver implements; it is not itself a working async storage.
- **Pool tier.** `DBIO::Storage::Pool` (`lib/DBIO/Storage/Pool.pm`) is the
  abstract pool interface (all methods croak); `DBIO::Storage::PoolBase`
  (`lib/DBIO/Storage/PoolBase.pm`) is the concrete pool — idle-list plus
  waiter-queue checkout/checkin, capacity-bounded connection creation, shutdown —
  shared by async drivers.
- **Real non-blocking drivers are separate, already-implemented dists.**
  `dbio-postgresql-async` and `dbio-mysql-async` (since renamed to the `-ev`
  dists — see Future architecture work below) each ship a working
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
calls this "Phase 1 + 2" (`lib/DBIO/Manual/Heritage.pod`): the
storage-agnostic async interface whose queries return `Future` objects, with two
concrete non-blocking drivers.

This is shipped and test-pinned, hence **accepted**, not proposed.
`t/test/09_async.t` asserts the default `future_class` is `DBIO::Future::Immediate`,
that `*_async` on sync storage returns an `is_ready` Future, and that it resolves
to the same value as the sync call (e.g. `txn_do_async`'s sub result via `get`).

**Smell, recorded deliberately — since resolved.** As first shipped, the
*production* default `future_class` was a class named `DBIO::Test::Future`: a
fake, immediately-resolving Future (mirroring `DBIO::Test::Storage`) that lets the
async API run without an event loop. The `Test::` name on a production default
was a genuine smell worth flagging, not an accident. It has since been resolved:
the class was renamed to `DBIO::Future::Immediate` (`lib/DBIO/Future/Immediate.pm`),
a properly-named, dependency-free production Future backing ADR 0030's `immediate`
async mode; `future_class` and `t/test/09_async.t` moved with it.

## Consequences

- The async API is universal: every `*_async` works on any storage. Sync storage
  resolves immediately (`DBIO::Future::Immediate`); a non-blocking driver resolves on
  the event loop. Application code is written once.
- Real async support is a driver concern, isolated to separate dists
  (`dbio-postgresql-async`, `dbio-mysql-async`); core carries no event-loop
  dependency. New async drivers implement `DBIO::Storage::Async` and reuse
  `DBIO::Storage::PoolBase` for pooling.
- The production default's `Test::`-named smell has since been resolved: the class
  was renamed to `DBIO::Future::Immediate`, and `t/test/09_async.t`'s
  `future_class` assertion moved with it (any driver overriding `future_class`
  tracks the name too).

## Future architecture work (tracked cross-repo, not here)

- **Binding model superseded by [ADR 0030](0030-async-explicit-per-connection-mode.md).**
  The `*_async`-degrade contract, the `DBIO::Storage::Async` abstract base and the
  `PoolBase` tier described here all stand. What 0030 replaces is *how a real
  non-blocking driver is selected and bound*: not a disjoint async `storage_type`
  chosen at schema-author time (the `connection()` → `storage_type(...)` hijack
  above), but an explicit per-connection `{ async => 'mode' }` choice resolved
  through a mode registry, so one schema class runs sync and several async modes
  side by side. The always-on silent degrade described here survives only as the
  explicit `immediate` mode. Read 0030 before relying on the binding or degrade
  mechanism described in this ADR.
- **"Separate dist per loop" framing superseded — one shared `dbio-async`
  backend, loop chosen via `Future::IO::Impl::*`.** The Decision above frames a
  real non-blocking driver as a separate storage dist *per event loop*
  (`dbio-postgresql-async` / `dbio-mysql-async`, with `DBIO::EV::Pg::Storage` /
  `Net::Async::DBIO::Storage` / `Mojo::DBIO::Storage` as the per-loop backend list
  in `DBIO::Storage::Async`'s POD). That framing is superseded: there is now ONE
  shared, loop-agnostic backend — `DBIO::Async::Storage` in the `dbio-async` dist —
  driving the driver's own non-blocking DBD binding through `Future::IO`, with the
  event loop chosen by installing a `Future::IO::Impl::*` adapter (`IO::Poll`
  built-in default; IO::Async / AnyEvent / Mojo / UV / Glib optional), **not** by
  picking a different dist. It is registered as the `future_io` mode ([ADR 0030](0030-async-explicit-per-connection-mode.md) §2);
  the loop-bound native-client route survives as the driver-resolved `ev` mode
  (`DBIO::PostgreSQL::EV::Storage` / `DBIO::MySQL::EV::Storage`, the renamed
  `-async` dists). The stale per-loop backend list and the class-name binding
  example in `DBIO::Storage::Async`'s POD have been corrected accordingly. Detail:
  dbio-async ADR 0004 (`docs/adr/0004-dbio-async-generic-future-io-layer.md` in the
  dbio-async repo). Only the framing of how a real driver is structured changes —
  the contracts in this ADR (the `*_async` degrade, the `DBIO::Storage::Async`
  abstract base, the `PoolBase` tier, the `DBIO::Future` duck-type, no event-loop
  hard require) are unaffected.
- **Async storage as a CredentialSource consumer — since promoted into core.**
  As this ADR was written, the AccessBroker seam (ADR 0013) was consumed only at
  the async *driver* level, not in the core async interface, and CONTEXT.md
  recorded async as a "planned-but-unwired second" consumer. That closing work has
  since landed: the broker seam is lifted into the core abstract
  `DBIO::Storage::Async` itself (`_setup_access_broker` / `_clear_access_broker`
  and the `_async_broker_conninfo` per-pool-spawn `conninfo_provider`), reusing the
  `set_access_broker` / `current_access_broker_connect_info` hooks inherited from
  base `DBIO::Storage`. CONTEXT.md now records `Storage::Async` as one of the two
  real in-core CredentialSource consumers alongside `Storage::DBI`. The seam stays
  owned with ADR 0013.

## Addendum 2026-10-08 — core keeps the contracts it documents at its own call sites (karr k284)

Two contracts of this interface were documented and not kept by core itself.
No new decision; the rule is that a seam core asks a backend to answer, and an
interface core says it calls, hold at every call site in core.

- **`_txn_conn_accessor` names the pinned connection both ways.** It is the
  name a backend's transaction context knows its connection by: the key
  `txn_do_async` passes it to the context's `new` under, and the method core
  calls to get it back. `deploy_async` read `$ctx->txn_conn` whatever the seam
  answered, so a backend answering another name could not deploy. It is the
  one place in core that reads the connection from a context; it asks under
  the seam's name now. Every context class of the family keeps `txn_conn`
  (dbio-async, both EV drivers), so nothing changes for them.
- **The transactional run of `deploy_async` stays on `_query_async_pinned`,
  past the context.** Sending its DDL through `$ctx->_query_async` instead
  would drop the read altogether, and was measured and not taken: the context
  asks its owner for proof (`_assert_async_context_owner`) and refuses once
  the storage is disconnected, so a deploy in flight at a `disconnect` would
  fail and roll back where today it goes on to its `COMMIT` on the connection
  it began on (the behaviour karr dbio-async k46 pinned), and every mock
  backend whose owner has no such proof would stop deploying.
- **`->then($on_done, $on_fail)` means what it means in Future.pm, on every
  Future class core ships.** `DBIO::Future` lists the two-callback `then` among
  what core calls on a `future_class`; `DBIO::Storage::Async` puts `ROLLBACK`
  and the hand-back of the connection into the second callback.
  `DBIO::Future::Immediate` dropped it. No production path of core sends an
  Immediate through it -- `DBIO::Storage::Async::future_class` has no default,
  every backend of the family names another class, and the `immediate` mode
  runs transactions through `_run_immediate_txn` (ADR 0055) -- but a
  `DBIO::Storage::Async` backend naming it, as the mock backends of core's
  tests do, kept the connection of every failed transaction. `then` takes the
  second callback now; `DBIO::Test::Future` already did.
- Still open, a maintainer decision: `DBIO::Future->validate` checks the five
  instance methods and none of the class methods core calls (`done`, `fail`,
  `needs_all`, `new`). `DBIO::Future::Immediate` has no `new` -- it is never
  pending -- and is the one class of the family a check for all four would
  refuse.
- No ADR 0024 contract-version bump. Pinned by
  `t/test/52_async_future_then_two_callbacks.t` (one table for the three
  classes, 25 of 288 assertions red before) and
  `t/test/53_async_txn_conn_accessor.t` (20 of 79 red before).
