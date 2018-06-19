#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}


use Test::CPAN::Meta::JSON;
meta_json_ok();
