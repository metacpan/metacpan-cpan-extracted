#!/usr/bin/perl -w
use strict;

$|=1;

use Test::More;

use lib ('t/lib');
use TestEnvironment;

# -------------------------------------------------------------------
# Variables

my $TESTS = 3;

#----------------------------------------------------------------------------
# Tests

my $handles = TestEnvironment::Handles();
if(!$handles)   { plan skip_all => "Unable to create test environment"; }
else            { plan tests    => $TESTS }

SKIP: {
    skip "No supported databases available", $TESTS  unless($handles->{CPANPREFS});

    TestEnvironment::LoadData('70');

    my @row = $handles->{CPANPREFS}->get_query('array','select count(*) from cpanstats');
    is($row[0]->[0], 2835, "row count for cpanstats");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from ixlatest');
    is($row[0]->[0], 43, "row ct");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from uploads');
    is($row[0]->[0], 207, "row count for uploads");
}
