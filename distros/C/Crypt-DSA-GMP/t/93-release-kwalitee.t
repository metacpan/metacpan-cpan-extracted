#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
  plan( skip_all => 'these tests are for release candidate testing' );
}

unless (
  eval {
    require Test::Kwalitee;
    Test::Kwalitee->import();
    unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
    1;
  }
) {
  plan( skip_all => 'Test::Kwalitee required for testing kwalitee' ) if $@;
}

