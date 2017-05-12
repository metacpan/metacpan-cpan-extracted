#!perl -T

# Verify to create object with no dbnames, to list which dbnames exist.
# Verify to create object with dbname and define collection

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Catalyst::Model::MongoDB');
}

my $mongo = new_ok 'Catalyst::Model::MongoDB';

# See if a test database is available. Preferably one called 'test'.
my $testdb;
eval '
  my @dbs = $mongo->dbnames();
  if ( grep /^test$/, @dbs ) {
    ($testdb) = grep /^test$/, @dbs;
  } elsif ( grep /test/i, @dbs ) {
    ($testdb) = grep /test/i, @dbs;
  } else {
    $testdb = shift @dbs;
  }
';

# If there is a database available, make reference to a collection
#
SKIP: {
  skip 'No local database available for testing', 5 unless $testdb;
  my $db = new_ok( 'Catalyst::Model::MongoDB' =>[
    dbname => $testdb,
  ] );
  ok ( $db, "database name" );
  my $coll = $db->collection('test');
  ok ( $coll, "Collection name" );

  $coll = $db->c('test');
  ok ( $coll, "Collection name" );

  $coll = $db->coll('test');
  ok ( $coll, "Collection name" );

};
