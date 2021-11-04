#!perl -w

BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    print qq{1..0 # SKIP these tests are for "smoke bot" testing\n};
    exit
  }
}

use CHI::t::Driver::Subcache::l1_cache;
CHI::t::Driver::Subcache::l1_cache->runtests;
