#!perl -wT

use strict;
use warnings;
use Test::Most;
use DateTime::Format::Text;

eval 'use Test::Carp';

ERROR: {
	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		plan(tests => 7);
		my $dft = new_ok('DateTime::Format::Text');
		ok(!defined($dft->parse('29 SepX 1939')));
		does_croak_that_matches(sub { $dft->parse({ date => '30 Sep 1939' }) }, qr/^Usage:/);
		does_croak_that_matches(sub { $dft->parse(string => undef) }, qr/^Usage:/);
		does_croak_that_matches(sub { $dft->parse(['30 Sep 1939']) }, qr/^Usage:/);
		does_croak_that_matches(sub { $dft->parse() }, qr/^Usage:/);
		does_croak_that_matches(sub { DateTime::Format::Text->parse() }, qr/^Usage:/);
	}
}
