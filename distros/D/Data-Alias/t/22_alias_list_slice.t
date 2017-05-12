#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 12;

use Data::Alias;

sub refs { [map "".\$_, @_] }

our ($x, $y);
our ($a, $b, $c, $d);

our @x;

alias +($x, @x[1,0], $y) = ($a, $b, $c, $d);
is_deeply refs($x, @x[1,0], $y), refs($a, $b, $c, $d);
alias @x[1,0] = @x;
is_deeply refs(@x), refs($b, $c);
is_deeply refs(alias { local @x[0,1] = ($a, $d); @x }), refs($a, $d);
is_deeply refs(@x), refs($b, $c);

our %x;

alias +($y, @x{1,0}, $x) = ($a, $b, $c, $d);
is_deeply refs($y, @x{1,0}, $x), refs($a, $b, $c, $d);
alias @x{1,0} = @x{0,1};
is_deeply refs(@x{0,1}), refs($b, $c);
is_deeply refs(alias { local @x{0,1} = ($a, $d); @x{0,1} }), refs($a, $d);
is_deeply refs(@x{0,1}), refs($b, $c);

SKIP: {
no warnings 'deprecated';
skip "pseudo-hashes not supported anymore", 4 unless eval { [{1,1},1]->{1} };

our $r = [{0=>1,1=>2}];

alias +($y, @$r{1,0}, $x) = ($a, $b, $c, $d);
is_deeply refs($y, @$r[2,1], $x), refs($a, $b, $c, $d);
alias @$r{1,0} = @$r[1,2];
is_deeply refs(@$r[1,2]), refs($b, $c);
is_deeply refs(alias { local @$r{0,1} = ($a, $d); @$r[1,2] }), refs($a, $d);
is_deeply refs(@$r[1,2]), refs($b, $c);
}

# vim: ft=perl
