# ADR 0001 — DBIO::Forked is the generic fork-per-query async backend

- Status: accepted
- Date: 2026-06-28
- Tags: async, fork, storage, drivers, generic, new-dist

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

## Future architecture work (tracked cross-repo, not here)

- **dbio (core)**: a fallback chain in `DBIO::Storage::DBI::_async_storage` so a
  driver with no native `async_backend` (or whose native backend is not
  installed) falls back to `DBIO::Forked::Storage`. Its own core ADR + mock test
  mirroring `t/test/10_async_backend.t`. karr ticket on the core board.
