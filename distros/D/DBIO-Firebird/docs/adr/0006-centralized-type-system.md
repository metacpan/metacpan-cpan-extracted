# ADR 0006 — Centralized type system in DBIO::Firebird::Type (bare type, size separate)

- Status: accepted
- Date: 2026-06-20
- Tags: types, ddl, introspect, diff, backfill

## Context

Three layers in this driver need to agree on Firebird type handling:

- `Introspect::Columns` maps `rdb$field_type` numbers to SQL type names (the
  *introspection* direction).
- `DDL` maps DBIO/SQL::Translator `data_type` values to concrete Firebird DDL
  types (the *deploy* direction).
- `Diff::Table` renders `(size)`/`(precision,scale)` suffixes when comparing
  and emitting column SQL.

Originally these three mappings lived in three modules pulling in different
directions, and they disagreed about *where the size lives*. Introspection
folded the size into the type string (`"decimal(18,6)"`) **and** also set a
separate `size` field, so `Diff::Table` — which renders the size from the model
— emitted it twice, producing the `"decimal(18,6)(18,6)"` double-size bug.

## Decision

`DBIO::Firebird::Type` is the single home for the Firebird type system, with one
invariant: **the type string is bare; size travels separately and is rendered
in exactly one place.** It exports three functions (`Type.pm`):

- `sql_type_from_rdb($field_type, $sub_type)` — maps an `rdb$field_type`
  number to a **bare** SQL type name via the `%RDB_TYPE` table, falling back to
  `'varchar'` for unknown types. It never folds size into the name.
  (`$sub_type` is accepted for forward compatibility but not yet used.)
- `ddl_type_from_info($column_info)` — maps a DBIO/SQL::Translator column-info
  hashref to a concrete Firebird DDL type string (`INTEGER`, `VARCHAR(255)`,
  `DECIMAL(18,6)`, ...).
- `render_size($size)` — the **one** place a model `size` becomes a SQL
  suffix: a scalar yields `"(n)"`, an arrayref yields `"(p,s)"`, and `undef`
  yields `""`.

The introspected model carries `data_type` as the bare type and `size`
separately (`undef`, a scalar, or `[precision, scale]`), and Introspect, Diff
and DDL all go through `DBIO::Firebird::Type` rather than carrying their own
type/size logic.

## Rationale

The type mapping and the size-rendering rule are *the same facts* consumed by
introspection, DDL and diff; three copies of those facts is not a style nit but
the direct cause of a real bug class. In a test-deploy-and-compare deployer, a
type/size disagreement between the introspector and the diff renderer manifests
as a phantom or malformed ALTER on every upgrade — `"decimal(18,6)(18,6)"` was
exactly that. Centralising in one module, with the explicit "bare type, size
separate, rendered once via `render_size`" contract, makes the three layers
agree by construction. The module's own DESCRIPTION POD records this history and
the contract, so the invariant survives future edits.

## Consequences

- New `rdb$field_type` mappings, new base→Firebird DDL mappings, and any change
  to size rendering go in `DBIO::Firebird::Type` only. Introspect, Diff and DDL
  consume it; none may re-derive type or size.
- Type strings in the model are bare by contract; any consumer that needs the
  size suffix must call `render_size` — never concatenate `(...)` into the type
  itself, or the double-size bug returns.
- `sql_type_from_rdb` falls back to `'varchar'` for unrecognised
  `rdb$field_type` numbers; an unmapped type degrades to varchar rather than
  throwing, which a future mapping addition should tighten if needed.
