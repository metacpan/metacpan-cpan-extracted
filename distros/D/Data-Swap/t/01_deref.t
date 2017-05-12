#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use File::Spec;
use lib File::Spec->catfile("t", "lib");
use Test::More tests => 13;

use Data::Swap 'deref';

$SIG{__WARN__} = sub { die(@_) };  # in case FATAL warnings don't work

sub refs { [map "".\$_, @_] }

our $x = \1;
our $y = [2, 3, 4];
our $z = {5 => 6, 7 => 8};

is_deeply [deref $x, $y, $z], [$$x, @$y, %$z];
is_deeply refs((deref $x, $y, $z)[0,1,2,3,5,7]), refs($$x, @$y, (%$z)[1,3]);

our @r = \(($x, $y, $z) = (1, 2, 3));
$_++ for deref @r;
is_deeply [$x, $y, $z], [2, 3, 4];

(deref @r) = (42, 43, 44);
is_deeply [$x, $y, $z], [42, 43, 44];

eval { deref undef };
like $@, qr/^Use of uninitialized value in deref /;

is_deeply [do { no warnings 'uninitialized'; deref undef }], [];

eval { no warnings; deref "" };
like $@, qr/^Can't deref string /;

our @n;
our %n;

is_deeply refs(deref \$x, \@n, \$y, \$z), refs($x, $y, $z);
is_deeply refs(deref \$x, \%n, \$y, \$z), refs($x, $y, $z);

format foo =
.

eval { no warnings; deref \&refs };
like $@, qr/^Can't deref subroutine reference /;

SKIP: {
	skip "no format refs", 1 unless *foo{FORMAT};
	eval { no warnings; deref *foo{FORMAT} };
	like $@, qr/^Can't deref format reference /;
}

eval { no warnings; deref *STDOUT{IO} };
like $@, qr/^Can't deref filehandle reference /;

use Tie::Array;

tie my @ta, 'Tie::StdArray';
my $tref = \@ta;
like tied(deref $tref), qr/^Tie::StdArray=ARRAY\(0x[0-9A-Fa-f]+\)\z/;

# vim: ft=perl
