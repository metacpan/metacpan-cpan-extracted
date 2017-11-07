# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
use Test::More;
use strict;
use warnings;

our $VERSION = q[477.1.4];

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
