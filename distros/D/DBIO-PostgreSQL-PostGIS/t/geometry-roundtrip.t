use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Geometry;
my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';

# from_wkt → to_wkt round-trip
my $g = $G->from_wkt('POLYGON((0 0,10 0,10 10,0 10,0 0))', srid => 4326);
is $g->to_wkt, 'POLYGON((0 0,10 0,10 10,0 10,0 0))', 'to_wkt round-trip';
is $g->srid,   4326,                                   'srid preserved';

# POINT Z
my $g2 = $G->from_wkt('POINT Z(1 2 3)');
is $g2->geometry_type, 'point', 'POINT Z type';
is $g2->to_wkt,        'POINT Z(1 2 3)', 'POINT Z round-trip';

# from_ewkb_hex now actually decodes
use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
my $hex = unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 5.0, 6.0));
my $g3  = $G->from_ewkb_hex($hex);
is $g3->geometry_type,  'point', 'from_ewkb_hex type';
is $g3->srid,           4326,    'from_ewkb_hex srid';
is $g3->coordinates->[0], 5.0,  'from_ewkb_hex x';

done_testing;
