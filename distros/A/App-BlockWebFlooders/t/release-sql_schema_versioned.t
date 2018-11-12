#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}


# currently dummy

use Test::More 0.98;

ok 1;
done_testing;
