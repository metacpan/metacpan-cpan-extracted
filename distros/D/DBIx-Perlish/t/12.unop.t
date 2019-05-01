use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# lone [boolean] tests
test_select_sql {
	tbl->boolvar
} "bool test",
"select * from tbl t01 where t01.boolvar",
[];
test_select_sql {
	!tbl->boolvar
} "not bool test",
"select * from tbl t01 where not t01.boolvar",
[];

# not expr
test_select_sql {
	!tbl->id == 5
} "bool test",
"select * from tbl t01 where not t01.id = 5",
[];

# defined
test_select_sql {
	defined(tab->field);
} "defined",
"select * from tab t01 where t01.field is not null",
[];

test_select_sql {
	defined tab->field;
} "defined",
"select * from tab t01 where t01.field is not null",
[];

test_select_sql {
	!defined(tab->field);
} "!defined",
"select * from tab t01 where t01.field is null",
[];

test_select_sql {
	not defined(tab->field);
} "not defined",
"select * from tab t01 where t01.field is null",
[];

# undef comparisons
test_select_sql {
	tab->age == undef;
} "undef cmp, literal, right, equal",
"select * from tab t01 where t01.age is null",
[];

test_select_sql {
	tab->age != undef;
} "undef cmp, literal, right, not equal",
"select * from tab t01 where t01.age is not null",
[];

test_select_sql {
	undef == tab->age;
} "undef cmp, literal, left, equal",
"select * from tab t01 where t01.age is null",
[];

test_select_sql {
	undef != tab->age;
} "undef cmp, literal, left, not equal",
"select * from tab t01 where t01.age is not null",
[];

my $undef = undef;
test_select_sql {
	tab->age == $undef;
} "undef cmp, scalar, right, equal",
"select * from tab t01 where t01.age is null",
[];

test_select_sql {
	tab->age != $undef;
} "undef cmp, scalar, right, not equal",
"select * from tab t01 where t01.age is not null",
[];

test_select_sql {
	$undef == tab->age;
} "undef cmp, scalar, left, equal",
"select * from tab t01 where t01.age is null",
[];

test_select_sql {
	$undef != tab->age;
} "undef cmp, scalar, left, not equal",
"select * from tab t01 where t01.age is not null",
[];

done_testing;
