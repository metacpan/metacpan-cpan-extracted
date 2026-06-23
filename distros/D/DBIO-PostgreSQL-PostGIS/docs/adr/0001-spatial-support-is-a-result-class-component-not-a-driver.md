# ADR 0001 — Spatial support is a result-class component layered on the pg driver, not its own driver

- Status: accepted
- Date: 2026-06-23
- Tags: drivers, component, postgis, architecture, backfill

## Context

DBIO::PostgreSQL::PostGIS adds PostGIS geometry/geography support to a
PostgreSQL connection that is already served by the `dbio-postgresql` driver.
There were two shapes available: register a second `Pg` storage driver that
owns the connection, or ship the spatial behaviour as a result-class *component*
that piggybacks on the existing pg driver. The choice shapes how a user reaches
the feature and how it coexists with the family-wide `Pg` driver registration
owned by core/`dbio-postgresql`.

PostGIS is an *extension* of PostgreSQL, not a different engine — the connection,
SQL dialect, introspection and deploy are all PostgreSQL's. Only column-level
type handling and a handful of spatial query helpers are new. That asymmetry
argues against owning the driver.

## Decision

Ship spatial support as a **result-class component**, loaded with
`load_components('PostgreSQL::PostGIS')`, layered on top of the unmodified
`dbio-postgresql` driver — never as its own registered driver.

- The component class roots at `DBIO::Base`, not `DBIO::Schema`
  (`PostGIS.pm:8`), matching the `DBIO::PostgreSQL` component pattern. It loads
  the `InflateColumn` component (`PostGIS.pm:12`) and hooks
  `register_column`/`connection`.
- Storage extensions are opt-in by setting `storage_type` to
  `+DBIO::PostgreSQL::PostGIS::Storage`; the component's `connection` method
  sets that storage_type when the component is loaded (`PostGIS.pm:14-18`). The
  Storage subclasses `DBIO::PostgreSQL::Storage` and only *adds* the spatial
  helpers `ensure_postgis` / `postgis_version` (`Storage.pm:7,24-48`).
- The driver is **not** re-registered. A prior `register_driver('Pg')` global
  side-effect on the Storage class was deliberately removed because it clobbered
  the family-wide Pg mapping owned by core (karr #2, finding 3); the
  driver-registry mechanism stays core's, and this distribution does not touch
  it.

## Rationale

PostGIS is the same engine with extra column types, so layering on the pg
driver means one connection, one dialect, one introspection/deploy pipeline —
the component contributes only what is genuinely new (type inflation and spatial
query helpers) and inherits everything else by subclassing pg's Storage. Owning
a second `Pg` driver would have meant re-implementing or shadowing the pg
driver's registration for no behavioural gain, and the removed
`register_driver` side-effect is the concrete evidence of why that path is
hostile: a plugin that re-registers `Pg` overwrites the family's mapping for
every non-PostGIS PostgreSQL schema in the same process. The component form
keeps the blast radius to the Result classes that explicitly opt in.

This shape is shipped and exercised (`t/00-load.t`, `t/20-inflate.t`,
`t/introspect-storage.t`), hence **accepted**.

## Consequences

- Spatial behaviour is opt-in per Result class via
  `load_components('PostgreSQL::PostGIS')`; a PostgreSQL schema without it
  behaves as a plain `dbio-postgresql` schema, untouched.
- The pg driver's `Pg` registration is authoritative and unshadowed — this
  distribution must never re-introduce a `register_driver` call; that contract
  is owned by core/`dbio-postgresql`, not here.
- Storage spatial helpers (`ensure_postgis`, `postgis_version`) are reachable
  only when `storage_type` resolves to the PostGIS Storage subclass; the
  component wires that on load, but a schema that sets `storage_type` by hand
  must point at `+DBIO::PostgreSQL::PostGIS::Storage`.
- The Deploy/Introspect augmentation (which conforms to a core/`dbio-postgresql`
  contract, not a local decision) is layered the same way — see the cross-repo
  notes on `dbio-postgresql` (karr #1), not a local ADR.
