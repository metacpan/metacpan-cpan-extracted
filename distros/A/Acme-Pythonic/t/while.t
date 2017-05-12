# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# ----------------------------------------------------------------------

my $x = 10
while $x--:
    pass

is $x, -1

# ----------------------------------------------------------------------

my $fbb = qq(foo bar baz)
my $c = 0
while $fbb =~ /b/g:
    ++$c

is $c, 2

# ----------------------------------------------------------------------

my $n = 25
while --$n:
    my $r = $n
    while $r != 1:
        if $r % 2 == 0:
            $r /= 2
        else:
            $r = 3*$r +1

no strict
no warnings
ok !defined $r

# ----------------------------------------------------------------------

my $i = 0
my $sum = 0
while $i < 10:
    $sum += $i
    $sum *= 1
    # comment
continue:
    ++$i

is $sum, 45

# ----------------------------------------------------------------------

package foo
our $bar = 3
my @vars = ()
while my ($key, $value) = each %foo:::
    push @vars, $key
Test::More::is_deeply(\@vars, ['bar'])
package main

# ----------------------------------------------------------------------

$i = 1
while:
    ++$i
    last if $i == 10
is $i, 10
