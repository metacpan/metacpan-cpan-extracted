# ADR 0013 — The model is normalized; the catalog form is internal to the diff

- Status: accepted
- Date: 2026-10-25
- Tags: introspect, diff, generate, model

Implemented with karr k44. Decided by the maintainer (via the hub, 2026-10-24): the
introspected model is the normalized model of the other drivers, the catalog form stays
inside.

## Context

`Introspect::Columns` put what `SYSCAT.COLUMNS` holds into the columns of the model
(karr k41, k45): `data_type` was `TYPENAME` (`CHARACTER`, `DOUBLE`), `size` was `LENGTH`
(the storage length for a type declared without one: `INTEGER` 4, `DATE` 4, a string
`10,2` for a `DECIMAL(10,2)`), `default_value` was `DEFAULT`, the SQL text (`'it''s'`
with its quotes). That is what the diff needs to render DDL back exactly. But the same
columns are what `DBIO::Introspect::Base::table_columns_info` hands to `DBIO::Generate`,
which writes them into a result class: `data_type => 'CHARACTER'`, `size => 4` on an
`INTEGER`, `size => '10,2'`, `default_value => "'it''s'"` (a default that is then quoted
a second time by `install_ddl`). Every other driver's model holds the value a result
class declares.

## Decision

1. **The columns of the model are normalized** (`DBIO::Introspect::Base`): `data_type`
   lower-case as a result class writes it (`char` for `CHARACTER`, `double precision`
   for `DOUBLE`, else `TYPENAME` lower-cased); `size` the declared length — a number,
   `[precision, scale]` for `DECIMAL`, the precision for `TIMESTAMP`, 16/34 for
   `DECFLOAT` — and absent for a type Db2 declares without one (`SMALLINT`, `INTEGER`,
   `BIGINT`, `REAL`, `DOUBLE`, `DATE`, `TIME`, `XML`, `BOOLEAN`, `LONG VARCHAR`);
   `default_value` the value: a string literal unquoted, a number as its text, an
   expression a SCALAR reference (the form `install_ddl` writes bare; dbio-oracle does
   the same), `DEFAULT NULL` and no default `undef`.
2. **The catalog form stays in the same column hash under internal names**:
   `catalog_type`, `catalog_size`, `catalog_default` — the values the model held before.
   `Diff::Table`, `Diff::Column` (rendering, `reorg_recommended`, the identity checks)
   and the comparison read these and only these; the comparison is
   `DBIO::Diff::Compare::changed_fields` on them with the field groups of core's
   `changed_column_fields`. The diff therefore does what it did before, statement for
   statement. The fields are documented as internal in `Introspect::Columns`; no other
   consumer reads them.
3. A mock model in a diff test carries the catalog fields.

## Alternatives considered

- **Raw in the model** (status quo): the diff stays as it is, and the generator keeps
  getting `CHARACTER`, `size => 4` and quoted default text. Every consumer of the
  contract would have to know Db2's catalog form. Rejected by the maintainer.
- **Normalize in `table_columns_info` only**, model raw: the contract method would
  convert, the model stays catalog-shaped. The model is also what a driver-independent
  consumer reads directly (`$introspect->model`); two shapes behind one name is the
  problem this ADR removes.
- **Derive the catalog form from the normalized fields in the diff**: not invertible
  (`INTEGER` 4 is gone, a bare `CLOB`'s length is a default, `DECIMAL(10)` and
  `DECIMAL(10,0)` merge); the diff would compare different things than the server holds.

## Consequences

- `size` of a bare `CLOB`/`BLOB` is the length the server gave it (1048576 for a `CLOB`);
  a generated class declares it, and installs the same type.
- A model with normalized fields only (hand-written, no catalog fields) cannot be
  diffed: `catalog_type` is missing and the type renders as the default `VARCHAR`.
- Whether each type class survives `introspect → DBIO::Generate → install_ddl →
  introspect` is measured, per column, in `t/73-generate-roundtrip-live.t`.
- Tests: `t/45-introspect-columns.t` (both descriptions of a row), `t/72-diff-reads-catalog-fields.t`
  (the diff reads the catalog fields only), `t/73-generate-roundtrip-live.t`.
