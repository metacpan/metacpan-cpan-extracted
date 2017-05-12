#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More qw|no_plan|;
use TestData;
use Calendar::List;
use Calendar::Functions qw(:test);

# switch off DateTime and Date::ICal, if loaded
_caltest(0,0);

###########################################################################
# name: 33select-tl.t
# desc: Dates for calendar_selectbox function
###########################################################################

# -------------------------------------------------------------------------
# The tests

my @tests = (1..10,14,15);
push @tests, 11,12,13	if($on_unix);

# 1. testing the returned string
foreach my $test (@tests) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
	my $str = calendar_selectbox(@args);

	if($tests{$test}->{hash}) {
		is($str,$expected03{$test},".. matches $test index");
	} else {
		my @array1 = split("\n",$str);
		my @array2 = split("\n",$expected03{$test});
#		is_deeply(\@array1,\@array2);
		is(scalar(@array1),scalar(@array2),".. matches $test count");
#		is(length $str,length $expected03{$test});
	}
}

