use warnings;
use strict;
use DBIx::Perlish qw/:all/;
use Test::More;
use t::test_utils;

# key fields
test_select_sql {
	my $a : tab;
	return -k $a->id, $a;
} "one simple key field, rest *",
"select t01.id as \"\$kf-1\", t01.* from tab t01",
[], ['$kf-1'];
test_select_sql {
	my $a : tab;
	return -k $a->id, $a->id;
} "one simple key field plus the same field",
"select t01.id as \"\$kf-1\", t01.id from tab t01",
[], ['$kf-1'];
test_select_sql {
	my $a : tab;
	return -k $a->id, -k $a->name, $a;
} "two simple key fields, rest *",
"select t01.id as \"\$kf-1\", t01.name as \"\$kf-2\", t01.* from tab t01",
[], ['$kf-1','$kf-2'];
test_select_sql {
	my $a : tab;
	return -k $a->id, $a, -k $a->name;
} "two simple key fields, rest *, different ordering",
"select t01.id as \"\$kf-1\", t01.*, t01.name as \"\$kf-2\" from tab t01",
[], ['$kf-1','$kf-2'];
test_select_sql {
	my $a : tab;
	return -k $a->id, -k $a->name, $a->x;
} "two simple key field plus some other field",
"select t01.id as \"\$kf-1\", t01.name as \"\$kf-2\", t01.x from tab t01",
[], ['$kf-1','$kf-2'];

test_bad_select {
	my $t : tab;
	return -k $t->f1;
} "only key fields 1", qr/all returns are key fields/;
test_bad_select {
	my $t : tab;
	return -k $t->id, -k $t->name;
} "only key fields 2", qr/all returns are key fields/;
test_bad_select {
	my $t : tab;
	return blah => -k $t->id, $t;
} "aliased key field", qr/a key field cannot be aliased/;
test_bad_select {
	my $t : tab;
	return -k $t;
} "* key field", qr/only a single value return specification can be a key field/;
test_bad_select {
	my $t : tab;
	return -k "heps";
} "constant key field", qr/only a single value return specification can be a key field/;


done_testing;
