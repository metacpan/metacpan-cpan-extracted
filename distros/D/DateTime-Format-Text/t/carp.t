#!perl -wT

use strict;
use warnings;
use DateTime::Format::Text;
use Test::Most tests => 12;
use Test::Needs 'Test::Carp';

CARP: {
	Test::Carp->import();
	my $dft = new_ok('DateTime::Format::Text');
	ok(!defined($dft->parse('29 SepX 1939')));
	my $rc;
	eval {
		# Put in eval because of Specio execption being thrown
		$rc = $dft->parse('Foo in November 2009 Bar. XYZZY 45th PLUGH 7th TULIP');
	};
	# diag($@);
	ok(!defined($rc));
	does_croak_that_matches(sub { $dft->parse({ date => '30 Sep 1939' }) }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse(\"25 Dec 2022") }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse(string => undef) }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse(plugh => 'xyzzy') }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse(['30 Sep 1939']) }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse() }, qr/^Usage:/);
	does_croak_that_matches(sub { $dft->parse_datetime() }, qr/^Usage:/);
	does_croak_that_matches(sub { DateTime::Format::Text->parse() }, qr/^Usage:/);
	does_croak_that_matches(sub { DateTime::Format::Text::parse() }, qr/^Usage:/);
}
