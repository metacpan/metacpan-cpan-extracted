# ADR 0003 — Lightweight lazy Geometry value object as the inflation target, incl. lat/lon axis-swap

- Status: accepted
- Date: 2026-06-23
- Tags: postgis, geometry, value-object, inflate, lazy, srid, axis-order, backfill

## Context

Geometry and geography columns inflate to *some* Perl object. The two candidates
are a `Geo::OGR::Geometry` (full GDAL geometry, heavy, requires the binding on
every read) or a purpose-built lightweight value object. Whatever the target,
its constructors and accessors become the public spatial API users touch, so its
ergonomics — coordinate access, SRID handling, and the longitude/latitude axis
trap that bites every geospatial API — are an architectural decision, not an
implementation detail.

PostGIS/WKT axis order is `POINT(lon lat)`; humans almost always say "lat, lon".
A geospatial value object that silently follows one convention without naming it
is a defect generator.

## Decision

Inflate to a **bespoke lightweight value object**,
`DBIO::PostgreSQL::PostGIS::Geometry`, that stores SRID plus a wire form (WKT or
EWKB-hex) and parses **lazily** on demand.

- **Lightweight store, lazy parse.** `new` stores
  `srid`/`wkt`/`ewkb_hex`/`geometry_type`/`coordinates` as a plain blessed hash
  (`Geometry.pm:48-58`). `geometry_type`, `wkt`, `coordinates`, `bbox`,
  `to_geojson` derive their values on first access via the codec chain and
  memoise (`Geometry.pm:269-331`), so a row that is fetched but whose geometry is
  never inspected pays no parsing cost.
- **Constructors cover the common shapes.** `from_wkt`, `from_ewkt`,
  `from_ewkb_hex`, `point`, `linestring`, `polygon`, `bbox_polygon`,
  `from_geojson`, `from_lat_lon` (`Geometry.pm:60-252`).
- **Explicit lat/lon axis-swap convention.** `from_lat_lon($lat, $lon)` takes the
  human order (lat first) and deliberately swaps to PostGIS
  `POINT(lon lat)` order, defaulting SRID to 4326 (`Geometry.pm:149-152`). The
  swap is documented at the method, not implicit. `from_geojson` likewise
  defaults SRID to 4326 per the GeoJSON spec unless overridden
  (`Geometry.pm:215-217`).
- **`Geo::OGR` only on demand.** `to_ogr` is the single bridge to the heavy
  library and `require`s it lazily (`Geometry.pm:416-420`); it is never on the
  inflation path. (The codec/dependency decision is ADR 0002.)

## Rationale

Most spatial reads want the SRID and a few coordinates, not a full GDAL geometry,
so a lightweight object that lazily parses is the cheaper default for the common
case while `to_ogr` keeps the heavy path one call away. Storing the wire form and
parsing lazily means a `SELECT … geom …` that never touches `->x`/`->coordinates`
does zero codec work — relevant because inflation runs per row. The axis-swap
convention is the load-bearing ergonomic decision: `from_lat_lon` exists
precisely so callers can use the human "lat, lon" order without silently
producing a point at the wrong place, and naming the swap at the method (rather
than hiding it) is what makes the convention safe. Defaulting SRID 4326 in two
constructors matches the de-facto standard for GPS/GeoJSON data and removes the
most common boilerplate.

The object is the inflation target exercised end-to-end (`t/10-geometry.t`,
`t/20-inflate.t`, `t/geometry-roundtrip.t`), hence **accepted**.

## Consequences

- Inflation produces a `DBIO::PostgreSQL::PostGIS::Geometry`, not a
  `Geo::OGR::Geometry`; code wanting GDAL must call `->to_ogr` and have the
  binding installed.
- `coordinates`/`x`/`y`/`z`/`bbox`/`to_geojson` are defined for the simple
  geometry types parseable from WKT; the value object returns `undef` for shapes
  too complex to parse from WKT alone, and the documented escape is `to_ogr`.
- `from_lat_lon` is the *only* constructor that swaps axis order; every other
  constructor (`point`, `from_wkt`, …) takes coordinates in native
  `lon`/`x`-first order. Mixing them up is the one footgun, which is why the swap
  is documented at the call site.
- New geometry-type support is added by extending the codecs and this object's
  constructors/accessors together; the lazy-parse contract (store wire form,
  derive on demand) must be preserved.
