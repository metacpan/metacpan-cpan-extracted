#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub { \"foo" },
    Name2 => sub { \"foo" },
    Name3 => sub { \"foo" },
});

cmpthese $result;
