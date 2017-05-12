
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

use Test::More;

eval 'use Test::Legal';
plan skip_all => 'Test::Legal required for testing licenses'
  if $@

copyright_ok;
license_ok;
