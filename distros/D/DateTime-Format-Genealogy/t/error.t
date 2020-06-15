#!perl -wT

use strict;
use warnings;
use Test::Most;
use DateTime::Format::Genealogy;
use Carp;

eval 'use Test::Carp';

ERROR: {
	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		plan(tests => 12);

		my $f = new_ok('DateTime::Format::Genealogy');
		does_croak_that_matches(sub { $f->parse_datetime('29 SepX 1939') }, qr/^Unparseable date/);
		does_carp_that_matches(sub { $f->parse_datetime('31 Nov 1939') }, qr/^31 Nov 1939/);
		does_croak_that_matches(sub { $f->parse_datetime(['29 Sep 1939']) }, qr/^Usage:/);
		does_croak_that_matches(sub { $f->parse_datetime({ datex => '30 Sep 1939' }) }, qr/^Usage:/);
		does_carp_that_matches(sub { $f->parse_datetime('Bef 29 Sep 1939') }, qr/invalid/);
		does_carp_that_matches(sub { $f->parse_datetime('Aft 1 Jan 2000') }, qr/invalid/);
		is($f->parse_datetime(date => 'Aft 1 Jan 2000', quiet => 1), undef, 'quiet does not carp');
		does_croak_that_matches(sub { $f->parse_datetime() }, qr/^Usage:/);
		does_croak_that_matches(sub { $f->parse_datetime(date => undef) }, qr/^Usage:/);
		does_carp_that_matches(sub { $f->parse_datetime({ date => '28 Jul 1914 - 11 Nov 1918' }) }, qr/Changing date/);
		does_croak_that_matches(sub { $f->parse_datetime(date => '12 June 2020', strict => 1) }, qr/^Unparseable date/);
	}
}
