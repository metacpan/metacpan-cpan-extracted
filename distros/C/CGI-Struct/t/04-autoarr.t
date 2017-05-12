#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 4;
use CGI::Struct;

# Test autoarrays

my %inp = (
	# Array in the base
	'a[]' => [qw(foo bar baz)],

	# One a couple levels down
	'h{foo}[1]{bar}[]' => [qw(da1 da2)],

	# One with only a single element
	'a2[]' => 'a2val',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

# These two just copy straight
is_deeply($hval->{a}, $inp{'a[]'}, 'a[] correct');

is_deeply($hval->{h}{foo}[1]{bar}, $inp{'h{foo}[1]{bar}[]'},
          'h{foo}[1]{bar}[] correct');

# Make sure this becomes a (1-element) array, not a scalar
is_deeply($hval->{a2}, ['a2val'], 'a2[] correct');
