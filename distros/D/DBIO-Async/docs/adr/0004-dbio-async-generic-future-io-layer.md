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

## Amendment (2026-09-05, k14) — the orchestration moved to core, `future_io` registers nothing, and the EV dists were never retired

The split this ADR decided stands: one shared, loop-agnostic async layer, the
Future / Future::IO requirements in a single cpanfile, no DB-specific code here,
and the watcher seam isolated so a spike can rework it without touching the
rest. The *Boundary* and the *Isolation principle* are unchanged. Four
statements about **how** it is wired are not — including one in the note above,
which corrected ADR 0028's `async_backend` and then named a mechanism that has
since been withdrawn in turn. That note stays exactly where it is, as the record
of that step; this is the next one.

1. **There is no registration of `future_io`, generic or otherwise.** The note's
   "`dbio-async` registers the `future_io` mode (in `DBIO::Async`)" describes
   nothing in the code: `DBIO::Async` calls no `register_async_mode` at all.
   Core resolves the transport class **by convention** (ADR 0030 §2 refinement,
   karr k65, refined k67): `_async_storage` in `DBIO::Storage::DBI` probes
   `$pkg . '::Async'` for each class in the concrete driver storage's linearised
   ISA, most-specific first, stopping strictly before the generic
   `DBIO::Storage::DBI` base. A *generic* base-class registration is skipped in
   the registry walk on purpose (`_resolve_async_mode_class` is called with an
   `exclude`), so merely loading this dist can no longer claim `future_io` for
   every installed driver and then die deep in an abstract `_submit_query`. An
   explicit per-driver `register_async_mode(future_io => ...)` still wins, and a
   driver with no adapter croaks early and by name. The *mode* is still explicit
   at `connect`; only the *class* is discovered.

2. **The generic machinery is not here.** The first *Decision* bullet lists the
   `_run_crud` runner, the blocking `->get` fallbacks, the TransactionContext
   shape, the `pipeline` bracketing and the AccessBroker glue as this class's
   contents. Core ADR 0030 §4 lifted all of it into `DBIO::Storage::Async`,
   which is concrete; the per-decision detail is in the 2026-09-05 addenda on
   ADRs 0001, 0002 and 0003. What `DBIO::Async::Storage` holds is the
   **transport**: `future_class`, `pool`, `_query_async` / `_query_async_pinned`,
   the `_await_*` watcher seam, `_async_broker_conninfo`,
   `transport_capabilities`, the two transaction-context seams (defaulted here
   since karr k13), and the croaking DB-seams `_submit_query`,
   `_collect_result`, `_conn_ready`, `_conn_fileno`, `_normalize_conninfo`,
   `_create_pool_connection` and `_shutdown_pool_connection`. The seam list in
   that bullet is otherwise right, except that `_transform_sql` and
   `_post_insert_sql` are now inherited as croaking seams from core rather than
   declared here.

3. **The watcher call is `poll`, not `ready_for_read`.** `_await_readable` in
   `lib/DBIO/Async/Storage.pm` calls `Future::IO->poll($fh, POLLIN)`. Two
   further details of the seam post-date this ADR and matter to anyone reworking
   it. First, `_await_readable` is the *single* method that touches
   `Future::IO`: `_await_conn_ready`, `_await_query_result` and a driver's
   re-polling `_collect_result` all go through it, so the seam is one method
   narrower than the two this ADR names. Second, the fd a driver returns from
   `_conn_fileno` is not handed to `Future::IO` directly — `_conn_poll_fh` dups
   it once per connection into a filehandle cached for that connection's whole
   life, because the impls mark a poll Future done *before* they unwatch its
   filehandle, and a per-poll handle would already be closed by then. The
   isolation principle is unchanged and is if anything better served.

4. **The EV dists were not retired.** The last consequence has both add-on dists
   "then retired". `dbio-postgresql-ev` and `dbio-mysql-ev` are live: core ADR
   0030 §2 keeps `ev` as a named, **driver-resolved** mode, and it is the
   transport that carries LISTEN/NOTIFY, COPY and pipelining — none of which
   this `future_io` transport advertises. What did happen to them is the other
   half of §4: they became thin transports over core's one orchestration,
   exactly as this dist did. The generic parts moved; the dists did not go away.

Finally, **ADR 0028 no longer exists.** It is cited in *Dependency posture* and
given its own subsection under *Relationship to core ADRs*; core deleted it when
ADR 0030 replaced 0028 and 0029 together. Read
`async_backend('DBIO::PostgreSQL::Async::Storage')` there as
`connect(..., { async => 'future_io' })`, and "exactly the capability-degrade
mechanism core ADR 0028 already implements" as: installing this dist supplies a
transport base a driver's own adapter subclasses, and nothing more — there is no
degrade left to speak of (ADR 0030 §3). The dependency posture itself — Future
and Future::IO required here, no event loop ever a hard require — is unchanged,
and is still this dist's cpanfile.

## Amendment (2026-10-08, k38) — an implementation applies when it is loaded, not when it is installed

The Decision below says `Future::IO`'s default implementation "is `IO::Poll`"
and that `Future::IO` "auto-routes through IO::Async / AnyEvent / Mojo / UV /
Glib when the matching `Future::IO::Impl::*` module is installed". Neither
describes `Future::IO` (checked against 0.23). The built-in implementation is a
plain `select` loop of `Future::IO`'s own; `IO::Poll` lends it constants only.
And an implementation takes over when it is **loaded** — `use
Future::IO::Impl::IOAsync;` in the program, or `Future::IO->load_best_impl`
called once by the main program — never by being installed; this dist loads
none, and neither does core. The decision itself stands: the user picks the
loop, and no event loop is a hard require. What the implementations do
differently with this transport's polls is recorded in the POD of
`DBIO::Async::Storage`, section *FUTURE::IO IMPLEMENTATIONS* (karr k38, k37).

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
  PostgreSQL re-engine (dbio-postgresql k21), but keep the
  `DBIO::Async::Storage` API strictly DB-agnostic. `dbio-mysql-async` adopts it
  in a later, separate ticket.

## Boundary (do NOT cross)

`dbio-async` = GENERIC + the Future requirements + the version policy, ONE
place. DB-specific glue stays in each driver. Pulling driver glue into
`dbio-async` would couple it to every DBD — rejected. The skeleton must load
and work without any concrete DBD installed (only `Future` / `Future::IO` +
core DBIO).

## Isolation principle (Seam rework-bar)

The `Future::IO` watcher seam is **concentrated in the `_await_*` methods**.
This is deliberate: at the time of this ADR the seam is *not yet proven by a
running driver* — the PostgreSQL re-engine spike (dbio-postgresql k21 Phase 1:
DBD::Pg native async + `Future::IO->ready_for_read` on `pg_socket`) is still
open, and the existing EV::Pg/EV::MariaDB drivers do not use `Future::IO` at
all. Isolating the seam means spike findings can be reworked **punctually** —
adjusting the `_await_*` hooks and the socket-fd contract — without rebuilding
the skeleton's generic machinery around them.

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
- The `_await_*` watcher seam is the rework surface for the dbio-postgresql k21
  spike; the rest of the skeleton is expected to be stable once the seam settles.
- The existing `dbio-postgresql-async` / `dbio-mysql-async` dists become the
  source material: their generic parts move here, their DB-specific parts move
  back to the respective driver. Both add-on dists are then retired (PG side:
  dbio-postgresql k21 Phase 7; MySQL side: a later adoption ticket).
