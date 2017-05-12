# -*- Mode: Python -*-

use strict;
use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# ----------------------------------------------------------------------

my @lines = ("foo\n", "bar\n", "baz\n")
LINE: foreach my $line in @lines:
    chomp $line
    if $line eq "bar":
        last LINE

is_deeply(\@lines, ["foo", "bar", "baz\n"]) # in the same line

# ----------------------------------------------------------------------

my $i = 1

FOO:
while $i:
    $i += 1
    last FOO if $i == 10

is($i, 10) # above

# ------------------------------------------------------------------------

my $j = 1

BAR:
# comment
# comment
while $j:
    $j += 1
    last BAR if $j == 10

is $j, 10

# ------------------------------------------------------------------------

my $k = 7
BAZ:
    --$k
    last BAZ if $k < 0
    redo BAZ

is $k, -1

# ----------------------------------------------------------------------

my $eps = 0
ZOO:
    ++$eps
    redo unless $eps == 10
continue:
    $eps = 1

is $eps, 1

# ----------------------------------------------------------------------

# inspired by perlsyn
my @ary1 = (2, 1, 0)
my @ary2 = (0, 1, 2)
OUTER:
for my $wid in @ary1:
    INNER:
    for my $jet in @ary2:
        next OUTER if $wid > $jet
        $wid += $jet

is_deeply \@ary1, [2, 1, 3]

# ----------------------------------------------------------------------

# inspired by perlsyn
@ary1 = (2, 1, 0)
OUTER: for my $wid in @ary1:
    INNER: for my $jet in @ary2:
        next OUTER if $wid > $jet
        $wid += $jet

is_deeply \@ary1, [2, 1, 3]
