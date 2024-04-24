#!perl -wT

use strict;
use warnings;
use Test::Most tests => 23;
use Test::Needs 'Test::Carp';
use DateTime::Format::Genealogy;
use Carp;

ERROR: {
	Test::Carp->import();

	my $f = new_ok('DateTime::Format::Genealogy');

	does_carp_that_matches(sub { $f->parse_datetime('29 SepX 1939') }, qr/^Unparseable date/);
	does_carp_that_matches(sub { $f->parse_datetime(date =>, '29 Se 1939', strict => 1) }, qr/^Unparseable date/);
	does_carp_that_matches(sub { $f->parse_datetime(date =>, '29 Sep. 1939', strict => 1) }, qr/^Unparseable date/);
	does_carp_that_matches(sub { $f->parse_datetime('31 Nov 1939') }, qr/^31 Nov 1939/);
	does_croak_that_matches(sub { $f->parse_datetime(['29 Sep 1939']) }, qr/^Usage:/);
	does_croak_that_matches(sub { $f->parse_datetime({ datex => '30 Sep 1939' }) }, qr/^Usage:/);
	does_carp_that_matches(sub { $f->parse_datetime('Bef 29 Sep 1939') }, qr/invalid/);
	does_carp_that_matches(sub { $f->parse_datetime(date => 'bef 29 Sep 1939', strict => 1) }, qr/need an exact date/);
	does_carp_that_matches(sub { $f->parse_datetime('Aft 1 Jan 2000') }, qr/invalid/);
	is($f->parse_datetime(date => 'Aft 1 Jan 2000', quiet => 1), undef, 'quiet does not carp');
	does_carp_that_matches(sub { $f->parse_datetime('Abt 1 Jan 2001') }, qr/invalid/);
	does_croak_that_matches(sub { $f->parse_datetime() }, qr/^Usage:/);
	does_croak_that_matches(sub { $f->parse_datetime(date => undef) }, qr/^Usage:/);
	does_carp_that_matches(sub { $f->parse_datetime({ date => '28 Jul 1914 - 11 Nov 1918' }) }, qr/Changing date/);
	does_carp_that_matches(sub { $f->parse_datetime({ date => '1517-05-04' }) }, qr/Changing date .+04 May 1517/);
	cmp_ok($f->parse_datetime({ date => '1517-05-04', strict => 0, quiet => 0 })->dmy, 'eq', '04-05-1517', 'Handle dashes in dates');
	does_carp_that_matches(sub { $f->parse_datetime(date => '12 June 2020', strict => 1) }, qr/^Unparseable date/);
	does_croak_that_matches(sub { my $rc = $f->parse_datetime(); }, qr/^Usage:/);
	does_carp_that_matches(sub { my $rc = $f->parse_datetime('xyzzy'); }, qr/does not parse/);
	does_carp_that_matches(sub { my $rc = $f->parse_datetime(date => 'xyzzy'); }, qr/does not parse/);
	does_carp_that_matches(sub { my $rc = $f->parse_datetime({ date => 'xyzzy' }); }, qr/does not parse/);
	does_carp_that_matches(sub { my $rc = $f->parse_datetime({ date => 'Zzz 55, 2020', strict => 1 }); }, qr/^Unparseable date/);
}
