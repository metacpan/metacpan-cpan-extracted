#perl -T

use strict;
use warnings;
use Test::More;
use lib "t/lib";

use_ok('DBI');
use_ok('DBD::DuckDB');

my $lib_version = DBD::DuckDB::db->x_duckdb_version();

diag("DBD::DuckDB $DBD::DuckDB::VERSION (libduckdb $lib_version, DBI $DBI::VERSION), Perl $], $^X");

done_testing;
