use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# limit via a label
test_select_sql {
	my $t : tbl;
	limit: 5;
} "simple limit label",
"select * from tbl t01 limit 5",
[];

# offset via a label
test_select_sql {
	my $t : tbl;
	offset: 42;
} "simple offset label",
"select * from tbl t01 offset 42",
[];

# limit & offset via a label (with int vars)
my $lim = 10;  my $ofs = 20;
test_select_sql {
	my $t : tbl;
	limit: $lim;
	offset: $ofs;
} "simple limit/offset label with int vars",
"select * from tbl t01 limit 10 offset 20",
[];

# limit & offset via a label (with string vars)
my $s_lim = '10';  my $s_ofs = '20';
test_select_sql {
	my $t : tbl;
	limit: $s_lim;
	offset: $s_ofs;
} "simple limit/offset label with string vars",
"select * from tbl t01 limit 10 offset 20",
[];

# limit & offset via last unless
test_select_sql {
	my $t : tbl;
	last unless 20..29;
} "limit/offset via last unless",
"select * from tbl t01 limit 10 offset 20",
[];

# limit via last unless
test_select_sql {
	my $t : tbl;
	last unless 0..9;
} "limit via last unless",
"select * from tbl t01 limit 10",
[];

# order by
test_select_sql {
	my $t : tbl;
	order_by: $t->name;
} "simple order by",
"select * from tbl t01 order by t01.name",
[];

# order by desc
test_select_sql {
	my $t : tbl;
	order_by: descending => $t->name;
} "simple order by, descending",
"select * from tbl t01 order by t01.name desc",
[];

done_testing;
