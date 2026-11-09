# ADR 0001 — DBIO::Forked is the generic fork-per-query async backend

- Status: accepted
- Date: 2026-06-28
- Tags: async, fork, storage, drivers, generic, new-dist

> **Addendum 2026-09-05 — the activation model below is superseded by core
> ADR 0030.** Core withdrew ADR 0028 (async as a pluggable embedded backend
> selected by an `async_backend` accessor) and ADR 0029 (the resolver fallback
> chain); neither is in core's `docs/adr/` any more. Their successor is core
> ADR 0030: async is an **explicit, per-connection mode**. An add-on registers
> its mode on the core base storage —
> `DBIO::Storage::DBI->register_async_mode( forked => 'DBIO::Forked::Storage' )`,
> which `DBIO::Forked::Storage` does at load time — and the user opts in at
> connect time with `connect(..., { async => 'forked' })`. There is no
> `async_backend` accessor, no silent degrade when the dist is absent, and **no
> auto-fallback**: a connection opened without `{ async => 'forked' }` stays
> synchronous and its `*_async` methods croak, and asking for `forked` without
> `dbio-forked` installed croaks loudly rather than degrading
> (`_async_storage` in `DBIO::Storage::DBI`).
>
> Read as superseded, therefore: the ADR-0028 sentence in *Context*; the
> "Activation reuses the existing ADR-0028 seam" bullet in *Decision*; the
> `async_backend` phrasing in the first *Consequences* bullet; and the whole
> *Future architecture work* section — the core fallback chain proposed there
> was not built and will not be, because deciding against an automatic fallback
> is precisely what ADR 0030 did. ADR 0002's citation of "ADR 0028" for the
> anti-recursion rule is stale in the same way, while the rule it cites is
> unchanged: the sync CRUD the child calls does not route to the async backend,
> so it cannot re-fork.
>
> The decision itself stands. `DBIO::Forked` is still the generic
> fork-per-query (Model A) async backend, still a sibling of `dbio-async` on the
> same `DBIO::Storage::Async` contract, still dependency-free, still bound by
> the boundary below — and because the mode is registered on the core *base*
> storage class it is still available to every driver. Only *how a connection
> reaches it* changed: one explicit mode instead of an accessor plus a fallback
> chain, so Forked is the backend of every connection that asks for `forked`,
> not of every driver automatically. Current behaviour is documented under
> "ACTIVATION" in `DBIO::Forked` and `DBIO::Forked::Storage`.

## Context

Core ADR 0014 made the `*_async` API universal; core ADR 0028 made async a
pluggable *embedded backend* of the sync storage, selected by the
`async_backend` accessor (`class | instance | coderef`, degrades silently when
absent). dbio-async ADR 0004 established `dbio-async` as the shared, Future::IO
based async layer — but it presupposes an **async-capable client** (DBD::Pg
native async / EV::Pg / EV::MariaDB).

DBIO ships 15+ sync drivers and only **two** native-async variants
(`dbio-postgresql-async`, `dbio-mysql-async`). The rest — Oracle, db2, Firebird,
Informix, MSSQL, Sybase, SQLite, DuckDB, … — will likely never get an
async-capable client, so under dbio-async alone they can never answer `*_async`
with real non-blocking behaviour.

DBIx::QuickORM's `forked` mode shows the way out: you can get async behaviour
**without** an async client by running the query synchronously in a child
process and streaming the result back over a pipe. The driver needs no async
support at all — the parallelism comes from the separate process.

## Decision

`DBIO::Forked` is a new dist: a generic, **fork-per-query** async backend
(Model A) that makes *any* sync DBIO driver async — no async client, no event
loop.

- `DBIO::Forked::Storage` subclasses core `DBIO::Storage::Async` and fulfils the
  `*_async` contract.
- **Activation reuses the existing ADR-0028 seam — no core change.**
  `async_backend('DBIO::Forked::Storage')` is loaded by the core resolver in
  `DBIO::Storage::DBI` (`load_optional_class` → `->new($schema)` →
  `->connect_info(...)`); it degrades silently when `dbio-forked` is not
  installed, exactly like any other backend. This is the user-override transport
  ADR 0028 §3 explicitly anticipated ("one implementation, not *the*
  implementation").
- **Dependency-free**: only core Perl (`fork`, `pipe`, `Storable`,
  `IO::Select`) plus DBIO core. No `Future`, no `Future::IO`, no event loop.

## Rationale

`DBIO::Forked` is a **sibling** of `dbio-async`, not a layer above or below it:
both fulfil the same core `DBIO::Storage::Async` contract, but `dbio-async` =
Future::IO + async client (efficient, for PG/MySQL), `dbio-forked` = fork +
ordinary sync client (universal, for everything else). Forked is the only async
backend that is genuinely generic, because it needs nothing but the DBI-form
connect info every sync driver already has.

Model A (one fork per query) is the deliberate MVP choice: simple, proves the
concept, covers every driver at once. A Model B (persistent worker pool with
connection reuse and multi-query transactions, mapping onto core `PoolBase` /
`acquire_txn`) is future work, motivated by the limits in ADR 0003.

## Boundary (do NOT cross)

`dbio-forked` ships **no** DB-specific code and re-implements **no** SQL — the
real driver does that in the child (ADR 0002). The dist must load and work with
any sync driver, and pull no async-ecosystem deps.

## Consequences

- async becomes a capability any driver can gain through `async_backend`,
  including the ~13 drivers that will never have a native async client.
- Wiring Forked as the *automatic* async fallback for every driver (incl.
  "native backend not installed → fall back to Forked") is a core resolver
  change, owned by core — see below.
- Model A's limits (no pool, no multi-query transaction pinning, a pipe-buffer
  size ceiling) are recorded in ADR 0002 and ADR 0003.

## Addendum 2026-10-30: the cost of a call is bounded by connect options

Every `*_async` call is one process and one database connection of its own, so
the cost per call is fixed by Model A and the number of them is the caller's.
The backend declares two options through core's `async_option_names` (core ADR
0078 seam, karr core k397): `statement_timeout` (seconds; a forked call past its
deadline is ended and its future fails) and `max_in_flight` (the number of
unresolved calls; one more fails before it forks). Both default to none. The
count is the storage's own, per process and per connection: it holds the futures
it forked weakly and counts those not yet resolved, so a resolved, cancelled or
dropped future frees its slot. The POD of `DBIO::Forked::Storage` names the
process and connection count per call (karr k27).

## Future architecture work (tracked cross-repo, not here)

- **dbio (core)**: a fallback chain in `DBIO::Storage::DBI::_async_storage` so a
  driver with no native `async_backend` (or whose native backend is not
  installed) falls back to `DBIO::Forked::Storage`. Its own core ADR + mock test
  mirroring `t/test/10_async_backend.t`. karr ticket on the core board.
