use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# special handling of sysdate
test_select_sql {
	tab->foo == sysdate();
} "sysdate() is not special",
"select * from tab t01 where t01.foo = sysdate()",
[];

test_select_sql {
	return diff => abs(tab->n1 - tab->n2)
} "expression return 2",
"select abs((t01.n1 - t01.n2)) as diff from tab t01",
[];

# autogrouping
test_select_sql {
	my $t : tab;
	return $t->name, $t->type, count($t->age);
} "autogrouping",
"select t01.name, t01.type, count(t01.age) from tab t01 group by t01.name, t01.type",
[];

test_select_sql {
	my $t : tab;
	return $t->name, $t->type, cnt($t->age);
} "no autogrouping - not an aggregate",
"select t01.name, t01.type, cnt(t01.age) from tab t01",
[];

test_select_sql {
	my $t : tab;
	return $t, count($t->age);
} "no autogrouping - table reference",
"select t01.*, count(t01.age) from tab t01",
[];

test_select_sql {
	my $t : tab;
	return count($t->age);
} "no autogrouping - aggregate only",
"select count(t01.age) from tab t01",
[];

test_select_sql {
	my $t : tab;
	return $t->name, count($t->age);
	group_by: $t->name, $t->type;
} "no autogrouping - explicit group by",
"select t01.name, count(t01.age) from tab t01 group by t01.name, t01.type",
[];

# extract quirk
test_select_sql {
	my $a : tab;
	return extract(day => $a->dfield);
} "simple extract",
"select extract(day from t01.dfield) from tab t01",
[];
my $mm = "month";
test_select_sql {
	my $a : tab;
	return extract($mm => $a->dfield);
} "simple extract, extract expression in a var",
"select extract(month from t01.dfield) from tab t01",
[];
test_select_sql {
	my $a : tab;
	return extract();
} "extract as a normal function, no arguments",
"select extract() from tab t01",
[];
test_select_sql {
	my $a : tab;
	return extract("day");
} "extract as a normal function, one argument",
"select extract(?) from tab t01",
["day"];
test_select_sql {
	my $a : tab;
	return extract("day",1,2);
} "extract as a normal function, three arguments",
"select extract(?, 1, 2) from tab t01",
["day"];
test_select_sql {
	my $a : tab;
	return extract($a->f1,$a->f2);
} "extract as a normal function, two arguments, tricky",
"select extract(t01.f1, t01.f2) from tab t01",
[];

# cast
test_select_sql {
	my $a : tab;
	cast($a->x, 'text') == 'foo';
	return cast($a->y, 'integer');
} "cast",
"select cast(t01.y as integer) from tab t01 where cast(t01.x as text) = ?",
['foo'];

# having
test_select_sql {
	my $w : weather;
	max($w->temp_lo) < 40;
	return $w->city;
} "simple having",
"select t01.city from weather t01 group by t01.city having max(t01.temp_lo) < 40",
[];


done_testing;
