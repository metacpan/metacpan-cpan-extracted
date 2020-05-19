use warnings;
use strict;
use lib '.';
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# mysql string concatentation really is different
$main::flavor = "mysql";
test_select_sql {
	return "foo-" . tab->name . "-moo";
} "mysql: concatenation in return",
"select (concat(?, t01.name, ?)) from tab t01",
["foo-","-moo"];

test_select_sql {
	tab->name . "x" eq "abcx";
	return tab->name;
} "mysql: concatenation in filter",
"select t01.name from tab t01 where (concat(t01.name, ?)) = ?",
["x","abcx"];

test_select_sql {
	my $t : tab;
	return "foo-$t->name-moo";
} "mysql: concatenation with interpolation",
"select (concat(?, t01.name, ?)) from tab t01",
["foo-", "-moo"];

test_select_sql {
	my $t : tab;
	return "foo-" . $t->firstname . " $t->lastname-moo";
} "mysql: concat, interp+normal",
"select (concat(?, t01.firstname, ?, t01.lastname, ?)) from tab t01",
["foo-", " ", "-moo"];

test_select_sql {
	my $t : tab;
	return "foo-$t->firstname $t->lastname-moo";
} "mysql: concat, interp x 2",
"select (concat(?, t01.firstname, ?, t01.lastname, ?)) from tab t01",
["foo-", " ", "-moo"];

if ( DBIx::Perlish->optree_version == 1 ) {
	test_select_sql {
	       my $t : tab;
	       return "abc$t->{name}xyz";
	} "mysql: concat, interp, hash syntax",
	"select (concat(?, t01.name, ?)) from tab t01",
	["abc", "xyz"];
} else {
	test_bad_select {
		my $t : tab;
		return "abc$t->{name}xyz";
	} "mysql: concat, interp, hash syntax", qr/not supported anymore/;
}

done_testing;
