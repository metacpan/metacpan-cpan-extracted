#!/usr/bin/perl

# Test that our META.yml file matches the specification

use strict;
use warnings;

my @MODULES = ( "Test::CPAN::Meta 0.12" );

my $has_meta = -f "META.yml";

# Don't run tests during end-user installs
use Test::More;
$ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING} || !$has_meta or
    plan skip_all => "Author tests not required for installation";

# Load the testing modules
foreach my $MODULE (@MODULES) {
    eval "use $MODULE";
    $@ or next;
    $ENV{RELEASE_TESTING}
	? die "Failed to load required release-testing module $MODULE"
	: plan skip_all => "$MODULE not available for testing";
    }

!$has_meta && -x "sandbox/genMETA.pl" and
    qx{ perl sandbox/genMETA.pl -v > META.yml };

meta_yaml_ok ();

$has_meta or unlink "META.yml";

1;
