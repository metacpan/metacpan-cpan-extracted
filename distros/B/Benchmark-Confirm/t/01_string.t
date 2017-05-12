#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub { "something" },
    Name2 => sub { "something" },
    Name3 => sub { "something" },
});

cmpthese $result;
