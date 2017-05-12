#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 4;
use CGI::Struct;

# Test that a simple hash gets built right

my %inp = (
	'h{foo}' => 'hashfoo',
	'h{bar}' => 'hashbar',
	'h{baz}' => 'hashbaz',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");
is($hval->{h}{$_}, $inp{"h{$_}"}, "h{$_} copied right") for qw/foo bar baz/;
