#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 7;
use CGI::Struct;

# Test multi-level arrays

my %inp = (
	'a[0][0]' => 'arr0_0',
	'a[0][1]' => 'arr0_1',
	'a[0][2]' => 'arr0_2',
	'a[1][0]' => 'arr1_0',
	'a[1][1]' => 'arr1_1',
	'a[1][2]' => 'arr1_2',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

for my $l1 (qw/0 1/)
{
	is($hval->{a}[$l1][$_], $inp{"a[$l1][$_]"}, "a[$l1][$_] copied right")
			for 0..2;
}
