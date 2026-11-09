# ADR 0005 — The Age deploy class is wired through the chainable `dbio_deploy_class` hook

- Status: superseded by core ADR 0066 (karr k20): the mechanism is the extension list and `DBIO::PostgreSQL::Age::Extension`; the decision that graph schemas are never dropped stands
- Date: 2026-10-16
- Tags: deploy, composition, storage-layer, postgis, age, introspection
- Amends: ADR 0004 (the "not wired through `dbio_deploy_class`" paragraph)

## Context

ADR 0004 left `DBIO::PostgreSQL::Age::Deploy` unwired: `dbio_deploy_class` was a
single-owner storage-layer hook, `DBIO::PostgreSQL::PostGIS::Storage` owned it,
and a second owner made AGE + PostGIS composition croak.

Core (dbio, karr ctx-hookchain) made `dbio_deploy_class` a chainable hook of
`DBIO::Storage::Composed`: when two or more layers define it, the composed
storage returns a synthesised deploy class whose `@ISA` (c3) are the layers'
deploy classes in layer registration order; one layer is unchanged.

That moves the problem into the deploy classes. `Age::Deploy::_introspect_class`
and `PostGIS::Deploy::_introspect_class` each returned a constant introspector,
so in a chain the first wins and the other's work is lost: the PostGIS geometry
metadata, or the graph filter (which is a `DROP SCHEMA <graph> CASCADE` in the
diff).

## Decision

- `DBIO::PostgreSQL::Age::Storage` defines `dbio_deploy_class`, returning
  `DBIO::PostgreSQL::Age::Deploy`. No `@ISA` of a component or a storage layer
  changes; the connect path is untouched (ADR 0003, core ADR 0032 section 7).
- `Age::Deploy::_introspect_class` is cooperative (`use mro 'c3'`). It asks
  `next::method` for the basis introspector:
  - the base `DBIO::PostgreSQL::Introspect` becomes `Age::Introspect`;
  - an `Age::Introspect` subclass is returned as is;
  - any other class `X` becomes the synthesised, cached class
    `DBIO::PostgreSQL::Age::Introspect::On::<X with :: as _>` with
    `@ISA = (Age::Introspect, X)` under c3.
- `Age::Introspect::_build_model` calls `next::method` instead of `SUPER::`, so
  in the synthesised class it builds the other introspector's model first and
  filters the graph schemas out of the result.
- `Age::Deploy` overrides no `install`, so it has nothing to chain there.
- The order of the chain is the registration order of the layers, that is the
  order of `load_components`. It is not decided here.

## Consequences

- AGE alone: `$storage->dbio_deploy_class` is `Age::Deploy`, as before for
  direct use.
- AGE then PostGIS: chain `[Age::Deploy, PostGIS::Deploy]`, `_introspect_class`
  is a class that is an `Age::Introspect` and a `PostGIS::Introspect`.
  `t/40-stacking.t` and `t/14-age-chain-live.t` pin it.
- **PostGIS then AGE:** the chain is `[PostGIS::Deploy, Age::Deploy]` and
  `PostGIS::Deploy::_introspect_class` still returns a constant, which shadows
  Age. Geometry metadata is kept, the graph filter is lost (an unrestricted
  deploy again wants to drop the graph). `PostGIS::Deploy` has to call
  `next::method` in `_introspect_class` (and in `install`, if it overrides it).
  That is a change in dbio-postgresql-postgis, not made here; `t/40-stacking.t`
  carries it as a TODO test. Until then AGE has to be registered first.
- The synthesised introspector class is a naming convention of this
  distribution; another extension that wants to cooperate with it needs only
  to call `next::method` in its own `_introspect_class`.

## Open for the maintainer

- Which registration order is the documented one (AGE first, PostGIS first) once
  PostGIS chains as well. With both cooperative the result is the same model
  either way; the order then only decides which `install` runs first.

## Rejected alternatives

- **A constant composite introspector in this repo that knows PostGIS.** Couples
  AGE to PostGIS and does not generalise to a third extension.
- **Changing `@ISA` of the storage layers or components to force an order.**
  An architecture change, not a fix (house rule on composition seams).
