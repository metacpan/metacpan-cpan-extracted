#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 18;
use CGI::Struct;

# Test that a simple array gets built right

my %inp = (
	'a[0]' => 'arr0',
	'a[1]' => 'arr1',
	'a[2]' => 'arr2',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");
is($hval->{a}[$_], $inp{"a[$_]"}, "a[$_] copied right") for 0..2;


# Test NULL-splitting
%inp = (
	'b'    => "ab0\0ab1\0ab2",
	'c.d'  => "cd0\0cd1\0cd2",
);
$hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");
is(ref $hval->{b}, 'ARRAY', "b properly split into array");
is(ref $hval->{c}{d}, 'ARRAY', "c{d} properly split into array");
is($hval->{b}[$_], "ab$_", "b[$_] has expected value") for 0..2;
is($hval->{c}{d}[$_], "cd$_", "c{d}[$_] has expected value") for 0..2;


$hval = build_cgi_struct \%inp, \@errs, {nullsplit => 0};

is(@errs, 0, "No errors");
is(ref $hval->{b}, '', "b properly not split into array");
is($hval->{b}, $inp{b}, "b content cleanly copied");
is(ref $hval->{c}{d}, '', "c{d} properly not split into array");
is($hval->{c}{d}, $inp{'c.d'}, "c{d} content cleanly copied");
