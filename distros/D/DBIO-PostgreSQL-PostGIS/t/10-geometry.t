use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Geometry;
my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';

subtest point => sub {
  my $p = $G->point(13.4, 52.5, srid => 4326);
  is $p->wkt,           'POINT(13.4 52.5)';
  is $p->ewkt,          'SRID=4326;POINT(13.4 52.5)';
  is $p->geometry_type, 'POINT';
  is $p->srid,          4326;
  is_deeply $p->coordinates, [13.4, 52.5];
  is $p->x, 13.4;
  is $p->y, 52.5;
  ok !$p->is_empty;
};

subtest from_lat_lon => sub {
  my $p = $G->from_lat_lon(52.5, 13.4);
  # lat/lon → POINT(lon lat)
  is_deeply $p->coordinates, [13.4, 52.5];
  is $p->srid, 4326;
};

subtest from_ewkt => sub {
  my $p = $G->from_ewkt('SRID=3857;POINT(1 2)');
  is $p->srid, 3857;
  is $p->wkt,  'POINT(1 2)';
};

subtest linestring => sub {
  my $l = $G->linestring([[0,0],[1,1],[2,0]], srid => 4326);
  is $l->wkt, 'LINESTRING(0 0,1 1,2 0)';
  is_deeply $l->coordinates, [[0,0],[1,1],[2,0]];
  is_deeply $l->bbox, [0, 0, 2, 1];
};

subtest polygon => sub {
  my $poly = $G->polygon(
    [[ [0,0],[10,0],[10,10],[0,10],[0,0] ]],
    srid => 4326,
  );
  is $poly->wkt, 'POLYGON((0 0,10 0,10 10,0 10,0 0))';
  is_deeply $poly->coordinates,
    [[ [0,0],[10,0],[10,10],[0,10],[0,0] ]];
  is_deeply $poly->bbox, [0, 0, 10, 10];
};

subtest bbox_polygon => sub {
  my $b = $G->bbox_polygon(0, 0, 5, 5, srid => 4326);
  is_deeply $b->bbox, [0, 0, 5, 5];
  is $b->geometry_type, 'POLYGON';
};

subtest empty => sub {
  my $e = $G->from_wkt('POINT EMPTY');
  ok $e->is_empty;
};

subtest geojson_roundtrip => sub {
  my $gj = { type => 'Point', coordinates => [10, 20] };
  my $g = $G->from_geojson($gj);
  is $g->wkt, 'POINT(10 20)';
  is $g->srid, 4326;
  is_deeply $g->to_geojson, $gj;
};

subtest geojson_polygon => sub {
  my $gj = {
    type => 'Polygon',
    coordinates => [[ [0,0],[1,0],[1,1],[0,1],[0,0] ]],
  };
  my $g = $G->from_geojson($gj);
  is $g->wkt, 'POLYGON((0 0,1 0,1 1,0 1,0 0))';
  is_deeply $g->to_geojson, $gj;
};

subtest multipolygon_parse => sub {
  my $mp = $G->from_wkt('MULTIPOLYGON(((0 0,1 0,1 1,0 1,0 0)),((2 2,3 2,3 3,2 3,2 2)))');
  my $coords = $mp->coordinates;
  is scalar @$coords, 2, 'two polygons';
  is_deeply $coords->[0], [[ [0,0],[1,0],[1,1],[0,1],[0,0] ]];
  is_deeply $mp->bbox, [0, 0, 3, 3];
};

done_testing;
