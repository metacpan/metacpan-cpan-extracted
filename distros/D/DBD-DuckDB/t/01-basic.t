#perl -T

use strict;
use warnings;

use Test::More;
use DBI ':sql_types';

my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:');

ok($dbh->do('CREATE TABLE t (id INTEGER)') == 0, 'do return 0E0 rows changed');

done_testing;
