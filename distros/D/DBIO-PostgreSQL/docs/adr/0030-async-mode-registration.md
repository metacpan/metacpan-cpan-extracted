# ADR 0030 — Per-repo async mode registration for PostgreSQL

- Status: accepted
- Date: 2026-07-06
- Tags: async, adr-0030, mode-registry, supersedes-pre-adr-0030-async-plan

## Context

Core ADR 0030 defines the async mode registry on `DBIO::Storage::DBI`: a schema
connected with `connect(..., { async => $mode })` resolves `$mode` through the
registry to an embedded async backend class, loaded lazily on first use of a
`*_async` method. The generic modes (`immediate`, and — where installed —
`forked` / `future_io`) are registered on the base storage class.

Before ADR 0030, `dbio-postgresql` reached its native event-loop backend through
an `async_backend('DBIO::PostgreSQL::EV::Storage')` class attribute (and, earlier
still, `load_components('PostgreSQL::EV')`). Both opt-ins are now obsolete: the
public contract is the connect-time `{ async => 'ev' }` mode, and the resolved
class is an implementation detail the optional `dbio-postgresql-ev` dist owns.

## Decision

Register `ev => DBIO::PostgreSQL::EV::Storage` on `DBIO::PostgreSQL::Storage` via
`register_async_mode`, placed immediately after the `register_driver('Pg')` wiring
in `lib/DBIO/PostgreSQL/Storage.pm`, with a comment block explaining the MRO
shadowing and lazy-load semantics.

Registration stores only the class *name* — it does not load
`DBIO::PostgreSQL::EV::Storage`. The optional `dbio-postgresql-ev` dist is
resolved lazily on first use, so declaring the mode here is safe when the dist is
absent. Consequently no `dbio-postgresql-ev` dependency is added to the cpanfile:
the EV add-on stays strictly optional (mirroring `dbio-mysql`).

## Consequences

- A PostgreSQL schema connected with `connect(..., { async => 'ev' })` now
  resolves the native EV backend lazily on first use of any `*_async` method,
  instead of croaking with "no driver or add-on registers it".
- Without `dbio-postgresql-ev` installed, the resolver croaks with the canonical
  "install DBIO::PostgreSQL::EV::Storage" message — the ADR 0030 contract. There
  is no silent fallback and no degrade.
- This registration shadows only `ev`; the generic modes remain resolved through
  the base `DBIO::Storage::DBI` registry (the test asserts `immediate` still
  resolves to `DBIO::Future::Immediate`), exactly as ADR 0030 specifies.
- The `async_backend()` and `load_components('PostgreSQL::EV')` opt-in patterns
  from before ADR 0030 are obsolete; the new path is the connect-time
  `{ async => 'ev' }` mode.

## References

- Core ADR 0030: `../dbio/docs/adr/0030-async-explicit-per-connection-mode.md`
- Registration + comment: `lib/DBIO/PostgreSQL/Storage.pm` (the `register_async_mode( ev => ... )` call)
- Contract test: `t/35-async-mode.t`
- Backend: `../dbio-postgresql-ev/lib/DBIO/PostgreSQL/EV/Storage.pm` (optional dist)
- MySQL mirror: `../dbio-mysql/docs/adr/0030-async-mode-registration.md`
