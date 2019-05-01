use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# order by desc
my $order_by = 'desc';
my $order_col = 'name';
test_select_sql {
	my $t : tbl;
	order_by: $order_by, $t->name;
	return $t;
} "inline order by, custom order",
"select t01.* from tbl t01 order by t01.name desc",
[];

test_select_sql {
	my $t : tbl;
	order_by: $order_by, $order_col;
} "inline order by, both custom",
"select * from tbl t01 order by name desc",
[];

# order by several
test_select_sql {
	my $t : tbl;
	order_by: asc => $t->name, desc => $t->age;
} "order by several",
"select * from tbl t01 order by t01.name, t01.age desc",
[];

# sort
test_select_sql {
	my $t : tbl;
	sort $t->name;
} "simple sort",
"select * from tbl t01 order by t01.name",
[];

# sort desc
test_select_sql {
	my $t : tbl;
	sort descending => $t->name;
} "simple sort, descending",
"select * from tbl t01 order by t01.name desc",
[];

# sort several
test_select_sql {
	my $t : tbl;
	sort asc => $t->name, desc => $t->age;
} "sort several",
"select * from tbl t01 order by t01.name, t01.age desc",
[];

# group by
test_select_sql {
	my $t : tbl;
	group_by: $t->type;
} "simple order by",
"select * from tbl t01 group by t01.type",
[];

done_testing;
