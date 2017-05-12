#!/usr/bin/perl -w
use strict;
use lib 't';

use Test::More;
use TestData;
use Calendar::List;

# check we can load the module
eval "use Date::ICal";
if($@) { plan skip_all => "Date::ICal not installed." }
plan tests => 15;

# switch off DateTime if loaded
use Calendar::Functions qw(:test);
_caltest(0,1);

###########################################################################
# name: 32select-di.t
# desc: Dates for calendar_selectbox function
###########################################################################

# -------------------------------------------------------------------------
# The tests

# 1. testing the returned string
foreach my $test (1..15) {
	my @args = ();
	push @args, $tests{$test}->{f1}		if $tests{$test}->{f1};
	push @args, $tests{$test}->{f2}		if $tests{$test}->{f2};
	push @args, $tests{$test}->{hash}	if $tests{$test}->{hash};
	my $str = calendar_selectbox(@args);

	if($tests{$test}->{hash}) {
		is($str,$expected03{$test},".. matches $test index");
	} else {
		is(length $str,length $expected03{$test},".. matches $test count");
	}
}

