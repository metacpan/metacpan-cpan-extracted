use warnings;
use strict;
use lib '.';
use Test::More;
use DBIx::Perlish qw/:all/;
use t::test_utils;

our $testour;
my $testmy;
my $val = 42;

test_bad_select {} "empty select", qr/no tables specified in select/;
# this is not empty:

$main::flavor = "foobar";
my $two = 2;
test_bad_select { return $two**5 } "unsupported exponent",
qr/exponentiation is not supported/;
$main::flavor = "";

test_bad_update {} "empty update", qr/no tables specified in update/;
test_bad_delete {} "empty delete", qr/no tables specified in delete/;

test_bad_update { tbl->id = 42 } "unfiltered update", qr/unfiltered update is dangerous/;
test_bad_delete { my $t : tbl } "unfiltered delete", qr/unfiltered delete is dangerous/;

test_bad_update { tbl->id == 42 } "nothing to update", qr/nothing to update/;

test_bad_select {
	table: 1;
} "table label1", qr/label .*? must be followed by an assignment/;
test_bad_select {
	table: $testmy = 1;
} "table label2", qr/label .*? must be followed by a lexical variable declaration/;

test_bad_select {
	limit: "hello";
} "limit label1", qr/label .*? must be followed by an integer/;
test_bad_select {
	my $t : tab;
	limit: $t;
} "limit label2", qr/cannot use table variable after/;

test_bad_select {
	offset: "hello";
} "offset label1", qr/label .*? must be followed by an integer/;
test_bad_select {
	my $t : tab;
	offset: $t;
} "offset label2", qr/cannot use table variable after/;

test_bad_select {
	label: "blah";
} "bad label1", qr/label .*? is not understood/;

test_bad_select {
	last unless $testmy;
} "bad range1", qr/range operator expected/;

test_bad_update {
	last;
} "last in update", qr/there should be no "last" statements in update's query sub/;
test_bad_delete {
	last;
} "last in update", qr/there should be no "last" statements in delete's query sub/;
test_bad_update {
	last unless 1..2;
} "last unless in update", qr/there should be no "last" statements in update's query sub/;
test_bad_delete {
	last unless 1..2;
} "last unless in update", qr/there should be no "last" statements in delete's query sub/;

# this should be implemented
test_bad_select { t->id % 5 } "no modulo", qr/unsupported binop modulo/;

test_bad_update {
	$testmy = { x => 1, y => 2};
} "bad my table in update", qr/cannot get a table to update/;
test_bad_update {
	$testour = { x => 1, y => 2};
} "bad our table in update", qr/cannot get a table to update/;

test_bad_select {
	t->id = 1;
} "assignment in select", qr/assignments are not understood in select's query sub/;
test_bad_delete {
	t->id = 1;
} "assignment in delete", qr/assignments are not understood in delete's query sub/;

test_bad_select {
	table: my $t = $testmy * $testour;
} "bad simple term 1", qr/cannot reconstruct simple term from operation/;
test_bad_select {
	last unless $testmy * $testour..3;
} "bad simple term 2", qr/cannot reconstruct simple term from operation/;
test_bad_select {
	last unless 3..($testmy * $testour);
} "bad simple term 3", qr/cannot reconstruct simple term from operation/;

test_bad_select {
	return tab->f1;
	return tab->f2;
} "multi-returns", qr/at most one return/;
test_bad_select {
	return tab->f1 if $val;
	return tab->f2 if $val;
} "multi-returns, hidden with if", qr/at most one return/;
test_bad_select {
	return tab->f1 unless $testmy;
	return tab->f2 unless $testmy;
} "multi-returns, hidden with unless", qr/at most one return/;
# TODO same as above, with $testour - it bitches

done_testing;
