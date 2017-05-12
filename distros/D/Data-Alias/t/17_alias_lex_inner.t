#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 34;

use Data::Alias;

my ($x, $y, $z);
my $T = 42;

is \alias($x = $y), \$y;
is \$x, \$y;
is \alias($x = $z), \$z;
is \$x, \$z;
isnt \$y, \$z;

is \alias($x ||= $T), \$T;
is \$x, \$T;
isnt \alias($x ||= $y), \$y;
is \$x, \$T;
is \alias($x &&= $z), \$z;
is \$x, \$z;
isnt \alias($x &&= $T), \$T;
is \$x, \$z;

my (@x, @y, @z);

is \alias(@x = @y), \@y;
is \@x, \@y;
is \alias(@x = @z), \@z;
is \@x, \@z;
isnt \@y, \@z;

@x = (); @z = (42);
isnt \alias(@x = (@z)), \@z;
isnt \@x, \@z;
is \$x[0], \$z[0];

my (%x, %y, %z);

is \alias(%x = %y), \%y;
is \%x, \%y;
is \alias(%x = %z), \%z;
is \%x, \%z;
isnt \%y, \%z;

%x = (); %z = (x => 42);
isnt \alias(%x = (%z)), \%z;
isnt \%x, \%z;
is \$x{x}, \$z{x};

my $outer = "outer";

sub foo {
	no warnings 'closure';
	alias $outer = "inner";
	sub { $outer }
}

is foo->(), "inner";
is $outer, "outer";

eval 'sub { alias $outer = "inner"; }';
like $@, qr/^Aliasing of outer lexical variable has limited scope/;

sub bar {
	alias my $x &&= 42;
	alias my $y ||= 42;
	[$x, $y]
}

is bar->[0], undef;
is bar->[1], 42;

# vim: ft=perl
