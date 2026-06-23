---
name: dbio-postgresql-postgis
description: "DBIO::PostgreSQL::PostGIS — spatial (geometry/geography) column support for DBIO::PostgreSQL: inflation to Geometry objects, EWKT/EWKB codecs, spatial resultset helpers. Use when working with PostGIS spatial data in DBIO."
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
__PACKAGE__->load_components('PostgreSQL::PostGIS');   # the component
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

`geometry`/`geography` columns auto-inflate on read and deflate to EWKT on write.

## Geometry objects

Read returns a `DBIO::PostgreSQL::PostGIS::Geometry`:

```perl
my $place = $schema->resultset('Place')->find(1);
$place->geom->x;              # longitude
$place->geom->y;              # latitude
$place->geom->srid;
$place->geom->geometry_type;  # 'POINT'
$place->geom->wkt / ->ewkt / ->ewkb_hex;
```

Constructors (deflate to EWKT on `update`):

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

```perl
package MyApp::Schema;
use base 'DBIO::PostgreSQL::PostGIS';   # sets storage_type +DBIO::PostgreSQL::PostGIS::Storage
```

- `DBIO::PostgreSQL::PostGIS::Storage` → `register_driver('Pg')`
- Codecs: `Codec::WKB::Decoder`, `Codec::WKT::Parser`, `Codec::WKT::Builder`
- `Introspect` + `Deploy` for spatial-aware schema management

## Testing

Needs a real PostGIS-enabled PostgreSQL (not the core fake storage):
`DBIO_TEST_PG_DSN` / `_USER` / `_PASS` against a DB with the `postgis` extension.
