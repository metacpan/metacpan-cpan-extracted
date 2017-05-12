#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 6;
use CGI::Struct;

# Test arrays of hashes

my %inp = (
	'a[0]{foo}' => 'arr0_foo',
	'a[0]{bar}' => 'arr0_bar',
	'a[0]{baz}' => 'arr0_baz',
	'a[1]{fred}' => 'arr1_fred',
	'a[1]{wilma}' => 'arr1_wilma',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");
is($hval->{a}[0]{$_}, $inp{"a[0]{$_}"}, "a[0]{$_} copied right")
		for qw/foo bar baz/;
is($hval->{a}[1]{$_}, $inp{"a[1]{$_}"}, "a[1]{$_} copied right")
		for qw/fred wilma/;
