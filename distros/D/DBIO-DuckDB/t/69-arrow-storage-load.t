#!/usr/bin/env perl
# t/69-arrow-storage-load.t -- the storage class loads without the Arrow module.
#
# WHY this matters: DBIO::DuckDB::Arrow binds libduckdb's Arrow functions when
# it is loaded, and fails without the library. If the storage class loaded it,
# every use of the driver (connect, deploy, a plain query) would depend on
# that, though only duckdb_arrow_fetch needs it. A missing library has to be an
# exception of that one method.

use strict;
use warnings;
use Test::More;

my $code = <<'EOC';
use DBIO::DuckDB::Storage;
exit(($INC{'DBIO/DuckDB/Arrow.pm'} ? 10 : 0) + (DBIO::DuckDB::Storage->can('duckdb_arrow_fetch') ? 0 : 20));
EOC

my $rc = system($^X, '-Ilib', '-e', $code) >> 8;
is $rc, 0, 'use DBIO::DuckDB::Storage does not load DBIO::DuckDB::Arrow, and the method is there';

{
  local $ENV{DUCKDB_NO_ALIEN} = 1;
  local $ENV{LD_LIBRARY_PATH} = '/nonexistent-dir';
  my $rc = system($^X, '-Ilib', '-e', $code) >> 8;
  is $rc, 0, 'the storage class loads where libduckdb cannot be found by name';
}

done_testing;
