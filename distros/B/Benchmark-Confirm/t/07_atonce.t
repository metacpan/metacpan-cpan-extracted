#!/usr/bin/perl
use strict;
use warnings;

use Benchmark::Confirm qw/timethese/;

{
    my $result = timethese( 1 => +{
        Name1 => sub { "something" },
        Name2 => sub { "something" },
        Name3 => sub { "something" },
    });
}

Benchmark::Confirm->atonce;

{
    my $result = timethese( 1 => +{
        Name1 => sub { 1 },
        Name2 => sub { 1 },
        Name3 => sub { 1 },
    });
}
