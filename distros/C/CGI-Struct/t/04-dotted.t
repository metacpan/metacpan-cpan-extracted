#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 20;
use CGI::Struct;

# Test dotted forms

my %inp = (
	# Single-level
	'h.foo' => 'hashfoo',
	'h.bar' => 'hashbar',

	# In an array
	'a[0].foo' => 'a0_foo',
	'a[0].bar' => 'a0_bar',

	# or a hash
	'h2{x}.foo' => 'h2_x_foo',
	'h2{x}.bar' => 'h2_x_bar',

	# or a hash of arrays
	'h2{y}[1].foo' => 'h2_y_1_foo',
	'h2{y}[1].bar' => 'h2_y_1_bar',

	# or a hash of arrays of hashes.  Sheesh.
	'h2{y}[2]{z}.foo' => 'h2_y_2_z_foo',
	'h2{y}[2]{z}.bar' => 'h2_y_2_z_bar',

	# And in the middle
	'h2{z}.foo{a}' => 'h2_z_foo_a',
	'h2{z}.bar{a}' => 'h2_z_bar_a',
	'h2{zz}.foo[1]' => 'h2_zz_foo_1',
	'h2{zz}.bar[1]' => 'h2_zz_bar_1',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

for my $k (qw/foo bar/)
{
	is($hval->{h}{$k}, $inp{"h.$k"}, "h.$k copied right");
	is($hval->{a}[0]{$k}, $inp{"a[0].$k"}, "a[0].$k copied right");
	is($hval->{h2}{x}{$k}, $inp{"h2{x}.$k"}, "h2{x}.$k copied right");
	is($hval->{h2}{y}[1]{$k}, $inp{"h2{y}[1].$k"},
	   "h2{y}[1].$k copied right");
	is($hval->{h2}{y}[2]{z}{$k}, $inp{"h2{y}[2]{z}.$k"},
	   "h2{y}[2]{z}.$k copied right");

	# Backslashes after $k to keep perl from looking for %k or @k,
	# respectively.  Using ${k} instead works on 5.8+, but not on 5.6.
	is($hval->{h2}{z}{$k}{a}, $inp{"h2{z}.$k\{a}"},
	   "h2{z}.$k\{a} copied right");
	is($hval->{h2}{zz}{$k}[1], $inp{"h2{zz}.$k\[1]"},
	   "h2{z}.$k\[1] copied right");
}


# Test of turning off dotting
%inp = (
	'h.v' => 'dotted hash',
	'h{x.y}' => 'dotted name',
);
@errs = ();
$hval = build_cgi_struct \%inp, \@errs, {nodot => 1};

is(@errs, 0, "No errors");

# Make sure it didn't translate
is($hval->{'h.v'}, $inp{'h.v'}, 'h.v untranslated with nodot');
is($hval->{h}{v}, undef, "h{v} didn't sneak in");

# Make sure the name comes through
ok(grep(/^x\.y$/, keys %{$hval->{h}}), 'x.y name translated');


# Double check that it gets an error without nodot
$hval = build_cgi_struct \%inp, \@errs;
ok(grep(/ender for \{ in x for h\{x.y}/, @errs),
   'without nodot properly failed');
