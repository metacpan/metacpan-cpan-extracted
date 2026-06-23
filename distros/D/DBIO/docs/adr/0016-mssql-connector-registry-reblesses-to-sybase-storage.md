# ADR 0016 — MSSQL connector registry reblesses to Sybase-derived storage

- Status: accepted
- Date: 2026-06-20
- Tags: storage, rebless, registry, connector, mssql, sybase, odbc, tds, backfill

## Context

DBIO determines its concrete storage class at connect time by reblessing the
generic `DBIO::Storage::DBI` into a driver-specific subclass. There are two
detection axes (`lib/DBIO/Storage/DBI.pm`): a *driver registry* keyed on the DBD
driver name (`Pg`, `mysql`, `Sybase`, `ODBC`, …) consulted by `_determine_driver`,
and a *connector registry* keyed on the normalized `SQL_DBMS_NAME` of the engine
*behind* a generic connector, consulted by `_determine_connector_driver` for
secondary detection (`DBI.pm:1424-1460`).

Microsoft SQL Server is reachable two ways: via `DBD::Sybase`/FreeTDS (its native
TDS-protocol client) and via `DBD::ODBC` (a generic connector that does not tell
you which RDBMS is on the far end). DBIx::Class modelled these as two independent
concrete storage classes — `Storage::DBI::ODBC::Microsoft_SQL_Server` and
`Storage::DBI::Sybase::Microsoft_SQL_Server` — each carrying its own copy of the
MSSQL-specific behaviour. The fork had to decide where an MSSQL connection,
arriving by either path, should land.

## Decision

Both MSSQL connection paths rebless into a single Sybase-derived concrete class,
`DBIO::MSSQL::Storage::Sybase`. There is **no** pure-ODBC MSSQL storage class.

- **The connector registry maps `Microsoft_SQL_Server` → Sybase storage.** The
  baked-in connector registry in core (`DBI.pm:1238-1241`) contains
  `'Microsoft_SQL_Server' => 'DBIO::MSSQL::Storage::Sybase'`, and the
  `register_connector_driver` POD example shows the same pairing
  (`DBI.pm:1298-1300`). An `dbi:ODBC:` connection first reblesses to
  `DBIO::Storage::DBI::ODBC`, whose `_rebless` calls
  `_determine_connector_driver('ODBC')` (`ODBC.pm:19`); that reads `SQL_DBMS_NAME`,
  normalizes non-word characters to `_` (`DBI.pm:1437`, "Microsoft SQL Server" →
  `Microsoft_SQL_Server`), looks it up in the connector registry, and reblesses
  into `DBIO::MSSQL::Storage::Sybase`.
- **The DBD::Sybase path converges on the same class.** A `dbi:Sybase:` connection
  reblesses via the driver registry to `DBIO::Sybase::Storage`, which detects an
  MSSQL engine behind the Sybase client and reblesses to the same
  `DBIO::MSSQL::Storage::Sybase`. Both axes therefore terminate at one concrete
  class.
- **Sybase is the common base, MSSQL specifics mix in.**
  `DBIO::MSSQL::Storage::Sybase` (in the `dbio-mssql` dist) multiply-inherits
  `DBIO::Sybase::Storage` *and* `DBIO::MSSQL::Storage` (`Sybase.pm:7-10`):
  the TDS/Sybase client behaviour is the base, the MSSQL dialect, identity-insert,
  GUID and DateTime concerns mix in on top. `DBIO::MSSQL::Storage` itself is an
  abstract base (UniqueIdentifier + IdentityInsert, `Storage.pm:7-10`), never a
  rebless target.
- **The registry entry is core-owned.** The `dbio-mssql` dist registers only the
  synthetic `MSSQL` DBD-driver name onto its base class
  (`__PACKAGE__->register_driver('MSSQL' => __PACKAGE__)`, `MSSQL/Storage.pm:25`);
  it does **not** call `register_connector_driver`. The
  `Microsoft_SQL_Server → DBIO::MSSQL::Storage::Sybase` mapping is hard-wired in
  the core connector registry, so the decision lives here.

## Rationale

Microsoft SQL Server inherited the Sybase TDS wire protocol from its shared
lineage, so the protocol-level storage behaviour MSSQL needs (placeholder
detection, FreeTDS version handling, statement-cache workarounds, savepoint
syntax) is *exactly* the Sybase behaviour. Making `DBIO::Sybase::Storage` the
single base and mixing MSSQL specifics on top removes the DBIx::Class duplication,
where two parallel `Microsoft_SQL_Server` classes carried near-identical TDS logic.
The ODBC connector adds nothing MSSQL-specific beyond *identifying* the backend —
once `SQL_DBMS_NAME` resolves it to MSSQL, the right behaviour is still the
Sybase-derived one. A dedicated pure-ODBC MSSQL storage class would be a second
home for the same logic with no behaviour of its own, so it was deliberately not
created; the connector registry routes ODBC-detected MSSQL straight to the Sybase
class instead. Keeping the registry entry in core (rather than self-registered by
`dbio-mssql`) is consistent with core owning connector detection: core decides the
rebless target, the driver dist supplies the class.

## Consequences

- A single concrete class, `DBIO::MSSQL::Storage::Sybase`, serves MSSQL regardless
  of whether the connection arrives via `DBD::Sybase`/FreeTDS or via `DBD::ODBC`.
  MSSQL-specific behaviour is written once.
- There is intentionally no `DBIO::MSSQL::Storage::ODBC` rebless target. Anyone
  searching for one by analogy to DBIx::Class's
  `Storage::DBI::ODBC::Microsoft_SQL_Server` will not find it; the connector
  registry is the indirection that makes it unnecessary.
- The mapping is overridable at runtime — `register_connector_driver` lets a
  consumer point `Microsoft_SQL_Server` at a different class — but the shipped
  default is core-owned, not contributed by `dbio-mssql`. Changing the default
  target is a core change to `DBI.pm:1239`.
- The further FreeTDS placeholder/NoBindVars rebless (`Sybase.pm:34-58`, to
  `DBIO::MSSQL::Storage::Sybase::NoBindVars`) is a *third*, dist-local rebless step
  layered on top of this decision; it is owned by `dbio-mssql`, not by the core
  registry, and is out of scope for this ADR.
- `dbio-mssql` records this convergence from its own side in a local ADR that
  cross-references this number (0016); the authoritative registry decision is here
  in core.
