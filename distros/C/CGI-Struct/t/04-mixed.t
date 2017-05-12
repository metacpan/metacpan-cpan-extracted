#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 18;
use CGI::Struct;

# Test mixed multi-level bits

my %inp = (
	# A scalar
	'h{a}[0]' => 'h_a1_0',
	# A hash
	'h{a}[1]{foo}' => 'h_a1_1_foo',
	'h{a}[1]{bar}' => 'h_a1_1_bar',
	# An array holding a scalar...
	'h{a}[2][0]' => 'h_a2_0',
	# ... and a hash ...
	'h{a}[2][1]{foo}' => 'h_a2_1_foo',
	'h{a}[2][1]{bar}' => 'h_a2_1_bar',
	# ... and an array
	'h{a}[2][2][0]' => 'h_a2_2_0',
	'h{a}[2][2][1]' => 'h_a2_2_1',

	# Now a top level array, holding...
	# a hash, containing...
	# one nice simple array
	'a[0]{h1}[0]' => 'a0_h1_0',
	'a[0]{h1}[1]' => 'a0_h1_1',
	# another, with one of the arrays being sparse
	'a[0]{h2}[5]' => 'a0_h2_5',
	'a[0]{h2}[9]' => 'a0_h3_9',
	# Another level of hash of scalars
	'a[0]{h3}{foo}' => 'a0_h3_foo',
	'a[0]{h3}{bar}' => 'a0_h3_bar',
	# And sneak in another array under that
	'a[0]{h3}{baz}[0]' => 'a0_h3_baz_0',
	'a[0]{h3}{baz}[1]' => 'a0_h3_baz_1',

	# And just make a big ugly mess
	'a[1]{foo}[7]{bar}{baz}[3]' => 'amess',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

is($hval->{h}{a}[0], $inp{"h{a}[0]"}, "h{a}[0] copied right");

is($hval->{h}{a}[1]{$_}, $inp{"h{a}[1]{$_}"}, "h{a}[1]{$_} copied right")
		for qw/foo bar/;

is($hval->{h}{a}[2][0], $inp{"h{a}[2][0]"}, "h{a}[2][0] copied right");

is($hval->{h}{a}[2][1]{$_}, $inp{"h{a}[2][1]{$_}"},
   "h{a}[2][1]{$_} copied right") for qw/foo bar/;

is($hval->{h}{a}[2][2][$_], $inp{"h{a}[2][2][$_]"},
   "h{a}[2][2][$_] copied right") for 0..1;



is($hval->{a}[0]{h1}[$_], $inp{"a[0]{h1}[$_]"}, "a[0]{h1}[$_] copied right")
		for 0..1;

is($hval->{a}[0]{h2}[$_], $inp{"a[0]{h2}[$_]"}, "a[0]{h2}[$_] copied right")
		for qw/5 9/;

is($hval->{a}[0]{h3}{$_}, $inp{"a[0]{h3}{$_}"}, "a[0]{h3}{$_} copied right")
		for qw/foo bar/;

is($hval->{a}[0]{h3}{baz}[$_], $inp{"a[0]{h3}{baz}[$_]"},
		"a[0]{h3}{baz}[$_] copied right") for 0..1;

is($hval->{a}[1]{foo}[7]{bar}{baz}[3], $inp{'a[1]{foo}[7]{bar}{baz}[3]'},
		'a[1]{foo}[7]{bar}{baz}[3] copied right');
