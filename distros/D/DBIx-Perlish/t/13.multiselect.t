use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# subselects
test_select_sql {
	tbl->id  <-  subselect { return t2->some_id };
} "simple IN subselect",
"select * from tbl t01 where t01.id in (select s01_t01.some_id from t2 s01_t01)",
[];
test_select_sql {
	!tbl->id  <-  subselect { return t2->some_id };
} "simple NOT IN subselect",
"select * from tbl t01 where t01.id not in (select s01_t01.some_id from t2 s01_t01)",
[];

test_select_sql {
	my $t : tbl;
	subselect { $t->id == t2->some_id };
} "simple EXISTS subselect",
"select * from tbl t01 where exists (select * from t2 s01_t01 where t01.id = s01_t01.some_id)",
[];
test_select_sql {
	my $t : tbl;
	!subselect { $t->id == t2->some_id };
} "simple NOT EXISTS subselect",
"select * from tbl t01 where not exists (select * from t2 s01_t01 where t01.id = s01_t01.some_id)",
[];

# expression return
test_select_sql {
	return tab->n1 - tab->n2
} "expression return 1",
"select (t01.n1 - t01.n2) from tab t01",
[];
test_select_sql {
	{ return t1->name } union { return t2->name }
} "simple union",
"select t01.name from t1 t01 union select t01.name from t2 t01",
[];

my @uids = (1,2,3);
test_select_sql {
	{
		my $t : tab1;
		$t->id <- @uids;
	} union {
		my $t : tab2;
		my $tt : tab2;
		$t->id == $tt->id;
		$t->id <- @uids;
	}
} "union bugfix",
"select * from tab1 t01 where t01.id in (?,?,?) union select * from tab2 t01, tab2 t02 where t01.id = t02.id and t01.id in (?,?,?)",
[1,2,3,1,2,3];

my $hr1 = { x => 'y' };
my %h1 = ( y => 'z' );
test_select_sql {
	{
		my $t : tab1;
		$t->id <- @uids;
	} union {
		my $t : tab2;
		my $tt : tab2;
		$t->id == $tt->id;
		$t->id <- @uids;
		$t->x == $hr1->{x};
		$t->y == $h1{y};
	}
} "union bugfix2",
"select * from tab1 t01 where t01.id in (?,?,?) union ".
"select * from tab2 t01, tab2 t02 where t01.id = t02.id and t01.id in (?,?,?) ".
"and t01.x = ? and t01.y = ?",
[1,2,3,1,2,3,"y","z"];

test_select_sql {
	{ return t1->name } intersect { return t2->name }
} "simple intersect",
"select t01.name from t1 t01 intersect select t01.name from t2 t01",
[];

test_select_sql {
	{ return t1->name } except { return t2->name }
} "simple except",
"select t01.name from t1 t01 except select t01.name from t2 t01",
[];

# multi-union
test_select_sql {
	{ return t1->name } union { return t2->name } union { return t3->name }
} "multi-union",
"select t01.name from t1 t01 union select t01.name from t2 t01 union select t01.name from t3 t01",
[];

test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 * $t2 => subselect { my $t3 : t3 }
} "bad join 10", qr/anything but conditional/;
test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 * $t2 => subselect { return $t1->x }
} "bad join 11", qr/anything but conditional/;
test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 * $t2 => subselect { group_by: $t1->name }
} "bad join 12", qr/anything but conditional/;
test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 * $t2 => subselect { order: $t1->name }
} "bad join 13", qr/anything but conditional/;
test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 + $t2 => subselect { }
} "bad join 14", qr/at least one conditional/;
test_bad_select { my $t1 : t1; my $t2 : t2;
	join $t1 * $t2 <= subselect {}, 42;
} "bad join 15", qr/not a valid join/;

test_bad_select {
	{ return t1->name } union { return t2->name } subselect { return t3->name }
} "multi-union gone bad", qr/missing semicolon after union/;

test_bad_select {
	my $t : t1;
	$t->id  <-  subselect { my $tt : t2 };
} "subselect returns too much 1", qr/subselect query sub must return exactly one value/;
test_bad_select {
	my $t : t1;
	$t->id  <-  subselect {
		my $t2 : t2; my $t3 : t3;
		$t2->id == $t3->id;
		return $t2;
	};
} "subselect returns too much 2", qr/subselect query sub must return exactly one value/;


done_testing;
