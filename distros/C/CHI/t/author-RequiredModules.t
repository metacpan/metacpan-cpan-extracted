#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use CHI::t::RequiredModules;
CHI::t::RequiredModules->runtests;
