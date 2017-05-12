#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
    unless ($ENV{REALLY_FORK_BOMB}) {
        plan skip_all => "Are you crazy? Do not run this test. If you really want this test, set the REALLY_FORK_BOMB environment to a true value.";
    }
}

use Acme::Fork::Bomb;

ok 1;
done_testing;
