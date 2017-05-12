#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 12;

use Data::Alias;

sub refs { [map "".\$_, @_] }

our $x = alias [];
is @$x, 0;

is_deeply alias([$_]), [$_]  for 1 .. 3;

$x = alias [42];
eval { $x->[0]++ };
like $@, qr/^Modification .* attempted /;

$x = alias [$x];
is_deeply refs(@$x), refs($x);

$x = alias [$x, our $y];
is_deeply refs(@$x), refs($x, $y);

$x = alias [$x, $y, our $z];
is_deeply refs(@$x), refs($x, $y, $z);

$x = alias [undef, $y, undef];
is @$x, 3;
is \$x->[1], \$y;
ok "$]" < 5.019004 ? !exists($x->[0]) : \$x->[0] eq \undef;
ok "$]" < 5.019004 ? !exists($x->[2]) : \$x->[2] eq \undef;

# vim: ft=perl
