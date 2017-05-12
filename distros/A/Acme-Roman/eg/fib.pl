#!perl 

use strict;
use warnings;

use Acme::Roman;

use Memoize;
memoize( 'fib' ); # make it fast

# Compute Fibonacci numbers (from "perldoc Memoize")
sub fib {
    my $n = shift;
    return $n if $n < 2;
    fib($n-1) + fib($n-2);
}

for ( I, II, III, IV, V, VI, VII, VIII, IX, X ) {
    printf "fib(%s) = %s\n", $_, fib($_);
}

