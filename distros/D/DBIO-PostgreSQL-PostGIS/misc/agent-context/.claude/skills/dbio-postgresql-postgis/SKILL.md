---
name: dbio-postgresql-postgis
description: Use when working with PostGIS spatial data in DBIO — geometry and geography columns, Geometry objects, EWKT/EWKB, spatial resultset helpers.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

PostGIS spatial support for `DBIO::PostgreSQL`. A result-class **component** that
inflates `geometry`/`geography` columns to `Geometry` objects and mixes spatial
query helpers into the resultset. Builds on [[dbio-postgresql]]; conventions →
[[dbio-perl-syntax]].

## Result class — declare a spatial column

```perl
package MyApp::Schema::Result::Place;
use base 'DBIO::Core';
__PACKAGE__->load_components('PostgreSQL::PostGIS');   # inflation + resultset helpers
__PACKAGE__->table('place');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'text' },
  geom => {
    data_type     => 'geometry',   # or 'geography'
    geometry_type => 'POINT',
    srid          => 4326,
  },
);
```

`geometry`/`geography` columns auto-inflate on read and deflate on write: a
Geometry read from the database goes back as the EWKB hex it carries (same type,
same Z/M, same doubles bit for bit), one built in Perl as EWKT.

## Geometry objects

Read returns a `DBIO::PostgreSQL::PostGIS::Geometry`:

```perl
my $place = $schema->resultset('Place')->find(1);
$place->geom->x;              # longitude
$place->geom->y;              # latitude
$place->geom->srid;
$place->geom->geometry_type;  # 'point' (lower-case when decoded from EWKB/WKT)
$place->geom->wkt / ->ewkt / ->ewkb_hex;
```

Only `NULL` reads as `undef`. A type the EWKB decoder names but does not decode
— `CIRCULARSTRING`, `COMPOUNDCURVE`, `CURVEPOLYGON`, `MULTICURVE`,
`MULTISURFACE`, `POLYHEDRALSURFACE`, `TIN`, `TRIANGLE`, or a
`GEOMETRYCOLLECTION` holding one — reads as an object with `ewkb_hex`, `srid`
and `geometry_type` (`circularstring`, …) and no coordinates: `coordinates`,
`wkt`, `ewkt`, `bbox`, `to_geojson` are `undef`. It is written back as its hex.

Constructors (deflate to EWKT on `update` — except `from_ewkb_hex`, whose
objects deflate to that hex):

```perl
DBIO::PostgreSQL::PostGIS::Geometry->point($lon, $lat, srid => 4326);
DBIO::PostgreSQL::PostGIS::Geometry->from_lat_lon($lat, $lon, srid => 4326);
DBIO::PostgreSQL::PostGIS::Geometry->from_wkt($wkt);
DBIO::PostgreSQL::PostGIS::Geometry->from_ewkt($ewkt);
DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($hex);
DBIO::PostgreSQL::PostGIS::Geometry->from_geojson($json);
->linestring(...) / ->polygon(...) / ->bbox_polygon(...)
```

## Spatial resultset helpers

Mixed in via `DBIO::PostgreSQL::PostGIS::ResultSet`:

| Method | Purpose |
|---|---|
| `within_distance($col, $geom, $meters)` | `ST_DWithin` filter |
| `bbox_intersects($col, $geom)` | bounding-box `&&` |
| `nearest_to($col, $geom)` | KNN order, nearest first |
| `order_by_distance($col, $geom)` | order by distance |
| `with_distance($col, $geom)` | add a computed distance column |

Raw spatial SQL is always available via a `-bool` literal:

```perl
$rs->search({ -bool => \['ST_DWithin(geom, ST_MakePoint(?,?)::geography, ?)',
                         $lon, $lat, $meters] });
```

## Driver wiring

PostGIS is a database extension; the schema declares it in its list of extensions
(ADR 0066), not by loading the component:

```perl
package MyApp::Schema;
use DBIO Schema => -pg;
__PACKAGE__->pg_extensions('postgis');                      # or
__PACKAGE__->pg_extensions(postgis => { schema => 'gis' });
```

The driver resolves the name to `DBIO::PostgreSQL::PostGIS::Extension`: model rules
(geometry type and SRID of a column; another SRID is converted with `ST_Transform`,
another type is refused), the storage layer and the inflation component. The layer
composes over the resolved driver storage, so the connected storage `isa` BOTH
`DBIO::PostgreSQL::PostGIS::Storage` AND `DBIO::PostgreSQL::Storage`;
`ensure_postgis` / `postgis_version` live on the layer. Deploy stays with the driver —
this distribution defines no `dbio_deploy_class`.

- `DBIO::PostgreSQL::PostGIS::Storage` is a plain storage **layer** — not a
  `storage_type` subclass, no `use base`, no `register_driver`. The extension never
  determines the driver.
- `postgis_topology` is its own extension (`Topology::Extension`).
- Codecs: `Codec::WKB::Decoder`, `Codec::WKT::Parser`, `Codec::WKT::Builder`
- `::Deploy` and `::Introspect` are stubs.

## Testing

Offline: `../dbio/maint/capped-test prove -lr t/` (mock storage, no database).
Live needs a PostGIS-enabled PostgreSQL (this repo's database is `dbio_postgis`):
`DBIO_TEST_PG_DSN` / `_USER` / `_PASS`. Bring-up and run rules: house rules, *Live
testing — resource discipline*.
