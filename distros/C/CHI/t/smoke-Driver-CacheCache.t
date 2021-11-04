#!perl -w

BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    print qq{1..0 # SKIP these tests are for "smoke bot" testing\n};
    exit
  }
}

use CHI::t::Driver::CacheCache;
CHI::t::Driver::CacheCache->runtests;
