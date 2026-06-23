use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::ResultSet;

# All 6 simple predicates must exist as methods
for my $name (qw(intersects contains within touches crosses overlaps)) {
  ok(DBIO::PostgreSQL::PostGIS::ResultSet->can($name),
    "$name method exists");
}

# within_distance also exists (separate, takes $dist)
ok(DBIO::PostgreSQL::PostGIS::ResultSet->can('within_distance'),
  'within_distance method exists');

# Custom methods exist
for my $name (qw(bbox_intersects nearest_to order_by_distance with_distance)) {
  ok(DBIO::PostgreSQL::PostGIS::ResultSet->can($name),
    "$name method exists");
}

done_testing;
