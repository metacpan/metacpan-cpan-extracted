#!/usr/bin/perl -w
use strict;

$|=1;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More;

use TestEnvironment;

# -------------------------------------------------------------------
# Variables

my $TESTS = 4;

#----------------------------------------------------------------------------
# Tests

my $handles = TestEnvironment::Handles();
if(!$handles)   { plan skip_all => "Unable to create test environment"; }
else            { plan tests    => $TESTS }

SKIP: {
    skip "No supported databases available", $TESTS  unless($handles->{CPANPREFS});

    TestEnvironment::LoadData('60');
    TestEnvironment::LoadArticles( qw(4766103 4766403 4766801) );

    my @row = $handles->{CPANPREFS}->get_query('array','select count(*) from cpanstats');
    is($row[0]->[0], 1907, "row count for cpanstats");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from ixlatest');
    is($row[0]->[0], 40, "row ct");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from uploads');
    is($row[0]->[0], 303, "row count for uploads");

    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from articles');
    is($row[0]->[0], 3, "row count for articles");
}
