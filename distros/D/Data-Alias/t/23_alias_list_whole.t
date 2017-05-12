#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 51;

use Data::Alias qw(alias deref);

sub refs { [map "".\$_, @_] }
sub srefs { [sort map "".\$_, @_] }

our ($x, $y);
our ($a, $b, $c, $d, $e) = (1 .. 5);

our @x;

is alias(($x, @x, $y) = ($a, $b, $c, $d)), 4;
is_deeply refs(@x), refs($b, $c, $d);
is_deeply refs($x, $y), refs($a, undef);

is_deeply refs(alias +($y, @x, $x) = ($b, $c, $d)), refs($b, $c, $d, undef);
is_deeply refs(@x), refs($c, $d);
is_deeply refs($y, $x), refs($b, undef);

is_deeply refs(alias +($x, @x, $y) = ()), refs(undef, undef);
is @x, 0;
is_deeply refs($x, $y), refs(undef, undef);
is alias(($x, @x, $y) = ()), 0;

is alias((@x) = (undef, $a, undef, $b, undef)), 5;
is_deeply refs(deref \@x), refs(undef, $a, undef, $b, undef);

our %x;

is alias(($x, %x, $y) = ($a, $b, $c, $d, $e)), 5;
is keys(%x), 2;
is_deeply refs(@x{$b, $d}), refs($c, $e);
is_deeply refs($x, $y), refs($a, undef);

is_deeply refs(alias +($y, %x, $x) = ($b, $c, $d)), refs($b, $c, $d, undef);
is keys(%x), 1;
is_deeply refs($x{$c}, $y, $x), refs($d, $b, undef);

is_deeply refs(alias +($x, %x, $y) = ()), refs(undef, undef);
is keys(%x), 0;
is_deeply refs($x, $y), refs(undef, undef);
is alias(($x, %x, $y) = ()), 0;

is alias((%x) = ($a, $b, $c, undef, $d, $e)), 6;
is keys(%x), 2;
is_deeply refs($x{$a}, $x{$d}), refs($b, $e);

is alias(($x, %x, $y) = ($a, $a, $b, $b, undef, $a, undef, $b, $c)), 9;
is keys(%x), 1;
is_deeply refs($x{$b}, $x, $y), refs($c, $a, undef);
is_deeply refs(alias +($x, %x, $y) = ($a, $a, $b, $b, undef, $a, undef, $b, $c)),
				refs($a, $a, undef, $b, $c, undef);

eval { alias +(%x) = ($a, $b, $c) };
like $@, qr/^Odd number of elements /;

{
no warnings 'misc';
is alias(($y, %x, $x) = ($e, $a, $b, $c, $d, $a)), 6;
is keys(%x), 1;
is_deeply refs($x{$c}, $y, $x), refs($d, $e, undef);
is_deeply refs(alias +($y, %x, $x) = ($e, $a, $b, $c, $d, $a)),
				refs($e, $c, $d, $a, undef);
}

SKIP: {
no warnings 'deprecated';
skip "pseudo-hashes not supported anymore", 16 unless eval { [{1,1},1]->{1} };

our $r = [{$a=>1,$b=>2,$c=>3,$d=>4}];

is alias(($x, %$r, $y) = ($a, $b, $c, $d, $e)), 5;
is_deeply refs($x, $y, deref $r), refs($a, undef, $$r[0], undef, $c, undef, $e);

is_deeply refs(alias +($y, %$r, $x) = ($b, $c, $d)), refs($b, $c, $d, undef);
is_deeply refs($y, $x, deref $r), refs($b, undef, $$r[0], undef, undef, $d);

is_deeply refs(alias +($x, %$r, $y) = ()), refs(undef, undef);
is_deeply refs($x, $y, deref $r), refs(undef, undef, $$r[0]);
is alias(($x, %$r, $y) = ()), 0;

is alias((%$r) = ($a, $b, $c, undef, $d, $e)), 6;
is_deeply refs(deref $r), refs($$r[0], $b, undef, undef, $e);

is alias(($x, %$r, $y) = ($a, $a, $b, $b, undef, $a, undef, $b, $c)), 9;
is_deeply refs($x, $y, deref $r), refs($a, undef, $$r[0], undef, $c);
is_deeply refs(alias +($x, %$r, $y) = ($a, $a, $b, $b, undef, $a, undef, $b, $c)),
				refs($a, $a, undef, $b, $c, undef);

eval { alias +(%$r) = ($a, $b, $c) };
like $@, qr/^Odd number of elements /;

{
no warnings 'misc';
is alias(($y, %$r, $x) = ($e, $a, $b, $c, $d, $a)), 6;
is_deeply refs($y, $x, deref $r), refs($e, undef, $$r[0], undef, undef, $d);
is_deeply refs(alias +($y, %$r, $x) = ($e, $a, $b, $c, $d, $a)),
				refs($e, $c, $d, $a, undef);
}

}

# vim: ft=perl
