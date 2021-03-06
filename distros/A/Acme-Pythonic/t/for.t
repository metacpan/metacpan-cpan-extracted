# -*- Mode: Python -*-

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

use warnings

# ----------------------------------------------------------------------

my $sgn = 1
for my $i = 0; $i < 3; ++$i:
    $sgn *= -1

ok $sgn, -1

# ----------------------------------------------------------------------

BLOCK_TO_DISABLE_STRICTNESS_LOCALLY:
    no strict
    $sgn = 1
    for $i = 0; $i < 3; ++$i:
        $sgn *= -1

ok $sgn, -1


# ----------------------------------------------------------------------

my @foo = 1..10
my $n = @foo
for ; @foo; pop @foo:
    --$n
    $n += 0

is $n, 0

# ----------------------------------------------------------------------

for do {@foo = 1..10; $n = 0}; @foo; pop @foo:
    ++$n
    $n += 0

is $n, 10

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
for @foo:
    $n += $_
    $n += 0

is $n, 55

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
for in @foo:
    $n += $_
    $n += 0

is $n, 55

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
my $elt
for $elt @foo:
    $n += $elt
    $n += 0

is $n, 55

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
for $elt in @foo:
    $n += $elt
    $n += 0

is $n, 55

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
for my $foo @foo:
    ++$n
    $n += 0

is $n, scalar @foo

# ----------------------------------------------------------------------

@foo = 1..10
$n = 0
for my $moo in @foo:
    ++$n
    $n += 0

is $n, scalar @foo

# ----------------------------------------------------------------------

$n = 0
for my $x in do { reverse 1..10 }:
    $n += $x
    $n += 0

is $n, 55

# ----------------------------------------------------------------------

my @array = qw(foo ofo oof)
for my $perm in @array:
    $perm .= $perm
continue:
    $perm =~ s/f//g

is_deeply \@array, [('oooo') x 3]

# ----------------------------------------------------------------------

package foo
our $bar = 3
$bar = 7
my @vars = ()
push @vars, $_ for keys %foo::
Test::More::is_deeply(\@vars, ['bar'])
package main

# ----------------------------------------------------------------------

$n = 0
for 1,,,:
    ++$n
is $n, 1

# ----------------------------------------------------------------------

my $foo
$n = 0
for$foo 1,,,:
    ++$n
is $n, 1

# ----------------------------------------------------------------------

$n = 0
for my$baz 1,,,:
    ++$n
is $n, 1

# ----------------------------------------------------------------------

$n = 0
for(),1,,,:
    ++$n
is $n, 1

# ----------------------------------------------------------------------

$n = 0
for$foo,1,,,:
    ++$n
is $n, 2

# ----------------------------------------------------------------------

%foo = (foo => 1)
$n = 0
for%foo,1,,,:
    ++$n
is $n, 3

# ----------------------------------------------------------------------

%foo = (foo => 1)
$n = 0
for my$zoo\%foo,1,,,:
    ++$n
is $n, 2

# ----------------------------------------------------------------------

@foo = (1)
$n = 0
for@foo,1,,,:
    ++$n
is $n, 2

# ----------------------------------------------------------------------

$n = 0
for\@foo,1,,,:
    ++$n
is $n, 2


# ----------------------------------------------------------------------

%foo = (foo => 1)
$n = 0
for%foo,1,,,:
    ++$n
is $n, 3

# ----------------------------------------------------------------------

%foo = (foo => 1)
$n = 0
for\%foo,1,,,:
    ++$n
is $n, 2

# ----------------------------------------------------------------------

$n = 0
for 1,
 2,
    3,
    4 =>
               5:
    ++$n
    --$n

is $n, 0

# ----------------------------------------------------------------------

$n = 0
--$n for 1,
 2,
    3,
    4 =>
               5

is $n, -5
