use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::Test::Conformance;

DBIO::SQLite::Test::Conformance->run('DDL');

done_testing;
