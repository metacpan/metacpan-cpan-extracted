#!perl -wT

use strict;
use warnings;
use Test::Most tests => 18;
use Test::NoWarnings;
use Test::Deep;

BEGIN {
	use_ok('DateTime::Format::Genealogy');
}

DATA: {
	my $f = new_ok('DateTime::Format::Genealogy');

	cmp_deeply($f->parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply($f->parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply($f->parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));

	ok(!defined($f->parse_datetime(date => 'bet 28 Jul 1914 and 11 Nov 1919')));

	my @dts = $f->parse_datetime({ date => 'bet 28 Jul 1914 and 11 Nov 1918' });

	ok(scalar(@dts) == 2);
	isa($dts[0], 'DateTime');
	ok($dts[0]->dmy() eq '28-07-1914');
	isa($dts[1], 'DateTime');
	ok($dts[1]->dmy() eq '11-11-1918');

	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy::parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy::parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));

	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('5 Jan 2019'), methods('dmy' => '05-01-2019'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime('5 Jan 2019'), methods('dmy' => '05-01-2019'));
}
