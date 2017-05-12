#!/usr/bin/env perl

# Check source files for FIXME statements
use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

my @MODULES = ( 'Test::Fixme 0.04', );

# Don't run tests during end-user installs
use Test::More;

# plan( skip_all => 'Author tests not required for installation' )
#   unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );

# Load the testing modules
foreach my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        $ENV{RELEASE_TESTING}
          ? die("Failed to load required release-testing module $MODULE")
          : plan( skip_all => "$MODULE not available for testing" );
    }
}

run_tests( where => 'lib', match => 'TODO' );

1;
