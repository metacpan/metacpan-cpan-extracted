use warnings;
use strict;
use Test::More tests => 6*6 + 8*6;
use DBIx::Perlish;
use t::test_utils;

sub compare_field_with_constant
{
	my ($pop, $sop, $f, $c) = @_;
	my $qc = $c;
	$qc = "\"$c\"" unless $c =~ /^\d+$/;

	my $test_name = "COL $pop CONST";
	my $sub = eval <<EOF;
sub {
	tbl->$f $pop $qc
};
EOF
	ok($sub, "$test_name: prepare code");
	if ($c eq $qc) {
		&test_select_sql($sub, $test_name,
			"select * from tbl t01 where t01.$f $sop $c",
			[]);
	} else {
		&test_select_sql($sub, $test_name,
			"select * from tbl t01 where t01.$f $sop ?",
			[$c]);
	}

	$test_name = "CONST $pop COL";
	$sub = eval <<EOF;
sub {
	$qc $pop tbl->$f
};
EOF
	ok($sub, "$test_name: prepare code");
	if ($c eq $qc) {
		&test_select_sql($sub, $test_name,
			"select * from tbl t01 where $c $sop t01.$f",
			[]);
	} else {
		&test_select_sql($sub, $test_name,
			"select * from tbl t01 where ? $sop t01.$f",
			[$c]);
	}
}

compare_field_with_constant '==', '=', id   => 42;
compare_field_with_constant 'eq', '=', name => "user";
compare_field_with_constant '!=', '<>', id   => 42;
compare_field_with_constant 'ne', '<>', name => "user";
compare_field_with_constant '<', '<', id => 42;
compare_field_with_constant 'lt', '<', name => "user";
compare_field_with_constant '>', '>', id => 42;
compare_field_with_constant 'gt', '>', name => "user";
compare_field_with_constant '<=', '<=', id => 42;
compare_field_with_constant 'le', '<=', name => "user";
compare_field_with_constant '>=', '>=', id => 42;
compare_field_with_constant 'ge', '>=', name => "user";
