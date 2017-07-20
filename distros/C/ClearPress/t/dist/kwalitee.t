#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

BEGIN {
  plan skip_all => 'these tests are for release candidate testing' unless($ENV{TEST_AUTHOR});

  eval {
    require Test::Kwalitee;
    Test::Kwalitee->import('kwalitee_ok');
  };

  plan skip_all => 'Test::Kwalitee unavailable' if(!$Test::Kwalitee::VERSION);
}

kwalitee_ok();  
done_testing;
