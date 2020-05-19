use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# logical ops
test_select_sql {
	my $a : tab;
	$a->x == 1 && $a->y == 2;
} "explicit simple AND",
"select * from tab t01 where (t01.x = 1) and (t01.y = 2)",
[];
test_select_sql {
	my $a : tab;
	$a->x == 1 || $a->y == 2;
} "explicit simple OR",
"select * from tab t01 where ((t01.x = 1) or (t01.y = 2))",
[];
test_select_sql {
	my $a : tab;
	$a->x =~ /abc/ || $a->y =~ /cde/;
} "explicit OR with RE",
"select * from tab t01 where (t01.x like '%abc%' or t01.y like '%cde%')",
[];
test_select_sql {
	my $a : tab;
	$a->x == 1 && $a->y == 2
	or
	$a->x == 3 && $a->y == 4
} "explicit ANDs inside OR",
"select * from tab t01 where (((t01.x = 1) and (t01.y = 2)) or ((t01.x = 3) and (t01.y = 4)))",
[];
test_select_sql {
	my $a : tab;
	$a->x == 1 || $a->y == 2
	and
	$a->x == 3 || $a->y == 4
} "explicit ORs inside AND",
"select * from tab t01 where ((t01.x = 1) or (t01.y = 2)) and ((t01.x = 3) or (t01.y = 4))",
[];
test_select_sql {
	my $a : tab;
	$a->x == 1 || $a->y == 2;
	$a->z == 3;
} "explicit simple OR, implicit AND",
"select * from tab t01 where ((t01.x = 1) or (t01.y = 2)) and t01.z = 3",
[];

done_testing;
