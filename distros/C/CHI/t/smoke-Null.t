#!perl -w

BEGIN {
  unless ($ENV{AUTOMATED_TESTING}) {
    print qq{1..0 # SKIP these tests are for "smoke bot" testing\n};
    exit
  }
}

use CHI::t::Null;
CHI::t::Null->runtests;
