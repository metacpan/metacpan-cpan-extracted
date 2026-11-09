# ADR 0074 — A column value is a value

- Status: accepted (coordinator decision of 2026-10-30, karr k384, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-30
- Tags: row, resultset, sqlmaker, create, update, populate, array, literal-sql, breaking, relates-0071

## Context

`new_result`, `create`, `update`, `populate`, `ResultSet::update` and the row
accessors hand a value per column to the storage, where the SQLMaker renders
it. A reference in that position has a meaning to the SQLMaker: a scalar
reference or an array reference of `[ $sql, @bind ]` is literal SQL, a hash
reference is an operator expression. ADR 0071 decided whose values are checked
where they enter the columns; this ADR decides what a value is.

## Decision

### 1. What a column value is

The value that goes to the storage for a column is one of

- a plain scalar, `undef`,
- a blessed object,
- an array reference (the array data type, always bound as one value),
- an explicit literal: `\'...'` or `\[ $sql, @bind ]`.

A hash reference, a code reference, a glob reference or a reference to a
reference that is not a literal is no column value. It throws
`column 'name' got a HASH reference -- a column value is a value; use \[ ... ]
for literal SQL or an inflated column type`. The message names the column and
the kind of reference, never the value.

### 2. Arrays are bound

`DBIO::SQLMaker` is built with `array_datatypes => 1` for every storage: sync,
async and the mock storage. An array reference as a value is one bound value,
never literal SQL. Literal SQL with binds is `\[ $sql, @bind ]`.

### 3. Where it is checked

One validator, called from several places, as no single place sees every
route:

- early, for a raw column (no inflate, filter or encode):
  `Row::new`, `set_column`, `set_columns`, `set_inflated_columns`,
  `store_column`;
- finally, after the deflate, in the `insert` and `update` of the row;
- `ResultSet::populate` (the bulk path that goes straight to the storage and
  the void context included) and `ResultSet::update` (mass update without a
  row) check their values as storage values.

### 4. Relationship values and inflated columns

In multi-create a hash or array under a relationship name is resolved as a
relationship first; only column values are checked. An inflated column
(`InflateColumn` with a hash as content, a serializer, `FilterColumn`,
`EncodedColumn`) takes a hash reference; its deflated value is checked.

### 5. Documentation

`update`, `create` and `populate` state the rule. `Manual/FAQ.pod` shows
copying a column as an explicit, quoted literal.

The search condition is not part of this ADR (`search_untrusted`, karr k378).

## Rationale

- **One meaning per position.** A column value is data; operators and SQL
  fragments are written as literals, where the reader sees them.
- **Arrays are values.** A bound array is the same in every storage and
  independent of the shape of its content.
- **Checked on the way to the storage.** Early checking names the column at the
  call; the final check covers what inflation and filters produce.

## Consequences

- A hash reference as value of a raw column throws; code that copies a column
  writes `\[ '"other"' ]`.
- An array reference with SQL in its first element is bound, not rendered.
- `Changes` carries a Breaking Changes entry.
