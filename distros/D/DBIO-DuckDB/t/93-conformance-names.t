use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::DuckDB; 1 }
    or plan skip_all => 'DBD::DuckDB required';
}

use DBIO::DuckDB::Test::Conformance;

DBIO::DuckDB::Test::Conformance->run('Names');

done_testing;
