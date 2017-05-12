use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

# Don't run tests during end-user installs
use Test::More;
unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval {
    require Test::Kwalitee;
    # Module::ExtractUse won't find POD modules usage; skip those tests
    Test::Kwalitee->import( tests => [ '-has_test_pod', '-has_test_pod_coverage' ] );
};
if ( $@ ) {
    $ENV{RELEASE_TESTING}
    ? die( "Failed to load required release-testing module Test::Kwalitee" )
    : plan( skip_all => "Test::Kwalitee not available for testing" );
}

