#!/usr/bin/perl -w

use strict;
use warnings qw(FATAL all);
use lib 'lib';
use Test::More tests => 4;

use Data::Alias;

SKIP: {
	skip "Scalar::Util not installed", 4
		unless eval "use Scalar::Util qw/ weaken /; 42";

	my $x = {};
	my $y = {};
	my $keepalive = $x;
	weaken($x);
	alias $x->{foo} = $y->{foo};
	$x->{foo} = 42;
	undef $keepalive;
	is $x, undef;
	is $y->{foo}, 42;

	$x = [];
	$keepalive = $x;
	weaken($x);
	alias push @$x, $y;
	$y = 42;
	is "@$keepalive", 42;
	undef $keepalive;
	is $x, undef;
}

# vim: ft=perl
