# ADR 0005 — Spatial query helpers emit -bool / order_by ScalarRef literals

- Status: accepted
- Date: 2026-06-23
- Tags: postgis, resultset, sqlmaker, scalarref, literal, knn, spatial-query, backfill

## Context

The PostGIS ResultSet offers spatial query shortcuts —
`within_distance`, `bbox_intersects`, `nearest_to`, `order_by_distance`,
`with_distance`, and the `ST_*` predicate family (`intersects`, `contains`,
`within`, `touches`, `crosses`, `overlaps`). Each must put a PostGIS function
call (`ST_DWithin`, `ST_Intersects`, …) or operator (`&&`, `<->`) into the
generated SQL, with the user's geometry argument bound safely. The alternative to
emitting raw SQL fragments would be to register every spatial function/operator
through the SQLMaker `expand_op` mechanism, as `dbio-postgresql` does for its
JSONB operators (its ADR 0005).

PostGIS exposes hundreds of `ST_*` functions and several geometry operators, most
taking positional arguments and casts; modelling each as a first-class SQLMaker
operator is a large, open-ended surface for a thin convenience layer.

## Decision

Implement every spatial helper as a thin wrapper that splices a **raw SQL
fragment** into a `-bool` / `order_by` / `+select` **ScalarRef literal**, with the
geometry argument rendered to `(SQL, @binds)` by one shared helper — never via
SQLMaker operator registration.

- **One geometry renderer.** `_geom_arg` turns the user's argument into
  `('SQL fragment', @binds)` (`ResultSet.pm:43-62`): a `\['ST_…', @binds]`
  REF passes through, a Geometry object becomes `ST_GeomFromText(?, ?)` /
  `ST_GeomFromText(?)` bound with WKT (+SRID), and a plain EWKT string becomes
  `ST_GeomFromEWKT(?)`. This is the offline-testable seam.
- **Function predicates via `-bool` literal.** `_spatial_search` builds
  `FUNC(me.col, <geom-sql>[, ?…])` and runs it through
  `search({ -bool => \[ $sql, @binds ] })` (`ResultSet.pm:64-74`).
  `within_distance` (`ST_DWithin`) and the six generated `ST_*` predicates ride
  this path (`ResultSet.pm:76-116`). `bbox_intersects` emits the `&&` operator
  the same way (`ResultSet.pm:128-135`).
- **Ordering via `order_by` literal.** `nearest_to` orders by the `<->` KNN
  operator (`ResultSet.pm:147-156`), `order_by_distance` by `ST_Distance`
  (`ResultSet.pm:168-175`), both as `order_by => \[ $sql, @binds ]`.
  `with_distance` adds an `ST_Distance` column via `+select`/`+as`
  (`ResultSet.pm:188-197`). All use `current_source_alias` to qualify the column.
- **Raw `-bool` stays the escape hatch.** A fully custom predicate is just
  `search({ -bool => \['ST_…(…)', @binds] })` — the same mechanism, exposed
  directly (documented in `PostGIS.pm` SYNOPSIS and `ResultSet.pm` DESCRIPTION).

## Rationale

The PostGIS function surface is too large and positional to model as registered
operators; a ScalarRef literal lets each helper emit exactly the call PostGIS
wants, with binds, in a few lines, and composes with ordinary `->search`
because every helper returns a chainable resultset. Funnelling geometry argument
rendering through the single `_geom_arg` helper keeps binding correct and
consistent across all helpers and gives one place to unit-test the SQL/bind
output offline. Using `current_source_alias` rather than a hard-coded `me`
keeps the fragments correct under joins. Contrast with `dbio-postgresql`'s JSONB
operators, which *are* registered via `expand_op` (its ADR 0005): that is the
right tool for a small fixed operator set that users reach through normal
`search({ col => {...} })` syntax; the spatial helpers are an explicit
method-call convenience over an open-ended function library, so the literal-SQL
approach fits where operator registration would not.

The helpers' generated SQL is covered offline (`t/resultset-predicates.t`) and
against a live PostGIS cluster (`t/30-spatial-live.t`), hence **accepted**.

## Consequences

- Adding a new spatial helper is a few lines over `_spatial_search` / `_geom_arg`
  — no SQLMaker operator registration, no `expand_op` handler.
- The helpers depend on SQL::Abstract's ScalarRef-literal contract
  (`-bool`/`order_by`/`+select` accepting `\[ $sql, @binds ]`); a change to how
  literals are spliced would land here and must be regression-tested against the
  spatial predicate tests.
- Geometry arguments accept three forms uniformly (Geometry object, EWKT string,
  raw `\['ST_…', @binds]`) because every helper routes through `_geom_arg`.
- For any predicate not wrapped as a helper, the user drops to
  `search({ -bool => \[…] })` directly — the helpers are sugar over that
  always-available mechanism, not a closed set.
