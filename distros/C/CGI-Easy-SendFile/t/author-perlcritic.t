#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use Test::More;

eval { require Test::Perl::Critic; };
plan(skip_all=>'Test::Perl::Critic required to criticise code') if $@;

Test::Perl::Critic->import(
    -verbose    => 9,           # verbose 6 will hide rule name
);
all_critic_ok();
