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
# name: 23list-tl.t
# desc: Dates for calendar_list function using Time::Local
###########################################################################

# -------------------------------------------------------------------------
# The tests

my @tests = (1..4,9,10,14,15);
push @tests, 11,13	if($on_unix);

# 1. testing the returned array
foreach my $test (@tests) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};

	my @array = calendar_list(@args);

	if($tests{$test}->{hash}) {
		is_deeply(\@array,$expected02{$test},".. matches $test index");
	} else {
		is(scalar(@array),scalar(@{$expected02{$test}}),".. matches $test count");
	}
}

@tests = (5..8);
push @tests, 12		if($on_unix);

# 2. testing the returned hash
foreach my $test (@tests) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
	
    my %hash = calendar_list(@args);

	if($tests{$test}->{hash}) {
		is_deeply(\%hash,$expected02{$test},".. matches $test index");
	} else {
		is(scalar(keys %hash),scalar(keys %{$expected02{$test}}),".. matches $test count");
	}
}
