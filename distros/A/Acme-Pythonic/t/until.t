# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic;

# ----------------------------------------------------------------------

my $x = 10
until $x-- == 0:
    pass

is $x, -1

# ----------------------------------------------------------------------

my $fbb = qq(foo bar baz)
my $c = 0
until $fbb !~ /b/g:
    ++$c

is $c, 2

# ----------------------------------------------------------------------

my $n = 25
until --$n == 0:
    my $r = $n
    until $r == 1:
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
until $i == 10:
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
until not my ($key, $value) = each %foo:::
    push @vars, $key
Test::More::is_deeply(\@vars, ['bar'])
