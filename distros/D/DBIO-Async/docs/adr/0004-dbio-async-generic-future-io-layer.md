# ADR 0004 — dbio-async is the generic, Future::IO-based async layer for DBIO drivers

- Status: accepted
- Date: 2026-06-28
- Tags: async, future-io, architecture, new-dist, generic, supersedes-0014-framing

> **Activation model superseded by core ADR 0030/0031.** This ADR's framing —
> "installing `dbio-async` is what turns async on" and a driver declaring its
> backend via `async_backend(...)` (the ADR 0028 model) — was replaced by the
> *explicit per-connection mode*: an add-on calls
> `DBIO::Storage::DBI->register_async_mode($mode => $class)` and the user opts in
> with `connect(..., { async => $mode })`. There is no `async_backend` /
> `async_fallback` and no auto-fallback. `dbio-async` registers the `future_io`
> mode (in `DBIO::Async`), so a connection opened with `{ async => 'future_io' }`
> builds the `DBIO::Async::Storage` backend. Everything else below (the generic
> skeleton, the `Future::IO` watcher seam, the dependency posture, the boundary)
> stands.

## Context

Core ADR 0014 made the `*_async` API universal and split the world into "core
holds the loop-free contracts; real non-blocking drivers are separate dists",
and ADR 0028 made async an embedded, pluggable *mode* of the sync storage. Both
stand. What neither addressed is the **middle layer**: the Future-bearing,
DB-agnostic plumbing that every async driver needs. Today that middle is
copy-pasted between `dbio-postgresql-async` and `dbio-mysql-async`
(`Async::Storage.pm`, `Async::Pool.pm`, `Async::TransactionContext.pm`), and
neither uses `Future::IO` — both speak their non-blocking client (EV::Pg /
EV::MariaDB) directly through its own callback API, so the watcher/loop seam is
implicit, not factored.

The consequence: every driver reimplements the same CRUD runner, transaction
pinning, pool, sync-`->get` fallbacks and AccessBroker wiring, and the
Future-ecosystem requirements (`Future`, `Future::IO`) live in each driver's
cpanfile — so a sync-only driver cannot avoid pulling async deps cleanly, and
swapping the event loop means swapping the driver.

## Decision

Establish `dbio-async` as the single shared, loop-agnostic async layer. It
carries the Future-ecosystem requirements and the generic plumbing; DB-specific
glue stays in each driver.

- **`DBIO::Async::Storage`** is a concrete, reusable, DB-agnostic skeleton
  subclassing core's abstract `DBIO::Storage::Async`. It hosts the generic
  machinery every driver duplicated: the `_run_crud` / runner pattern, the
  blocking `->get` sync fallbacks (ADR 0001), the `TransactionContext` shape
  (ADR 0002), the `pipeline` bracketing (ADR 0003), the AccessBroker async
  consumption glue (over core's `DBIO::Storage` hooks), and the
  capability-gating helper. A driver subclasses it and supplies **only** the
  DB-specific seam hooks (submit async query, collect ready result, transform
  SQL, post-insert SQL, connect-info shape, pool create/shutdown, socket fd).
- **The watcher seam is `Future::IO`.** `_await_conn_ready($conn)` and
  `_await_query_result($conn, $sql, $bind)` are generic hüllen that drive
  `Future::IO->ready_for_read($fh)` on a driver-supplied socket fd. The built-in
  `Future::IO` implementation is `IO::Poll` (core, no event loop); `Future::IO`
  auto-routes through IO::Async / AnyEvent / Mojo / UV / Glib when the matching
  `Future::IO::Impl::*` module is installed. This *is* the "user decides the
  loop" seam — one backend, pluggable loop.
- **Dependency posture lives here, not in each driver.** `dbio-async` cpanfile:
  `requires Future`, `requires Future::IO` (default impl `IO::Poll`, no event
  loop); `recommends IO::Async` + `Future::IO::Impl::IOAsync`; `suggests` the
  AnyEvent/Mojo/UV/Glib Impl modules. **No event loop is ever a hard require**
  (core ADR 0014). A sync-only driver (e.g. `dbio-postgresql` alone) therefore
  pulls **no** async deps; installing `dbio-async` is what turns async on —
  exactly the capability-degrade mechanism core ADR 0028 already implements.
- **Scope: PG-first, generic design.** Build and prove `dbio-async` driving the
  PostgreSQL re-engine (#21), but keep the `DBIO::Async::Storage` API strictly
  DB-agnostic. `dbio-mysql-async` adopts it in a later, separate ticket.

## Boundary (do NOT cross)

`dbio-async` = GENERIC + the Future requirements + the version policy, ONE
place. DB-specific glue stays in each driver. Pulling driver glue into
`dbio-async` would couple it to every DBD — rejected. The skeleton must load
and work without any concrete DBD installed (only `Future` / `Future::IO` +
core DBIO).

## Isolation principle (Seam rework-bar)

The `Future::IO` watcher seam is **concentrated in the `_await_*` methods**.
This is deliberate: at the time of this ADR the seam is *not yet proven by a
running driver* — the PostgreSQL re-engine spike (#21 Phase 1: DBD::Pg native
async + `Future::IO->ready_for_read` on `pg_socket`) is still open, and the
existing EV::Pg/EV::MariaDB drivers do not use `Future::IO` at all. Isolating
the seam means spike findings can be reworked **punctually** — adjusting the
`_await_*` hooks and the socket-fd contract — without rebuilding the skeleton's
generic machinery around them.

## Relationship to core ADRs

- **ADR 0014** (async storage interface): its contracts stand — the `*_async`
  degrade, the `DBIO::Storage::Async` abstract base, the `PoolBase` tier. What
  this ADR supersedes is 0014's *framing* that a real async driver is "a
  separate dist per loop" (EV::Pg / Net::Async / Mojo as separate storage
  dists): there is now ONE shared `dbio-async` backend, and the loop is chosen
  via the `Future::IO` Impl, not via picking a different dist. 0014's
  `DBIO::Storage::Async` POD backend list collapses to `dbio-async` + the
  `Future::IO::Impl::*` adapters. (Refreshing 0014's text is core-doc work,
  tracked as a follow-up ticket on the dbio board.)
- **ADR 0028** (async as storage mode, pluggable embedded backend): unchanged
  and complementary. 0028 defines *how the backend is bound* (embedded, lazy,
  string-declared, degrades when absent); this ADR defines *what the shared
  backend is*. A driver declares `async_backend('DBIO::PostgreSQL::Async::Storage')`
  (0028); that class subclasses `DBIO::Async::Storage` (this ADR).

## Consequences

- The generic Future/Pool/TransactionContext plumbing lives in one place;
  drivers supply only DB-specific seam hooks. `dbio-mysql-async` adopts the
  skeleton later without rewriting the generic tier.
- A sync-only driver pulls no async deps; `dbio-async`'s cpanfile is the single
  home of the Future/Future::IO requirements.
- The loop is user-chosen via `Future::IO::Impl::*`; no event loop is a hard
  require.
- The `_await_*` watcher seam is the rework surface for the #21 spike; the rest
  of the skeleton is expected to be stable once the seam settles.
- The existing `dbio-postgresql-async` / `dbio-mysql-async` dists become the
  source material: their generic parts move here, their DB-specific parts move
  back to the respective driver. Both add-on dists are then retired (PG side:
  #21 Phase 7; MySQL side: a later adoption ticket).
