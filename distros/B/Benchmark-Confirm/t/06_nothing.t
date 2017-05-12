#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub {},
    Name2 => sub {},
    Name3 => sub {},
});

cmpthese $result;

require Test::More;
Test::More::ok(1);
Test::More::done_testing(1);

