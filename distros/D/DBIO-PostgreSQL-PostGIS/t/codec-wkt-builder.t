use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;
my $b = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder';

is $b->build({ type => 'point',      coords => [13.4, 52.5] }),
   'POINT(13.4 52.5)',  'POINT build';

is $b->build({ type => 'point',      coords => [13.4, 52.5, 10], has_z => 1 }),
   'POINT Z(13.4 52.5 10)', 'POINT Z build';

is $b->build({ type => 'linestring', coords => [[0,0],[1,1],[2,2]] }),
   'LINESTRING(0 0,1 1,2 2)', 'LINESTRING build';

is $b->build({ type => 'polygon',    coords => [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }),
   'POLYGON((0 0,10 0,10 10,0 10,0 0))', 'POLYGON build';

is $b->build({ type => 'point', is_empty => 1 }),
   'POINT EMPTY', 'EMPTY build';

# Round-trip with Parser
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
my $wkt = 'POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,2 1,2 2,1 2,1 1))';
my $parsed  = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);
my $rebuilt = $b->build($parsed);
is $rebuilt, $wkt, 'round-trip POLYGON with hole';

done_testing;
