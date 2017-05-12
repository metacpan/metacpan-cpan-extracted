#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub { sub { 1 } },
    Name2 => sub { sub { 2 } },
    Name3 => sub { sub { 3 } },
});

cmpthese $result;
