#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

skip_all( "benchmark skipped, run it with BENCHMARK=1") unless $ENV{BENCHMARK};

require Benchmark;

our $S;

my $map = {
    read_xs => sub {
        return Colon::Config::read( $S );
    },
    read_pp => sub {
        return Colon::Config::read_pp( $S ); # limitation on \s+
    },
};

note "sanity check";

foreach my $method ( sort keys %$map ) {

    $S = <<EOS;
key1: value
key2: another value
EOS
    is $map->{$method}->(), [ 'key1' => 'value', 'key2' => 'another value' ], "sanity check: '$method'" or die;
}

note "Running benchmark";
for my $size ( 1, 4, 16, 64, 256, 1024 ) {
    note "Using $size key/value pairs\n";

    $S = '';
    foreach my $id ( 1..$size ) {
        $S .= "key$id: value is $id\n";
    }

    Benchmark::cmpthese( - 5 => $map );
    note "";
}



done_testing;

__END__

# Using 1 key/value pairs
             Rate read_pp read_xs
read_pp  628770/s      --    -66%
read_xs 1869031/s    197%      --
#
# Using 4 key/value pairs
            Rate read_pp read_xs
read_pp 237209/s      --    -58%
read_xs 569785/s    140%      --
#
# Using 16 key/value pairs
            Rate read_pp read_xs
read_pp  66985/s      --    -57%
read_xs 157592/s    135%      --
#
# Using 64 key/value pairs
           Rate read_pp read_xs
read_pp 17805/s      --    -59%
read_xs 43798/s    146%      --
#
# Using 256 key/value pairs
           Rate read_pp read_xs
read_pp  4678/s      --    -54%
read_xs 10278/s    120%      --
#
# Using 1024 key/value pairs
          Rate read_pp read_xs
read_pp 1175/s      --    -55%
read_xs 2598/s    121%      --
#