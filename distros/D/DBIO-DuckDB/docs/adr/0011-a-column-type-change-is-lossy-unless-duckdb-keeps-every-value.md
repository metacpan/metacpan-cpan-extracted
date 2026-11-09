# ADR 0011 — A column type change is lossy unless DuckDB keeps every value

- Status: accepted
- Date: 2026-10-30

## Context

Core's `DBIO::Deploy::Base::apply` (core k399, ADR 0080) runs a diff with a
drop of something the schema does not declare, or with an operation that
answers `lossy`, only with `allow_destructive => 1`. `ALTER COLUMN ... SET DATA
TYPE` casts the stored values; a cast can change a value (`FLOAT` to `DOUBLE`
shows another decimal reading, a `DECIMAL` to a smaller one, a text to a
number) or fail half way through the diff. `DBIO::DuckDB::Diff::Column`
therefore has to say which changes keep every value.

## Decision

1. `DBIO::DuckDB::Diff::Column::lossy` answers through
   `DBIO::Diff::Compare::column_change_lossy`. A pair of types is lossless only
   if it is in `%DBIO::DuckDB::Diff::Column::LOSSLESS_PAIRS`; the same type with
   a larger size is lossless by the comparison itself. Everything else is lossy.
   In doubt, lossy.
2. The pairs were measured on libduckdb 1.5.3 (in-memory database, a table
   with the boundary values of the old type, `SET DATA TYPE`, the values read
   back through a cast to the old type and compared with the originals):
   - signed integers to a wider one: `TINYINT` < `SMALLINT` < `INTEGER` <
     `BIGINT` < `HUGEINT`;
   - unsigned integers to a wider one: `UTINYINT` < `USMALLINT` < `UINTEGER` <
     `UBIGINT`;
   - an unsigned integer to a signed one of more bits (`UTINYINT` to
     `SMALLINT` and up, ..., `UBIGINT` to `HUGEINT`);
   - `DATE` to `TIMESTAMP` (midnight);
   - `DECIMAL(p,s)` to `DECIMAL(p2,s)` with `p2 >= p`, through the size: the
     introspected type carries precision and scale in its name, which `lossy`
     reads as the size.
3. Measured and left lossy because the value is rewritten or the result depends
   on something outside the column: a number to `VARCHAR` or `JSON`, anything
   from `VARCHAR`, `FLOAT` to `DOUBLE` (the decimal reading changes), an
   integer to `DOUBLE` (representation), an integer to `DECIMAL` (fails when the
   value does not fit), `TIMESTAMP` and `TIMESTAMPTZ` either way (session time
   zone), `DATE` to `TIMESTAMPTZ`, `BOOLEAN` to a number, a narrowing of any
   kind, and a change of the scale of a `DECIMAL`.
4. A change of `NOT NULL` or of the default keeps every value and is not lossy.

## Consequences

An upgrade that widens an integer or a `DECIMAL` runs as it is; one that
narrows, converts through text or changes the time zone reading needs the
release. `t/67-diff-lossy.t` holds the table and one run through `apply` each
way. A pair added to the list is measured first, the way point 2 says.

## Addendum 2026-10-30: the rebuild

`DBIO::DuckDB::Diff::Rebuild` answers `lossy` by the same rule: a column its
`column_ops` drop, or change with `Diff::Column::lossy` (the pair list above),
makes the rebuild need `allow_destructive`. A rebuild that copies every column
unchanged (a UNIQUE dropped, a foreign key added) runs without the release.
Its `summary` names `table.column` of each such column, never a value.
`t/66-diff-rebuild.t` holds both ways.
