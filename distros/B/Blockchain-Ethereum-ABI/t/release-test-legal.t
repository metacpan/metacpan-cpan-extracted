
BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print qq{1..0 # SKIP these tests are for release candidate testing\n};
        exit;
    }
}

use strict;
use warnings;

use Test::More qw(no_plan);

SKIP: {

    eval { require Test::Legal };

    skip "Test::Legal required for testing licences" if $@;

    eval { Test::Legal->import() };

    BAIL_OUT "Test::Legal reported error on import so aborting tests: $@" if $@;

    can_ok(__PACKAGE__, qw(copyright_ok license_ok));

    main->copyright_ok;

    main->license_ok;

}
