#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 24;

use Data::Alias;


tie our $x, 'MyTie';

$x = 42;

is $MyTie::var, 42;

{
	alias local $x = 666;
	is $MyTie::var, 42;
	is $x, 666;
}

is $MyTie::var, 42;
is ref(tied($x)), 'MyTie';

{
	alias local $x;
	is $MyTie::var, 42;
	undef *x;
}

is $MyTie::var, undef;
is tied($x), undef;


tie our @y, 'MyTie';

$y[0] = 42;

is $MyTie::var, 42;

{
	alias local @y = 666;
	is $MyTie::var, 42;
	is $y[0], 666;
}

is $MyTie::var, 42;
is ref(tied(@y)), 'MyTie';

{
	alias local @y;
	is $MyTie::var, 42;
	undef *y;
}

is $MyTie::var, undef;
is tied(@y), undef;


tie our %z, 'MyTie';

$z{foo} = 42;

is $MyTie::var, 42;

{
	alias local %z = (foo => 666);
	is $MyTie::var, 42;
	is $z{foo}, 666;
}

is $MyTie::var, 42;
is ref(tied(%z)), 'MyTie';

{
	alias local %z;
	is $MyTie::var, 42;
	undef *z;
}

is $MyTie::var, undef;
is tied(%z), undef;


package MyTie;

our $var;

sub TIESCALAR { bless {}, shift }
sub TIEHASH { bless {}, shift }
sub TIEARRAY { bless {}, shift }
sub FETCH { $var }
sub STORE { $var = pop }
sub DESTROY { $var = undef }

# vim: ft=perl
