#!perl -wT

use strict;
use warnings;
use Test::Most tests => 26;
use Test::NoWarnings;
use Test::Deep;

BEGIN {
	use_ok('DateTime::Format::Genealogy');
}

DATE: {
	my $f = new_ok('DateTime::Format::Genealogy');

	cmp_deeply($f->parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply($f->parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply($f->parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));
	cmp_deeply($f->parse_datetime({ date => 'Sep 29, 1939' }), methods('dmy' => '29-09-1939'));

	ok(!defined($f->parse_datetime(date => 'bet 28 Jul 1914 and 11 Nov 1919')));
	ok(!defined($f->parse_datetime({ date => '2022' })));

	my @dts = $f->parse_datetime({ date => 'bet 28 Jul 1914 and 11 Nov 1918' });

	ok(scalar(@dts) == 2);
	isa($dts[0], 'DateTime');
	ok($dts[0]->dmy() eq '28-07-1914');
	isa($dts[1], 'DateTime');
	ok($dts[1]->dmy() eq '11-11-1918');

	cmp_ok($f->parse_datetime('25 Dec 2022')->dmy(), 'eq', '25-12-2022', 'Basic test');
	ok(!defined($f->parse_datetime('20 Dec 20')));

	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy::parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy::parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime('29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime({ date => '27 sept 1791', strict => 0 }), methods('dmy' => '27-09-1791'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime({ date => '27 sept. 1791', strict => 0 }), methods('dmy' => '27-09-1791'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime(date => '29 Sep 1939'), methods('dmy' => '29-09-1939'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime({ date => '29 Sep 1939' }), methods('dmy' => '29-09-1939'));

	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('5 Jan 2019'), methods('dmy' => '05-01-2019'));
	cmp_deeply(DateTime::Format::Genealogy->parse_datetime('5 Jan 2019'), methods('dmy' => '05-01-2019'));

	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('12 June 2020'), methods('dmy' => '12-06-2020'));
	cmp_deeply(DateTime::Format::Genealogy::parse_datetime('21 Mai 1681'), methods('dmy' => '21-05-1681'));

	# cmp_deeply(DateTime::Format::Genealogy::parse_datetime({ date => '1637-10-17', quiet => 1}), methods('dmy' => '17-10-1637'));
}
