# ADR 0007 — A dedicated pure-ODBC storage class over a transport-neutral MSSQL base

- Status: accepted
- Date: 2026-07-25
- Tags: storage, rebless, registry, odbc, sybase, supersedes-0006

## Context

[ADR 0006](0006-single-sybase-based-storage-serves-odbc-and-sybase.md) recorded
that this driver ships exactly **one** MSSQL connection storage class,
`DBIO::MSSQL::Storage::Sybase`, serving both `DBD::ODBC` and `DBD::Sybase`, and
deliberately **no** pure-ODBC class. Its justification was that a second class
would be a near-empty duplicate of the whole MSSQL behaviour set and would have
to be kept in lockstep — a maintenance trap.

That objection held only because the MSSQL behaviour lived *in the Sybase-derived
class*. The price was structural: an ODBC connection was reblessed into a class
whose ISA carries `DBIO::Sybase::Storage` and its entire Sybase/FreeTDS layer —
`_using_freetds`, the `_init` statement-cache workaround, the `NoBindVars`
rebless, `syb_date_fmt` — none of which an ODBC connection ever executes. An
ODBC-only deployment still had to depend on the separate `dbio-sybase`
distribution.

## Decision

**Shared MSSQL semantics live in the transport-neutral base
`DBIO::MSSQL::Storage`, and each DBD gets its own thin transport class over
it. `DBD::ODBC` connections rebless into `DBIO::MSSQL::Storage::ODBC`, which has
no `DBIO::Sybase` in its ISA; `DBD::Sybase` connections keep
`DBIO::MSSQL::Storage::Sybase`.**

- `DBIO::MSSQL::Storage` (`lib/DBIO/MSSQL/Storage.pm`) owns everything that is
  identical regardless of DBD: the `DBIO::MSSQL::SQLMaker` dialect and
  `[ ]` quoting, IDENTITY handling on top of
  `DBIO::Storage::DBI::IdentityInsert` / `DBIO::Storage::DBI::UniqueIdentifier`,
  the MONEY bind cast and GUID-autoinc suppression in `_prep_for_execute`, the
  ordered-subselect wrap in `_select_args_to_query`, `_identity` / `last_insert_id`
  and savepoint handling. It registers only the synthetic DBD name via
  `register_driver('MSSQL' => __PACKAGE__)` and is never itself a rebless target.
- `DBIO::MSSQL::Storage::ODBC` (`lib/DBIO/MSSQL/Storage/ODBC.pm`) inherits from
  `DBIO::Storage::DBI::ODBC` and `DBIO::MSSQL::Storage` under `mro 'c3'` and
  **overrides nothing** — it is inheritance-only. It picks up the ODBC transport
  helpers (`_using_freetds`) from the core ODBC storage and the engine semantics
  from the base.
- `DBIO::MSSQL::Storage::Sybase` (`lib/DBIO/MSSQL/Storage/Sybase.pm`) inherits
  from `DBIO::Sybase::Storage` and `DBIO::MSSQL::Storage` and keeps the real
  Sybase/FreeTDS behaviour: its own `_rebless` into
  `DBIO::MSSQL::Storage::Sybase::NoBindVars` when placeholders are unsupported,
  and `DBIO::MSSQL::Storage::Sybase::DateTime::Format` as `datetime_parser_type`.

Both rebless paths converge from outside this repo: the core connector registry
maps `Microsoft_SQL_Server` to `DBIO::MSSQL::Storage::ODBC` for the
`_determine_connector_driver('ODBC')` lookup, and `DBIO::Sybase::Storage::_rebless`
special-cases the `Microsoft_SQL_Server` dbtype to the cross-namespace
`DBIO::MSSQL::Storage::Sybase`, loaded via `load_optional_class` so neither
distribution hard-depends on the other.

## Rationale

Hoisting the shared behaviour into the transport-neutral base voids ADR 0006's
central objection: the ODBC class duplicates nothing, because it *is* nothing but
inheritance. What used to be "one class, two transports" is now "one base, one
class per transport" — the same single source of truth for MSSQL semantics,
without the dead Sybase layer in the ODBC ISA.

The split also makes each path's `isa` honest. Before, both transports answered
`isa('DBIO::MSSQL::Storage::Sybase')`; now `t/11-mssql-odbc.t` and
`t/21-mssql-odbc-core.t` assert `DBIO::MSSQL::Storage::ODBC`, while `t/10-mssql.t`
and `t/20-mssql-core.t` assert `DBIO::MSSQL::Storage::Sybase` (or
`...::Sybase::NoBindVars`).

Shipped in commits `c73dcde` ("route ODBC off the Sybase class", 2026-06-24) and
`2cc2df7` (2026-07-12), live-verified against MSSQL 2022 over both transports —
hence **accepted**, not proposed.

## Consequences

- **ODBC-only deployments drop the `dbio-sybase` dependency.** The Sybase/FreeTDS
  layer is gone from the ISA of an ODBC connection; the offline suite passes with
  the optional Sybase stack absent entirely.
- **Two rebless targets to keep in mind, not one.** New MSSQL behaviour belongs in
  `DBIO::MSSQL::Storage` unless it is genuinely transport-specific; putting it in
  a transport class now silently excludes the other transport.
- **`DBIO::MSSQL::Storage::ODBC` is deliberately empty of overrides.** If it ever
  grows one, that is the signal that a transport difference was found — worth an
  ADR of its own.
- **The registry mapping itself remains core-owned**, exactly as under ADR 0006:
  it is hard-wired in core's `%_connector_registry`; this repo never calls
  `register_connector_driver`.

## Relationship to other ADRs

- **Supersedes [ADR 0006](0006-single-sybase-based-storage-serves-odbc-and-sybase.md).**
  0006's decision — one Sybase-derived class for both DBDs, no pure-ODBC class —
  is reversed here. 0006's text is left intact as the record of the single-class
  design and why it was tried; only its Status is updated.
- **Driver companion to core ADR 0035**
  (`dbio/docs/adr/0035-mssql-odbc-reblesses-to-dedicated-odbc-storage-class.md`),
  which records the core-owned half — the `%_connector_registry` flip — and
  supersedes core ADR 0016 the way this ADR supersedes 0006. The same ownership
  split applies as under 0006/0016: registry mapping is core's, the storage
  classes are this repo's.
