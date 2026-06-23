# ADR 0006 — ScalarMap collapses all DB types to four GraphQL scalars

- Status: accepted
- Date: 2026-06-21
- Tags: graphql, scalar, types, scalarmap, backfill

## Context

Every column in a generated schema needs a GraphQL type, and several places
need to agree on what that type is: the per-source object type's scalar
fields (`GraphQL.pm`), the per-column filter input (`Filter.pm`, via the
`*Filter` selection), the mutation argument types (`Mutation.pm`), and the
singular-lookup / relationship-PK arguments. DBIO columns carry an arbitrary
`data_type` string drawn from the underlying database (`int`, `bigint`,
`tinyint(1)`, `decimal`, `varchar`, `text`, `datetime`, `json`, `uuid`, …).

GraphQL's built-in scalar set is small: `Int`, `Float`, `Boolean`, `String`.
The schema could mint **custom GraphQL scalars** (a `DateTime` scalar, a
`JSON` scalar, a `UUID` scalar) to preserve richer type information, at the
cost of defining, naming, and serialising each custom scalar and keeping its
coercion rules correct across every driver's `data_type` spellings.

## Decision

`DBIO::GraphQL::ScalarMap::for_column` collapses every DB `data_type` to one
of the **four built-in GraphQL scalars** — `Int`, `Float`, `Boolean`,
`String` — and mints **no custom scalars** (`ScalarMap.pm`).

The mapping is a regex match on `data_type` in a **fixed priority order**,
and the order is correctness-critical:

1. **Boolean first** — matches `bool` / `boolean` and the MySQL idiom
   `tinyint(1)`. Boolean must be tested *before* Int, otherwise `tinyint(1)`
   would be swallowed by the integer pattern and a boolean column would
   surface as `Int`.
2. **Float second** — `float` / `double` / `real` / `money` / `decimal` /
   `numeric`. Float must be tested *before* the integer catch-all so a
   `decimal`/`numeric` column is not mis-bucketed as `Int`.
3. **Int third** — the integer family (`int`, `integer`, `bigint`,
   `smallint`, `tinyint`, `mediumint`, `serial`).
4. **String fallback** — anything unrecognised.

`date` / `datetime` / `json` / `uuid` deliberately fall through to **String**.

This module is the single chokepoint: filter, mutation, relationship, and the
core field builder all call `for_column` rather than re-deriving the mapping.

## Rationale

Four built-in scalars keep the generated schema portable and dependency-free:
every GraphQL client and tool understands `Int`/`Float`/`Boolean`/`String`
out of the box, with no custom-scalar coercion to define or keep in sync. A
date, a JSON blob, and a UUID are all faithfully representable as `String`
over the wire, and the cost of losing the richer GraphQL type is small
compared with the cost of defining and maintaining correct custom-scalar
serialisation for every driver's `data_type` vocabulary.

The fixed priority order is the load-bearing part. The type families overlap
textually — `tinyint(1)` is a substring of the integer family, `decimal` and
`numeric` would also match a loose number pattern — so the only thing keeping
each column in the right bucket is testing the more specific patterns
(Boolean, then Float) before the broad integer catch-all. The ordering is
not stylistic; reordering it silently mis-types columns.

Centralising in one `for_column` means every consumer agrees on a column's
scalar by construction, which is what lets the object type, its filter input,
and its mutation args stay consistent without a shared table duplicated
across modules.

## Consequences

- **`for_column` is the one place the DB-type → GraphQL-scalar decision
  lives.** Filter, Mutation, Relationship, and the field builder must consume
  it, never re-derive a mapping. A new mapping rule (or a new family) is a
  change to `ScalarMap.pm` alone.
- **The match order must be preserved.** Any reordering — in particular moving
  Boolean after Int, or Float after the integer catch-all — is a correctness
  regression: `tinyint(1)` would become `Int`, and `decimal`/`numeric` would
  become `Int`. New patterns must be inserted respecting the
  specific-before-general invariant.
- date/datetime/json/uuid are `String` on the wire by design. Clients that
  need richer handling parse the string themselves; the schema does not
  promise a structured GraphQL type for them.
- No custom GraphQL scalars exist in the schema, so there is no custom-scalar
  coercion surface to maintain or to get wrong per driver.
