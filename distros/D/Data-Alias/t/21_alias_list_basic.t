#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 24;

use Data::Alias;

sub refs { [map "".\$_, @_] }

our ($x, $y, $z);

is alias(($x) = ()), 0;
is \$x, \undef;
is_deeply refs(alias +($x) = ()), refs(undef);
is \$x, \undef;
is alias(($x) = $y), 1;
is \$x, \$y;
is_deeply refs(alias +($x) = $z), refs($z);
is \$x, \$z;
is alias(($x) = ($y, $z)), 2;
is \$x, \$y;
is_deeply refs(alias +($x) = ($z, $y)), refs($z);
is \$x, \$z;
is alias(($z, $y) = ($y, $z)), 2;
is \$x, \$y;

our $r = refs($y, $z);
is_deeply refs(alias +($z, $y) = ($y, $z)), $r;
is \$x, \$z;

$r = refs($y, $x, $z);
is_deeply refs(alias +($z, undef, $y) = ($y, $x, $z)), $r;
is \$x, \$y;

$r = *x;
is_deeply refs(alias +(undef, $$r, undef) = ($r, $z, $y)), refs($r, $z, $y);
is \$x, \$z;

alias { $x = my $foo };

our (@x, %x);
undef $r;
alias +($x[0], $x{0}, $$r) = ($x, $y, $z);
is \$x[0], \$x;
is \$x{0}, \$y;
is $r, \$z;

SKIP: {
no warnings 'deprecated';
skip "pseudo-hashes not supported anymore", 1 unless eval { [{1,1},1]->{1} };

$r = [{0=>1}];
alias +($r->{0}) = ($x);
is \$r->[1], \$x;
}

# vim: ft=perl
