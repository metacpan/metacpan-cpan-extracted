# ADR 0071 — Mass assignment is checked where the caller's values enter the columns

- Status: accepted (coordinator decision of 2026-10-29, karr k381, under the maintainer's order to resolve the security findings before the release)
- Date: 2026-10-29
- Tags: resultset, row, relationship, create, update, populate, multi-create, is-guarded, breaking, relates-0034, relates-0070

## Context

`new_result`, `create`, `update(\%hash)`, `update_or_create`,
`update_or_new`, `populate` and multi-create take one hash of values and write
the columns of a row from it. The hash holds plain columns and relationship
values (a related object, a hash of related data, an array of such hashes);
`Row::new` resolves a relationship value to foreign key columns with
`set_from_related`, now or when the row is inserted. A resultset has a
condition of its own (its scope: `$artist->cds`, `search({ artist => 7 })`),
and a row created through it holds the values of that condition's equalities.

ADR 0070 decided which condition `find` runs and when nested multi-create data
identifies an existing row.

## Decision

### 1. Whose value it is

A value the caller passes is an assignment of the caller's: a column key of the
hash, and a relationship value (object, hash, array) that `Row::new` resolves
to columns through `set_from_related`, in the same call or when the row is
inserted. The values of the resultset's condition, and the foreign keys a row
inherits from its parent (`create_related`, `new_related`, the rows of a
`has_many` created along), are no assignment of the caller's. The checks of 2
and 3 apply to the resolved column assignments of the caller, by whichever
route they arrive.

### 2. A value of the caller does not contradict the scope

`ResultSet::_merge_with_rscond` (called from `new_result` and the update paths
of `update_or_create` / `update_or_new`), `new_related` and `populate` (also in
void context, which builds no row objects) refuse a value of the caller's that
contradicts an equality of the scope. The exception reads
`create on a scoped resultset: 'artist' is fixed to a value by the condition, got another value`.
The same value is allowed. A condition `IS NULL` fixes `undef`: `undef` is the
same value there, and contradicts a defined value of the condition. A
relationship value counts by the column value it resolves to, whatever name
the relationship has. A resultset reached through a `belongs_to` whose foreign
key is `NULL` holds `IS NULL` for the key of the related source: creating that
related row with a defined key of the caller's (`find_or_new_related`,
`find_or_create_related`) throws the same exception. There is no switch.

### 3. `is_guarded`

A column declared with `is_guarded => 1` in `add_columns` takes no value from
a hash: `new_result`, `create`, `update(\%hash)`, `update_or_create`,
`populate` (void context included) and multi-create throw when the caller
assigns it, also through a relationship value that sets it as foreign key.
`set_column`, the accessor and `update` without a hash set it. Inherited values
(1) are no assignment.

A relationship declared with `is_guarded => 1` in its attribute hash is
excluded from multi-create: a hash or array of hashes under its name throws.

`update_or_create` and `update_or_new` look the row up by the columns of the
covered constraint (ADR 0070); those columns name the row and assign nothing,
so a guarded column among them is not part of the update.

### 4. Multi-create looks up only through a belongs_to

A related row of a multi-create hash is fetched with `find` only when the
relationship is a `belongs_to` (its dependency metadata, `is_depends_on`, says
so, not the accessor type) and the hash gives every column of a unique
constraint of the related source (the rule "covered" of ADR 0070). Every other
related hash creates its row. `add_to_*` of a `many_to_many` follows the same
rule for the foreign row it is given as a hash.

Being unique is not a permission to link a row. Where callers may not link
existing rows, the relationship or its foreign key column carries
`is_guarded`.

### 5. Documentation

`DBIO::Row::new` and `DBIO::ResultSet::create` state that passing a request
hash to `create` is mass assignment and describe 2 to 4.

## Rationale

- **What lands in the columns is what is checked.** The route of a value (a
  column key, a relationship name that differs from its foreign key, an object,
  a nested hash) does not change the rule.
- **Inherited is not assigned.** Scope values and the parent's key are the
  resultset's and the relationship's own; only the caller's values are in
  question.
- **The declaration sits next to the column.** `is_guarded` is read where the
  other column attributes (`is_nullable`, `is_serializable`) are.
- **Linking is a declared property of the relationship.** `belongs_to` names a
  parent that exists on its own; the other relationships name rows that belong
  to the new row.

## Consequences

- Creating through a resultset whose condition fixes a column, with another
  value for that column, throws. Code that relied on the value of the call
  winning writes the row through the unscoped resultset.
- Multi-create creates the rows of `has_many`, `might_have` and `has_one` hashes
  and of `belongs_to` hashes that cover no constraint; it finds the others.
- `Changes` carries a Breaking Changes entry.
- The private seams `ResultSet::_scope_values`, `Row::__assert_caller_assignment`,
  `Relationship::Base::_inferred_from_related` and
  `ResultSource::_assert_columns_not_guarded`, `_assert_scope_agrees`,
  `_relationship_depends_on` carry the rules.

## Addendum — the message names the column, never a value

- Status: accepted (coordinator decision of 2026-11-02, under the maintainer's order to check every driver for values in error texts; ADR 0075)
- Date: 2026-11-02

### Decision

6. **The message of the scope check names the column and whether the
    condition and the caller give a value or NULL.** It reads `'artist' is
    fixed to a value by the condition, got another value`, `'artistid' is
    fixed to NULL by the condition, got a value` or `'artist' is fixed to a
    value by the condition, got NULL`; a reference reads `a <REF> value`. The
    value of the condition and the value of the caller are not part of it.
