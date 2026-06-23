# DBIO::PostgreSQL::PostGIS

PostGIS spatial extension support for DBIO::PostgreSQL.

## Supports

- PostGIS geometry/geography types ([DBIO::PostgreSQL::PostGIS](https://metacpan.org/pod/DBIO::PostgreSQL::PostGIS))
- inflate/deflate via [DBIO::PostgreSQL::PostGIS::Geometry](https://metacpan.org/pod/DBIO::PostgreSQL::PostGIS::Geometry) value objects
- spatial query helpers via [DBIO::PostgreSQL::PostGIS::ResultSet](https://metacpan.org/pod/DBIO::PostgreSQL::PostGIS::ResultSet)
- integration with [DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL) base driver

## Usage

    package MyApp::Schema::Result::Place;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::PostGIS');
    __PACKAGE__->table('place');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'text' },
      geom => {
        data_type     => 'geometry',
        geometry_type => 'POINT',
        srid          => 4326,
      },
    );

    # Inflated reads - returns DBIO::PostgreSQL::PostGIS::Geometry
    my $place = $schema->resultset('Place')->find(1);
    $place->geom->x;        # longitude
    $place->geom->y;        # latitude
    $place->geom->wkt;      # 'POINT(13.4 52.5)'

    # Deflated writes - pass a Geometry object
    $place->geom(
      DBIO::PostgreSQL::PostGIS::Geometry->point(13.4, 52.5, srid => 4326),
    );
    $place->update;

DBIO core autodetects `dbi:Pg:` DSNs and [DBIO::PostgreSQL::PostGIS](https://metacpan.org/pod/DBIO::PostgreSQL::PostGIS)
is loaded via C<load_components> on Result classes.

## PostGIS Features

**Geometry Types**
- `POINT`, `LINESTRING`, `POLYGON`
- `MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON`
- `GEOMETRYCOLLECTION`

**Coordinates & SRID**
- X/Y (and optional Z) coordinate accessors
- SRID support (defaults to 4326 WGS84)
- EWKT (SRID=4326;POINT(...)) serialization

**Spatial Queries (ResultSet helpers)**
- `within_distance(geom => $geometry, $meters)` - find rows within radius
- `nearest_to(geom => $geometry)` - KNN ordering by distance

**Geometry Construction**
- `DBIO::PostgreSQL::PostGIS::Geometry->point($x, $y, srid => 4326)`
- `->linestring([[0,0],[1,1]], srid => 4326)`
- `->polygon([[ [$xmin,$ymin], ... ]], srid => 4326)`
- `->bbox_polygon($xmin, $ymin, $xmax, $ymax, srid => 4326)`
- `->from_wkt($wkt, srid => 4326)`
- `->from_ewkb_hex($hex)`
- `->from_geojson(\%geojson, srid => 4326)`
- `->from_lat_lon($lat, $lon)` - convenience (swaps order for WKT)

**Geometry Methods**
- `->srid`, `->geometry_type`, `->wkt`, `->ewkt`, `->ewkb_hex`
- `->x`, `->y`, `->z` (POINT only)
- `->coordinates` - nested array ref
- `->is_empty` - true for EMPTY geometries
- `->bbox` - [xmin, ymin, xmax, ymax]
- `->to_geojson` - GeoJSON hashref

**Integration**
- Raw spatial SQL via C<-bool> literal for advanced queries
- ST_DWithin, ST_Contains, ST_Intersects, etc. via raw SQL

## Testing

Requires a running PostgreSQL instance with PostGIS extension:

```bash
export DBIO_TEST_PG_DSN="dbi:Pg:database=myapp"
export DBIO_TEST_PG_USER=postgres
export DBIO_TEST_PG_PASS=secret
prove -l t/
```

The live test (C<t/30-spatial-live.t>) creates an actual geometry table
and runs spatial queries. Skips if no PostGIS extension is available.

## Requirements

- Perl 5.36+
- [DBD::Pg](https://metacpan.org/pod/DBD::Pg)
- PostGIS extension
- DBIO core
- [DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL) base driver

## See Also

[DBIO::PostgreSQL](https://metacpan.org/pod/DBIO::PostgreSQL), [DBIO::PostgreSQL::PostGIS::Geometry](https://metacpan.org/pod/DBIO::PostgreSQL::PostGIS::Geometry),
[PostGIS](https://postgis.net/)

## Repository

[https://codeberg.org/dbio/dbio-postgresql-postgis](https://codeberg.org/dbio/dbio-postgresql-postgis)