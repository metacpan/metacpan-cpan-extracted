#!/usr/bin/perl

# Ensure pod coverage in your distribution
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

my @MODULES = (
	'Pod::Coverage 0.18',
	'Test::Pod::Coverage 1.08',
);

# Don't run tests during end-user installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE ( @MODULES ) {
	eval "use $MODULE";
	if ( $@ ) {
		$ENV{RELEASE_TESTING}
		? die( "Failed to load required release-testing module $MODULE" )
		: plan( skip_all => "$MODULE not available for testing" );
	}
}

my $trustme = [

    # Captive::Portal
    'new',
    'run',
    'active_view',
    'detail_status_view',
    'dispatch',
    'error_page_500',
    'idle_view',
    'login',
    'logout',
    'no_mac_view',
    'no_ssl_detected',
    'splash_view',
    'summary_status_view',

    # Captive::Portal::TestServer
    'print_banner',
];

all_pod_coverage_ok({trustme => $trustme});


1;
