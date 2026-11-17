use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::Test::Conformance;

# One subtest per area of the shared case table (core ADR 0060)
for my $area (qw(DDL Diff Bind)) {
  subtest $area => sub {
    DBIO::SQLite::Test::Conformance->run($area);
  };
}

done_testing;
