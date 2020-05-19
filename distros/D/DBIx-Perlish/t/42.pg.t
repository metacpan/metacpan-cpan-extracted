use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

my $someid = 42;
$main::flavor = "pg";
test_select_sql {
	tbl->id  <- tablefunc($someid);
} "Pg: tablefunc IN subselect",
"select * from tbl t01 where t01.id in (select tablefunc(?))",
[42];
test_select_sql {
	!tbl->id  <- tablefunc($someid);
} "Pg: tablefunc NOT IN subselect",
"select * from tbl t01 where t01.id not in (select tablefunc(?))",
[42];
test_select_sql {
	my $p : table = tablefunc($someid);
	return $p;
} "Pg: tableop",
"select t01.* from tablefunc(?) t01",
[42];

my $two = 2;
test_select_sql { return $two**5 } "supported exponent",
"select (pow(?, 5))", [2];

done_testing;
