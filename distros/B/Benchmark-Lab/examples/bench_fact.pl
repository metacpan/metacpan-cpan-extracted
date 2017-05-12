#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Benchmark::Lab -profile => $ENV{DO_PROFILE};

sub fact { my $n = int(shift); return $n == 1 ? 1 : $n * fact( $n - 1 ) }

*Fact::do_task = sub {
    my $context = shift;
    fact( $context->{n} );
};

my $bl      = Benchmark::Lab->new;
my $context = { n => 25 };
my $res     = $bl->start( "Fact", $context );

printf( "Median rate: %d/sec\n", $res->{median_rate} );
