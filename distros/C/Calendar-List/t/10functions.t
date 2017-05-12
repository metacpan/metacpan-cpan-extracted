#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw(no_plan);
#use Test::More test => 69;
use TestData;
use Calendar::Functions qw(:form);

# Note this test is for the base functions that don't rely on other modules

# The basic functions
for my $test (sort keys %exts)       { is(ext($test), $exts{$test},      ".. passed ext test $test")  }
for my $test (sort keys %monthtest)  { is(moty($test),$monthtest{$test}, ".. passed moty test $test") }
for my $test (sort keys %daytest)    { is(dotw($test),$daytest{$test},   ".. passed dotw test $test") }

# date formatting
foreach my $test (@format01) {
	my $str = format_date(@{$test->{array}});
	is($str,$test->{result});
}

foreach my $test (@format02) {
	my $str = reformat_date(@{$test->{array}});
	is($str,$test->{result});
}
