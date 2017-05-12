#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
  plan( skip_all => 'these tests are for release candidate testing' );
}

eval 'use Test::Kwalitee';  ## no critic (eval)
plan( skip_all => 'Test::Kwalitee required for testing kwalitee' ) if $@;

unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
