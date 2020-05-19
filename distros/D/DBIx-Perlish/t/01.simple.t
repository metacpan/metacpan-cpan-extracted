use warnings;
use strict;
use lib '.';
use Test::More;
use DBIx::Perlish;
use t::test_utils;

test_select_sql {
	my $x : table;
} "select * from table",
"select * from table t01",
[];

test_select_sql {
	users->type eq "su",
	users->id == superusers->user_id;
} "simple join",
"select * from users t01, superusers t02 where t01.type = ? and t01.id = t02.user_id",
["su"];

# return
test_select_sql {
	return tbl->name
} "return one",
"select t01.name from tbl t01",
[];
test_select_sql {
	return (tbl->name, tbl->val);
} "return two",
"select t01.name, t01.val from tbl t01",
[];
test_select_sql {
	return (nm => tbl->name);
} "return one, aliased",
"select t01.name as nm from tbl t01",
[];
test_select_sql {
	return (tbl->name, value => tbl->val);
} "return two, second aliased",
"select t01.name, t01.val as value from tbl t01",
[];
test_select_sql {
	my $t : tbl;
	return value => "Value";
} "return constant alias",
"select ? as value from tbl t01",
["Value"];
test_select_sql {
	my $t : tbl;
	return $t, value => "Value";
} "return *, then constant alias",
"select t01.*, ? as value from tbl t01",
["Value"];
test_select_sql {
	my $t : tbl;
	return $t->val, value => "Value";
} "return column, then constant alias",
"select t01.val, ? as value from tbl t01",
["Value"];

# distinct
test_select_sql {
	return distinct => tbl->id
} "simple SELECT DISTINCT",
"select distinct t01.id from tbl t01",
[];

# distinct via a label
test_select_sql {
	DISTINCT: return tbl->id
} "simple SELECT DISTINCT via a label",
"select distinct t01.id from tbl t01",
[];

#  return t.*
test_select_sql {
	my $t1 : table1;
	my $t2 : table2;
	$t1->id == $t2->table1_id;
	return $t1, $t2->name;
} "select t.*",
"select t01.*, t02.name from table1 t01, table2 t02 where t01.id = t02.table1_id",
[];

# verbatim
test_select_sql {
	tab->id == sql "some_seq.nextval";
} "verbatim in select",
"select * from tab t01 where t01.id = some_seq.nextval",
[];
test_update_sql {
	tab->state eq "new";

	tab->id = sql "some_seq.nextval";
} "verbatim in update",
"update tab set id = some_seq.nextval where state = ?",
['new'];
test_select_sql {
	tab->id == `some_seq.nextval`;
} "verbatim `` in select",
"select * from tab t01 where t01.id = some_seq.nextval",
[];
test_update_sql {
	tab->state eq "new";

	tab->id = `some_seq.nextval`;
} "verbatim `` in update",
"update tab set id = some_seq.nextval where state = ?",
['new'];

# string concatenation
test_select_sql {
	return "foo-" . tab->name . "-moo";
} "concatenation in return",
"select (? || t01.name || ?) from tab t01",
["foo-","-moo"];

test_select_sql {
	tab->name . "x" eq "abcx";
	return tab->name;
} "concatenation in filter",
"select t01.name from tab t01 where (t01.name || ?) = ?",
["x","abcx"];

test_select_sql {
	my $t : tab;
	return "foo-$t->name-moo";
} "concatenation with interpolation",
"select (? || t01.name || ?) from tab t01",
["foo-", "-moo"];

test_select_sql {
	my $t : tab;
	return "foo-" . $t->firstname . " $t->lastname-moo";
} "concat, interp+normal",
"select (? || t01.firstname || ? || t01.lastname || ?) from tab t01",
["foo-", " ", "-moo"];

test_select_sql {
	my $t : tab;
	return "foo-$t->firstname $t->lastname-moo";
} "concat, interp x 2",
"select (? || t01.firstname || ? || t01.lastname || ?) from tab t01",
["foo-", " ", "-moo"];

done_testing;
