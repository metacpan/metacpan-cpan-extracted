#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 10;
use CGI::Struct;

# Make sure odd characters work

my %inp = (
	"h{xy'z}" => 'singlequote',
	'h{xy"z}' => 'doublequote',
	'h{xy/z}' => 'slash',
	'h{xy\\z}' => 'backslash',
	"h{x\x{ff}z}" => '8-bit char',
	'h{xy$z}' => 'dollar',
	'h{xy@z}' => 'at',
	'h{xy%z}' => 'percent',
	'h{xy#z}' => 'hash',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

for my $k (keys %inp)
{
	(my $ok = $k) =~ s/h\{(.*)}/$1/;
	is($hval->{h}{$ok}, $inp{$k}, "$k copied right");
}
