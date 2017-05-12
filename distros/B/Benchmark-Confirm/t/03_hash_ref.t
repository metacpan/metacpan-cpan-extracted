#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese cmpthese/;

my $result = timethese( 1 => +{
    Name1 => sub { +{ a => 1 } },
    Name2 => sub { +{ a => 1 } },
    Name3 => sub { +{ a => 1 } },
});

cmpthese $result;