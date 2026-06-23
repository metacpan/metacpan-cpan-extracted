# ADR 0001 — GUID auto-increment suppresses IDENTITY_INSERT and SCOPE_IDENTITY

- Status: accepted
- Date: 2026-06-20
- Tags: storage, identity, guid, insert

## Context

`DBIO::MSSQL::Storage` composes two core Storage mixins via `use base` + C3
ISA (`Storage.pm:7-11`):

    use base qw/
      DBIO::Storage::DBI::UniqueIdentifier
      DBIO::Storage::DBI::IdentityInsert
    /;
    use mro 'c3';

`IdentityInsert` wraps any `INSERT` that supplies a value for an
`is_auto_increment` column in `SET IDENTITY_INSERT <t> ON/OFF`, and the MSSQL
`_prep_for_execute` appends a trailing `SELECT SCOPE_IDENTITY()` to retrieve
the generated identity (`Storage.pm:117-133`).

This is correct for real `IDENTITY(1,1)` columns. It is **wrong** for GUID
primary keys. A `uniqueidentifier` PK is not a real IDENTITY column — it is
populated by `NEWID()` through `DBIO::Storage::DBI::UniqueIdentifier`'s
`_prefetch_autovalues`, before the INSERT. If the inherited `IdentityInsert`
wrapper still fires, MSSQL rejects it with *"Table '...' does not have the
identity property. Cannot perform SET operation."*, and there is no real
IDENTITY value for `SCOPE_IDENTITY()` to return.

## Decision

In `_prep_for_execute` (`Storage.pm:87-133`), before delegating to
`next::method`, inspect `$ident->columns_info` for any
`is_auto_increment` column whose `data_type` matches
`/^(?:uniqueidentifier(?:str)?|guid)\z/i`. When found on an `insert` that has
`_autoinc_supplied_for_op` set:

1. Locally suppress the autoinc flag for the duration of the delegated call —
   `local $self->{_autoinc_supplied_for_op} = 0` (`Storage.pm:109-112`) — so
   the inherited `IdentityInsert` wrapper sees no autoinc-with-value and emits
   no `SET IDENTITY_INSERT`.
2. Skip the trailing `SELECT SCOPE_IDENTITY()` for that statement
   (`$suppress_identity_insert` short-circuits the append at
   `Storage.pm:125-133`).

GUID PKs continue to be populated by `NEWID()` via the `UniqueIdentifier`
prefetch path.

## Rationale

The clean fix would be for a GUID column never to carry `is_auto_increment`,
but schemas in the wild (and core's own test schemas) model a GUID PK as
"auto-increment-shaped". Rather than forbid that, the storage detects the
shape at execute time and routes it away from the IDENTITY machinery. The
suppression is `local`-scoped to a single delegated call, so it cannot leak
into unrelated inserts in the same connection.

## Consequences

- GUID-PK inserts work against MSSQL without manual `SET IDENTITY_INSERT`
  juggling and without spurious `SCOPE_IDENTITY()` round-trips.
- **Corollary for non-PK GUID columns** (tracked as karr `dbio-mssql` #1,
  resolved): a non-PK `uniqueidentifier` that should be auto-populated needs
  `auto_nextval => 1`, **not** `is_auto_increment => 1` — only
  `auto_nextval` triggers `UniqueIdentifier::_prefetch_autovalues` for non-PK
  columns. A PK GUID is populated unconditionally and needs no flag.
- This is the most fragile and most surprising MSSQL invariant in the driver:
  the detection is keyed on `data_type` strings, so a column typed
  `uniqueidentifier` but flagged purely as IDENTITY would be mis-routed. New
  type spellings must be added to the regex at `Storage.pm:100`.
