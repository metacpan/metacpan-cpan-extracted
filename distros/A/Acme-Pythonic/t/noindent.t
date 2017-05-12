# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic;

# ----------------------------------------------------------------------

my $foo = "foo"
is $foo, "foo"

# ----------------------------------------------------------------------

use vars qw($bar $baz)
$bar = "bar"
local *baz
*baz = $bar
is $bar, $baz

# ----------------------------------------------------------------------

my $zoo = 5
$zoo = 7 if $zoo == 5
is $zoo, 7

# ----------------------------------------------------------------------

my $mu = "moo"
$mu = $mu eq $bar ? q:some colons: : ""
is $mu, ""

# ----------------------------------------------------------------------

my $moo = "moo"
$moo =~ s:moo:foo:
is $moo, $foo

# ----------------------------------------------------------------------

# Checks we don't see a comment in $#foo
my @foo = (0, 1)
my $n = 0
$#foo || undef $n
ok defined $n
