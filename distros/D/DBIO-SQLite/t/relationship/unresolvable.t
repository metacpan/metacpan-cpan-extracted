use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

my $cd = $schema->resultset('CD')->search ({}, { columns => ['year'], rows => 1 })->single;


throws_ok (
  sub { $cd->tracks },
  qr/Unable to resolve relationship .+ column .+ not loaded from storage/,
  'Correct exception on nonresolvable object-based condition'
);

done_testing;
