# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# ----------------------------------------------------------------------

my @foo = 1..5
@foo = map:
    $_ *= 2
    $_ += 1
@foo

is_deeply \@foo, [3, 5, 7, 9, 11]

# ----------------------------------------------------------------------

my %foo = (bar => 3,
           baz => 2, # this comment shouldn't be a problem
           moo => 4,
           zoo => 1)

my @st = map:
    $_->[0]
sort:
    $a->[1] <=> $b->[1]
map:
    [$_, $foo{$_}]
keys %foo

is_deeply \@st, [qw(zoo baz bar moo)]

# ----------------------------------------------------------------------

my %n = map { $_ => 1 } 1..5
my @n = grep:
         my $aux = $_
         $aux *= 2
         $aux % 3
     sort keys %n

is_deeply \@n, [1, 2, 4, 5]
