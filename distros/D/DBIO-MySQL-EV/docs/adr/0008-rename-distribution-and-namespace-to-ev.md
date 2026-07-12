# ADR 0008 — Rename distribution and namespace from ::Async to ::EV

- Status: accepted
- Date: 2026-06-30
- Tags: packaging, rename, namespace, ev, drivers, cpan-migration

## Context

This distribution shipped as `DBIO-MySQL-Async` (namespace `DBIO::MySQL::Async`)
and is on CPAN as `GETTY/DBIO-MySQL-Async-0.900000`. The name claims the generic
"async MySQL" slot, but the driver is not generic: it bypasses DBI entirely,
speaks MariaDB's C client async protocol directly through `EV::MariaDB`, and is
hard-wired to the EV event loop (ADR 0003). There is no loop-agnostic seam here —
`->get` drives a real EV loop (ADR 0001), the pool builds `EV::MariaDB` handles
(ADR 0003), and every async primitive resolves on EV.

Meanwhile the family is growing a shared, loop-agnostic async layer
(`DBIO::Async::Storage`, the generic `Future::IO`-based skeleton) that a *future*
MySQL/MariaDB async driver can subclass to run on whatever loop the user picks.
That future driver is the rightful owner of the neutral `DBIO::MySQL::Async`
name. Keeping the EV-only driver parked on that name would be dishonest about its
single-loop nature and would block the loop-agnostic driver from taking the
obvious namespace.

The structural twin `dbio-postgresql-async` faces the identical split and is
being renamed to `DBIO::PostgreSQL::EV` in lockstep; this ADR records the MySQL
side of that family-wide decision.

## Decision

Rename the distribution `DBIO-MySQL-Async` to `DBIO-MySQL-EV` and the namespace
`DBIO::MySQL::Async` to `DBIO::MySQL::EV`, end to end:

- The six modules move from `lib/DBIO/MySQL/Async/` to `lib/DBIO/MySQL/EV/`
  (history-preserving `git mv`): the schema component `DBIO::MySQL::EV`, plus
  `::Storage`, `::Pool`, `::QueryExecutor`, `::ConnectInfo`, `::TransactionContext`.
- The component short-form follows: `load_components('MySQL::EV')` now resolves to
  the renamed main module.
- `dist.ini` `name` becomes `DBIO-MySQL-EV` and the owned skill becomes
  `dbio-mysql-ev`; the worker agent becomes `dbio-worker-mysql-ev`.
- This is a CPAN namespace migration, not a deletion: `DBIO-MySQL-Async-0.900000`
  stays on CPAN untouched, and the freed `DBIO::MySQL::Async` namespace is reserved
  for the future loop-agnostic driver built on `DBIO::Async::Storage`.

This is a pure rename. No runtime behaviour, API surface, SQL generation, or
transaction semantics change — only the package/distribution names.

## Rationale

The name should tell the truth. `EV` in the name makes the hard EV dependency and
the single-loop nature explicit at the point a user chooses the driver, instead of
discovering it after wiring `DBIO::MySQL::Async` into an IO::Async or Mojo app and
finding it only ever drives EV. The honest name also unblocks the family plan:
the loop-agnostic seam lives once in `DBIO::Async::Storage`, and the neutral
`DBIO::MySQL::Async` namespace is exactly where a future driver subclassing that
seam belongs — so it must not be occupied by the EV-only implementation.

Doing it as a namespace migration (old dist left on CPAN) rather than a hostile
takeover keeps existing `DBIO-MySQL-Async-0.900000` installs working while new
work moves to `DBIO-MySQL-EV`. The rename is mechanical and fully covered by the
existing offline test suite, so the risk is confined to packaging.

## Consequences

- Consumers that load `DBIO::MySQL::Async` / `load_components('MySQL::Async')` must
  switch to `DBIO::MySQL::EV` / `load_components('MySQL::EV')`. The old CPAN release
  keeps working at its pinned version; there is no shim in this dist.
- The `DBIO::MySQL::Async` namespace is now free and reserved for a future
  loop-agnostic driver on `DBIO::Async::Storage`. Nothing in this dist may reclaim
  it.
- ADRs 0001–0007 now describe `DBIO::MySQL::EV::*` classes; their decisions are
  unchanged, only the class names moved. References to the sibling
  `dbio-postgresql-async` / `DBIO::PostgreSQL::Async` are left as-is — that rename
  is recorded in its own repo.
- The full test count is unchanged by the rename (the suite asserts the same
  behaviour under the new names), which is the acceptance gate for this being a
  no-behaviour-change packaging move.
