#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Autocache qw( autocache );

Autocache->initialise( filename => 't/001_fib.t.conf' );

ok( autocache 'fib', 'Autocache function' );

is( fib( 65 ), 17167680177565, '65th Fibonacci number' );

exit;

sub fib
{
    my ($n) = @_;
    return 1 if( $n == 1 || $n == 2 );
    return ( fib( $n - 1 ) + fib( $n - 2 ) );
}
