#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use File::Spec;
use lib File::Spec->catfile("t", "lib");
use Test::More tests => 20;

use Data::Swap;

sub refs { [map "".\$_, @_] }

my $foo = 42;
my $bar = 666;

swap \$foo, \$bar;

is $foo, 666;
is $bar, 42;

our $x = [1, 2, 3];
our $y = {4 => 5};
our $i = 0 + $x;

swap $x, $y;
is_deeply [@$y, %$x], [1 .. 5];
is 0+$x, $i;

eval { no warnings; swap $x, undef };
like $@, qr/^Not a reference /;

eval { no warnings; swap undef, $x };
like $@, qr/^Not a reference /;

eval { no warnings; swap $x, \undef };
like $@, qr/^Modification .* attempted /;

eval { no warnings; swap \undef, $x };
like $@, qr/^Modification .* attempted /;

bless $x, 'Overloaded';

eval { no warnings; swap $x, $y };
if ($^V lt 5.9.5) {
	like $@, qr/^Can't swap an overloaded object with a non-overloaded one/;
} else {
	is_deeply [@$x, %$y], [1 .. 5];
}

eval { no warnings; swap $y, $x };
if ($^V lt 5.9.5) {
	like $@, qr/^Can't swap an overloaded object with a non-overloaded one/;
} else {
	is_deeply [@$y, %$x], [1 .. 5];
}

bless $y, 'Overloaded';

swap $x, $y;
is_deeply [@$x, %$y], [1 .. 5];
is 0+$x, $i;

SKIP: {
	skip "no weak refs", 8 unless eval "use Scalar::Util 'weaken'; 42";

	weaken(our $wx = $x);

	swap $x, $y;
	is_deeply [@$y, %$x], [1 .. 5];
	is $wx, $x;

	undef $x;
	is $wx, undef;

	weaken($wx = $x = bless {4 => 5}, 'Overloaded');
	weaken(our $wy = $y);

	swap $x, $y;
	is_deeply [@$x, %$y], [1 .. 5];
	is $wx, $x;
	is $wy, $y;

	undef $x;
	is $wx, undef;

	undef $y;
	is $wy, undef;
}

package Overloaded;

use overload '*' => sub {}, fallback => 1;

# vim: ft=perl
