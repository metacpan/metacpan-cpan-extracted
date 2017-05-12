#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Autocache qw( autocache );

Autocache->initialise( filename => 't/004_stat.t.conf' );

ok( autocache 'fib', 'Autocache function' );

my $junk = fib( 65 );

is( fib( 65 ), 17167680177565, '65th Fibonacci number' );

my $strategy = Autocache->singleton->get_strategy( 'stats' );

my $stats = $strategy->statistics;

is( $stats->{create}, 65, 'Create count correct' );

is( $stats->{hit}, 63, 'Hit count correct' );

is( $stats->{miss}, 65, 'Miss count correct' );

exit;

sub fib
{
    my ($n) = @_;
    return 1 if( $n == 1 || $n == 2 );
    return ( fib( $n - 1 ) + fib( $n - 2 ) );
}
