#!/usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 5;
use CGI::Struct;

# Test that multi-level hashes gets built right

my %inp = (
	'h{foo}{bill}'  => 'hfoo_bill',
	'h{foo}{ted}'   => 'hfoo_ted',
	'h{bar}{bill}'  => 'hbar_bill',
	'h{bar}{ted}'   => 'hbar_ted',
);
my @errs;
my $hval = build_cgi_struct \%inp, \@errs;

is(@errs, 0, "No errors");

for my $k (qw/foo bar/)
{
	is($hval->{h}{$k}{$_}, $inp{"h{$k}{$_}"}, "h{$k}{$_} copied right")
			for qw/bill ted/;
}
