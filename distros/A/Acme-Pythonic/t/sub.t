# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# ----------------------------------------------------------------------

sub foo:
    my $i = 7
    return $i

is foo, 7

# ----------------------------------------------------------------------

my $coderef = sub:
    my $n = shift
    $n *= 3

is $coderef->(3), 9

# ----------------------------------------------------------------------

my $fib
$fib = sub:
    my $n = shift
    die if $n < 0
    $n < 2 ? $n : $fib->($n - 1) + $fib->($n - 2)

is $fib->(5), 5

# ----------------------------------------------------------------------

sub count_collatz_steps:
    my $n = shift
    my $steps = 0 # do we put a semicolon here?
    while $n != 1:
        $steps++
        if $n % 2:
            $n = 3*$n + 1
        else:
            $n /= 2 # there is a variant that removes all even factors
    $steps

is count_collatz_steps(1), 0
is count_collatz_steps(2), 1
is count_collatz_steps(5), 5
