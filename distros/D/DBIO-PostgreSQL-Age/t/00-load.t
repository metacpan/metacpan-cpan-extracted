use strict;
use warnings;
use Test::More;

use_ok 'DBIO::PostgreSQL::Age';
use_ok 'DBIO::PostgreSQL::Age::Storage';

# The future_io async adapter needs the PostgreSQL future_io transport (and its
# DBD::Pg/Future/Future::IO chain); load it only when those are available so a
# minimal environment still passes the core load test.
SKIP: {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or skip 'future_io prerequisites (DBD::Pg/Future/Future::IO) not available', 1;
  use_ok 'DBIO::PostgreSQL::Age::Storage::Async';
}

done_testing;
