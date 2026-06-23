# ADR 0006 — One Sybase-based Storage serves both DBD::ODBC and DBD::Sybase

- Status: accepted
- Date: 2026-06-20
- Tags: storage, rebless, registry, odbc, sybase

## Context

MSSQL is reachable from Perl through two different DBDs: `DBD::ODBC` (with
FreeTDS or the MS ODBC driver) and `DBD::Sybase` (also FreeTDS-based). The
DBIO driver-development pattern is one Storage class per DBD, registered by
DBD name and selected by the connector registry on first connect.

DBIO core's `DBIO::Storage::DBI::ODBC->_rebless` calls
`_determine_connector_driver('ODBC')`, which looks up `SQL_DBMS_NAME` in the
connector registry. For MSSQL that registry maps `Microsoft_SQL_Server` to a
**single** Sybase-derived storage class — see core
`dbio/lib/DBIO/Storage/DBI.pm:1239` and `:1299`. So a `DBD::ODBC` connection
and a `DBD::Sybase` connection both rebless to the same class.

## Decision

There is exactly one MSSQL connection storage class —
`DBIO::MSSQL::Storage::Sybase`
(`lib/DBIO/MSSQL/Storage/Sybase.pm`). It inherits from both
`DBIO::Sybase::Storage` and `DBIO::MSSQL::Storage` via C3 ISA
(`Sybase.pm:7-11`) and is the rebless target for **both** DBDs, per the core
registry mapping above. There is deliberately **no** pure-ODBC MSSQL storage
class.

## Rationale

Both DBD paths talk to the same server with the same SQL dialect, identity
semantics, datetime handling and subselect rules — all of which live in
`DBIO::MSSQL::Storage`. The DBD-specific concerns (placeholder support,
FreeTDS statement-caching bugs, `syb_date_fmt`) are Sybase/FreeTDS-layer
concerns already handled by `DBIO::Sybase::Storage` and the `_rebless` /
`_init` hooks here (e.g. reblessing to `...::Sybase::NoBindVars` when
placeholders are unsupported). A second, near-empty ODBC storage class would
duplicate the entire MSSQL behaviour set for no behavioural difference, and
would have to be kept in lockstep — a maintenance trap. Routing both DBDs
through the Sybase-derived class keeps a single source of truth.

## Consequences

- Both `DBD::ODBC` and `DBD::Sybase` connections behave identically at the
  DBIO layer; tests assert the rebless target is `DBIO::MSSQL::Storage::Sybase`
  regardless of DBD.
- The driver depends on `DBIO::Sybase::Storage` (a separate distribution) even
  for ODBC-only deployments.
- **The registry mapping decision itself is core-owned**, not owned by this
  repo: it lives in `dbio/lib/DBIO/Storage/DBI.pm:1239,1299`. It is recorded in
  **core ADR 0016**
  (`dbio/docs/adr/0016-mssql-connector-registry-reblesses-to-sybase-storage.md`),
  backfilled from karr ticket `dbio` (core board) #49.
