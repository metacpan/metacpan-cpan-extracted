#!perl
use strict;
use warnings;

sub fib
{
    my $n = shift;
    die "can't do negatives!" if $n < 0;
    return $n * fib($n - 1);
}

fib(5);

