use warnings;
use strict;
use Test::More tests => 3*4;
use DBIx::Perlish;
use t::test_utils;

for my $name (qw(a b c d)) {
	test_select_sql {
		tbl->name eq $name
	} "closure comparison, $name",
	"select * from tbl t01 where t01.name = ?",
	[$name];
}
