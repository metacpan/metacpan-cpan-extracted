#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use_ok('Adam');

can_ok('Adam', 'async');

SKIP: {
    eval { require IO::Async::Loop::POE };
    skip 'IO::Async::Loop::POE not installed', 1 if $@;

    ok(1, 'IO::Async::Loop::POE is available');
}

done_testing();
