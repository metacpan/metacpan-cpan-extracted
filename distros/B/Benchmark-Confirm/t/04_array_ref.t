#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub { [1, 2] },
    Name2 => sub { [1, 2] },
    Name3 => sub { [1, 2] },
});

cmpthese $result;