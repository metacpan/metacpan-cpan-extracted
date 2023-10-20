
BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print qq{1..0 # SKIP these tests are for release candidate testing\n};
        exit;
    }
}

use strict;
use warnings;
use Test::More;

use Test::DistManifest;
manifest_ok();
