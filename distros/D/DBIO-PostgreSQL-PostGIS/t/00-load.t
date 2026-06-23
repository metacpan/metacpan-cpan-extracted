use strict;
use warnings;
use Test::More;

use_ok 'DBIO::PostgreSQL::PostGIS';
use_ok 'DBIO::PostgreSQL::PostGIS::Storage';
use_ok 'DBIO::PostgreSQL::PostGIS::Geometry';
use_ok 'DBIO::PostgreSQL::PostGIS::ResultSet';
use_ok 'DBIO::PostgreSQL::PostGIS::Introspect';
use_ok 'DBIO::PostgreSQL::PostGIS::Deploy';

done_testing;
