# ADR 0004 — Spatial column auto-detection by data_type + resultset_class promotion guard

- Status: accepted
- Date: 2026-06-23
- Tags: postgis, register-column, inflate, resultset, auto-detection, backfill

## Context

When a Result class loads `PostgreSQL::PostGIS`, the component must decide *which*
columns get geometry inflate/deflate wired, and it must give the source's
resultsets the spatial query helpers (ADR 0005). Two design questions arise:
should spatial columns be marked explicitly by the user or detected from
`data_type`, and how is the resultset class promoted without trampling a user who
has their own `resultset_class`?

A geometry column is already declared with `data_type => 'geometry'` /
`'geography'` — that declaration carries the signal, so requiring a second
explicit per-column flag is redundant for the common case. But auto-promotion of
the resultset class can silently discard a user's custom subclass if done
naively.

## Decision

Detect spatial columns from `data_type` (overridable), and promote the
`resultset_class` **once**, behind a guard that leaves user subclasses alone.
Both happen in `register_column` (`PostGIS.pm:101-148`), after the parent's
registration runs.

- **Auto-detection with explicit override.** A column is spatial when
  `inflate_geometry` is set (honoured verbatim), else when `data_type` lowercases
  to `geometry` or `geography` (`PostGIS.pm:105-110`). Setting
  `inflate_geometry => 0` opts a geometry-typed column out; `inflate_geometry => 1`
  opts a differently-typed column in. The matched column gets inflate/deflate
  handlers (the codec round-trip of ADR 0002), with the column's `srid` used as
  the default SRID for bare-WKT inflation (`PostGIS.pm:118-147`).
- **resultset_class promotion guard.** On the first spatial column, if the
  source's current `resultset_class` does **not** already inherit from
  `DBIO::PostgreSQL::PostGIS::ResultSet`, it is promoted to that class
  (`PostGIS.pm:112-116`). A user who set `resultset_class` to a subclass of the
  PostGIS ResultSet is detected by the `isa` check and skipped, so their methods
  survive alongside the spatial helpers.

## Rationale

`data_type` already names the column geometry/geography, so detecting from it is
the least-surprising default — the user declares the column once and inflation
follows — while the `inflate_geometry` override keeps the door open for the
two edge cases (a geometry column that should stay a raw string, or a
non-standard type that should still inflate). The promotion guard is the
load-bearing safety check: blindly setting `resultset_class` would silently
delete a user's custom resultset methods the moment they added a geometry column,
so the `isa` test is what lets the component add its helpers without owning the
resultset class outright. Promoting only once (the guard short-circuits when the
class is already a PostGIS ResultSet) keeps repeated `register_column` calls
idempotent.

This registration behaviour is exercised by the inflate and resultset tests
(`t/20-inflate.t`, `t/resultset-predicates.t`), hence **accepted**.

## Consequences

- Declaring `data_type => 'geometry'`/`'geography'` is sufficient to get
  inflation; no extra per-column flag is needed in the common case.
- `inflate_geometry => 0` is the documented opt-out for a geometry column that
  should round-trip as a raw string; `inflate_geometry => 1` force-enables on
  any column.
- A user who needs custom resultset methods *and* the spatial helpers must
  subclass `DBIO::PostgreSQL::PostGIS::ResultSet` and set `resultset_class` to
  that subclass before the first geometry column registers — the guard then
  leaves their class in place. A non-PostGIS custom `resultset_class` will be
  replaced on first spatial column (the documented contract).
- The default-SRID-from-column behaviour means bare-WKT inflation depends on the
  column's `srid` metadata; a geometry column with no declared SRID inflates
  bare WKT with an undefined SRID.
