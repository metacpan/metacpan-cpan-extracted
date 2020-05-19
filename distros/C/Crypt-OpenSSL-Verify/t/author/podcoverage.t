#!/usr/bin/env perl
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage 1.04;

all_pod_coverage_ok({
    also_private => [qw/ dl_load_flags /],
});
