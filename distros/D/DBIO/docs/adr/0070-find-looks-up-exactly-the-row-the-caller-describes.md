# ADR 0070 — find looks up exactly the row the caller describes

- Status: accepted (coordinator decision of 2026-10-29, karr k383, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-29
- Tags: resultset, find, unique-constraints, find-or-create, update-or-create, breaking, relates-0034

## Context

`DBIO::ResultSet::find` takes a condition hash or the values of a unique
constraint and returns one row. Its callers write a condition to name one
row: `find({ id => $id, owner_id => $me })` names the row with that id that
belongs to that owner. The `find_or_new`, `find_or_create`, `update_or_new`
and `update_or_create` helpers, and their `_async` variants, build on it and
take one hash that mixes the columns that identify a row with the columns that
are its data.

ADR 0034 decided how a relationship-valued key resolves to concrete foreign
key columns before the lookup; this ADR decides which condition may run and
what the query contains.

## Decision

### 1. A constraint is covered by concrete equalities

A condition covers a unique constraint when every column of the constraint has
a concrete equality in it: a defined plain scalar, or `{ '=' => $scalar }`, on
the top `AND` level of the condition. The condition counts after the
resultset's own condition (its scope) and the values of relationships are
merged in. Operators, value lists, `undef`, and a constraint that stands only
in an `OR` branch do not cover it. Constraints that share a column set count
once, `primary` first.

### 2. find runs the whole condition

`find(\%cond)` puts every key of the condition into the query as one `AND`
and drops none; a key given as `undef` stays as `IS NULL`. There is no `OR`
over several constraints.

At least one constraint has to be covered; with `key => '...'` that constraint
has to be. A condition that covers none throws. The message names the given
columns and the constraints of the source and names
`search(...)->single` as the way to look rows up by any other condition. There
is no fallback to the first row. `find(@pk)` with plain values is the lookup by
the primary key (or the named `key`). A column of the named constraint that is
missing or `undef` throws: only defined values cover a constraint, there is no
warning and no `IS NULL` lookup for it. A key of the condition outside the
covered constraint given as `undef` stays `IS NULL` in the `AND`.

`find_async` resolves its condition through the same code as `find`.

### 3. The write helpers separate identity from data

`find_or_new`, `find_or_create`, `update_or_new`, `update_or_create` and their
`_async` variants, and `find_or_new_related`, `find_or_create_related` and
`update_or_create_related` (which run them on the related resultset, the
foreign key it holds counting as part of the data), look the row up by the
columns of the covered constraint only (with `key`, exactly the named
constraint). The remaining values are the
data the row is created or updated with. When several constraints are covered
and `key` is absent, the call throws and asks for `key`; when none is covered
it throws.

### 4. Relationship values keep an explicit foreign key

A relationship value resolves to the foreign key columns of the source
(ADR 0034). A foreign key column the condition passes explicitly keeps its
value; a relationship that resolves it to a different value throws. A list
value for a relationship name is refused by `find`.

### 5. The row layer follows

`Row::get_from_storage` of a row without a primary key finds by its loaded
columns when they cover a unique constraint and searches for those columns
otherwise. Nested multi-create data is looked up only through a belongs_to
relationship and only when it covers a unique constraint (ADR 0071); in every
other case the row is created. `DBIO::PopulateMore` writes its rows with `update_or_create`, so a row
definition covers exactly one constraint.

### 6. Documentation

Application code writes `find({ id => $id })` for a value that comes from
outside the program, with the column named.

## Rationale

- **A condition means what it says.** The row returned is the row the caller
  described; every column the caller wrote restricts it.
- **Identity and data are different arguments.** A lookup by the constraint
  columns finds the row; the other values are what it holds or is given, so
  `update_or_create({ id => 1, name => 'new' })` updates row 1.
- **One question, one answer.** Whether a condition names a row is decided by
  the unique constraints of the source, in one place shared by `find`,
  `find_async` and the helpers.
- **Other conditions have a method.** `search(...)->single` states that the
  caller wants the first row of an arbitrary condition.

## Consequences

- `find` throws for a condition that covers no unique constraint, and for a
  relationship that contradicts an explicit foreign key.
- The write helpers throw when the data covers no constraint, and ask for
  `key` when it covers several.
- The contract of `find` is entered in `Changes` under Breaking Changes.
- `ResultSet::_non_unique_find_fallback` is retired.
- The private seams `_covered_constraints`, `_lookup_for_write` and
  `_find_identified` carry the rules for the helpers and the row layer.
