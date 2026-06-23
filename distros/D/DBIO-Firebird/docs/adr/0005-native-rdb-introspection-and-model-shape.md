# ADR 0005 — Native rdb$ introspection and the canonical model shape

- Status: accepted
- Date: 2026-06-20
- Tags: introspect, rdb, model, contract, generate

## Context

DBIO's deploy/upgrade triad is test-deploy-and-compare: introspect the live DB,
deploy the desired schema to a scratch DB, introspect that, and diff the two
*normalised* models (core ADR 0006/0007). For that to be sound, introspection
must read the engine's own catalog directly and return a stable, documented
model shape that the Diff layer and the `DBIO::Generate` contract both consume.

Firebird exposes its catalog through the `rdb$*` system tables, not through the
generic DBI metadata methods (`column_info`, `foreign_key_info`, ...). The DBI
metadata layer over DBD::Firebird/InterBase is incomplete and does not expose
the constraint/index/generator detail the diff needs.

## Decision

`DBIO::Firebird::Introspect` (subclass of `DBIO::Introspect::Base`) reads the
live database through the `rdb$` system tables via thin per-artifact fetch
helpers, and `_build_model` (`Introspect.pm:33-55`) assembles a model with
**exactly five top-level sections**, each keyed by bare (unqualified) table
name — Firebird has no schemas:

    { tables, columns, indexes, unique_constraints, foreign_keys }

The helpers and their catalog sources:

- `Introspect::Tables` — `rdb$relations` (tables + views).
- `Introspect::Columns` — `rdb$relation_fields` (incl. `rdb$null_flag`) joined
  to `rdb$fields`.
- `Introspect::Indexes` — `rdb$indices` + `rdb$index_segments`.
- `Introspect::Uniques` — `rdb$relation_constraints` (type `UNIQUE`) +
  `rdb$index_segments`.
- `Introspect::ForeignKeys` — `rdb$relation_constraints` + `rdb$indices` +
  `rdb$ref_constraints`.

The exact field-by-field shape (the column hashref keys, the
`[ constraint_name, \@cols ]` unique form, the FK hashref) is specified in the
**THE INTROSPECTED MODEL** POD of `Introspect.pm` and is the single source of
truth shared by Introspect, Diff and the `DBIO::Generate` contract.

The normalized generation contract (`table_keys`, `table_columns_info`,
`table_pk_info`, `table_uniq_info`, `table_fk_info`, `table_is_view`, ...) is
inherited unchanged from `DBIO::Introspect::Base`, because the assembled model
follows the base's canonical single-schema shape — no Firebird-specific
override of the contract methods is needed (recorded in karr #2).

### Sub-decision A — `FetchHashKeyName = 'NAME_lc'`

`_build_model` forces `local $dbh->{FetchHashKeyName} = 'NAME_lc'`
(`Introspect.pm:38-40`) for the whole build. Firebird returns result-column
names **upper-cased**, but the fetch helpers read **lower-case** `rdb$` keys
from `fetchrow_hashref` (e.g. `$row->{'rdb$relation_name'}`). Forcing
lower-cased hash keys reconciles the two so the helpers' hash lookups hit.
(Statement handles inherit this at prepare time.)

### Sub-decision B — UNIQUE constraints vs CREATE UNIQUE INDEX are split

A Firebird `UNIQUE` *constraint* and a standalone `CREATE UNIQUE INDEX` are
**two different catalog objects**. The two are introspected by two different
helpers:

- `Introspect::Uniques` reads `UNIQUE` *constraints* via
  `rdb$relation_constraints` (`rdb$constraint_type = 'UNIQUE'`) and feeds
  `unique_constraints` — the authoritative source for `table_uniq_info`.
- `Introspect::Indexes` **deliberately excludes** constraint-backed indexes:
  after fetching from `rdb$indices`, it queries `rdb$relation_constraints` for
  `PRIMARY KEY`/`UNIQUE` index names and skips them
  (`Introspect/Indexes.pm:61-83`), so only explicit `CREATE INDEX` objects land
  in `indexes`.

Only the constraints feed `table_uniq_info`; the standalone unique indexes stay
in `indexes` (recorded in karr #4, the `table_uniq_info` gap).

## Rationale

The `rdb$` tables are the only source with the constraint-level, generator-level
and referential-action detail the diff and generation contracts need; the DBI
metadata layer would lose information and make the introspect/diff round-trip
unreliable. Pinning the model to one documented five-section shape lets Diff and
`DBIO::Generate` depend on a single contract rather than each re-deriving
Firebird's catalog. The `NAME_lc` reconciliation is the small but essential
glue that lets the helpers use ordinary lower-case `rdb$` key lookups despite
Firebird's upper-casing. Keeping constraint-uniques and index-uniques separate
matters because they are deployed and dropped differently: folding a
`CREATE UNIQUE INDEX` into `table_uniq_info` would make the diff propose
constraint operations for a plain index (and vice versa).

## Consequences

- All Firebird introspection reads `rdb$*` directly; do not reach for DBI
  metadata methods to "simplify" a helper — it would lose the detail the diff
  depends on.
- The per-helper subdir layout matches every other DBIO driver
  (`Introspect/{Tables,Columns,Indexes,Uniques,ForeignKeys}`); new
  introspected facts go in the matching helper.
- `THE INTROSPECTED MODEL` POD is the contract; any change to a section's shape
  must be made there and in Diff/Generate consumers together.
- `NAME_lc` is set for the whole `_build_model`; helpers may rely on lower-case
  `rdb$` keys and must not also case-fold result-column names themselves.
- The constraint/index split must be preserved: `Uniques` owns constraints,
  `Indexes` excludes constraint-backed indexes.
