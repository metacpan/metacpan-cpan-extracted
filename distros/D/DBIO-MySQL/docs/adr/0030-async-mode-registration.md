# ADR 0030 — Per-repo async mode registration for MySQL/MariaDB

- Status: accepted
- Date: 2026-07-01
- Tags: async, adr-0030, mode-registry, supersedes-pre-adr-0030-async-plan

## Context

Core ADR 0030 defines the async mode registry on `DBIO::Storage::DBI`: a
schema connected with `connect(..., { async => $mode })` resolves `$mode`
through the registry to an embedded async backend class. `dbio-postgresql`
already wires its native `ev` mode at `Storage.pm:75-85`. MySQL currently
has no driver-side registration, so `connect(..., { async => 'ev' })`
cannot resolve on a MySQL schema even when the `dbio-mysql-ev` dist is
installed — the resolver walks an empty MRO arm and croaks.

## Decision

Register `ev => DBIO::MySQL::EV::Storage` on `DBIO::MySQL::Storage` via
`register_async_mode`, placed immediately after the `register_driver` call
in `lib/DBIO/MySQL/Storage.pm` and matching the comment block shape used
by the PostgreSQL mirror.

The MariaDB subclass (`DBIO::MySQL::Storage::MariaDB`) needs no separate
registration: MRO inheritance resolves `ev` through the parent class.

## Consequences

- A MySQL or MariaDB schema connected with `connect(..., { async => 'ev' })`
  now resolves the native EV backend lazily on first use of any `*_async`
  method, instead of croaking with "no driver or add-on registers it".
- Without `dbio-mysql-ev` installed, the resolver croaks with the canonical
  "install DBIO::MySQL::EV::Storage" message — ADR 0030 contract.
- This registration shadows only `ev`; the generic modes (`forked`,
  `future_io`) remain resolved through the base `DBIO::Storage::DBI`
  registry, exactly as ADR 0030 specifies.
- The `async_backend()` and `load_components('MySQL::EV')` opt-in patterns
  from before ADR 0030 are obsolete; the new path is the connect-time
  `{ async => 'ev' }` mode.

## References

- Core ADR 0030: `../dbio/docs/adr/0030-async-explicit-per-connection-mode.md`
- PostgreSQL mirror: `../dbio-postgresql/lib/DBIO/PostgreSQL/Storage.pm:75-85`
- Backend: `../dbio-mysql-ev/lib/DBIO/MySQL/EV/Storage.pm` (optional dist)