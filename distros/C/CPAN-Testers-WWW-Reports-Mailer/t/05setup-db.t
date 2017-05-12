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

my $TESTS = 5;

#----------------------------------------------------------------------------
# Tests

my $result = TestEnvironment::Create();
if(!$result)    { plan skip_all => "Unable to create test environment"; }
else            { plan tests    => $TESTS }


SKIP: {
    skip "No supported databases available", $TESTS  unless($result);

    my $handles = TestEnvironment::Handles();
    TestEnvironment::LoadData('05');
    

    my @row = $handles->{CPANPREFS}->get_query('array','select count(*) from cpanstats');
    is($row[0]->[0], 35, "row count for cpanstats");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from uploads');
    is($row[0]->[0], 68, "row count for uploads");

    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from articles');
    is($row[0]->[0], 2, "row count for articles");

    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from prefs_authors');
    is($row[0]->[0], 16, "row count for prefs_authors");
    @row = $handles->{CPANPREFS}->get_query('array','select count(*) from prefs_distributions');
    is($row[0]->[0], 16, "row count for prefs_distributions");
}
