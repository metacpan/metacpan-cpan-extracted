#!perl -wT

use strict;
use warnings;
use Test::Most tests => 9;
use Test::NoWarnings;

BEGIN {
	use_ok('DateTime::Format::Genealogy');
}

DATA: {
	my $f = new_ok('DateTime::Format::Genealogy');

	my $dt = $f->parse_datetime('29 Sep 1939');

	ok(defined($dt));
	isa($dt, 'DateTime');
	ok($dt->dmy() eq '29-09-1939');

	$dt = $f->parse_datetime(date => 'bet 28 Jul 1914 and 11 Nov 1919');

	ok(!defined($dt));

	my @dts = $f->parse_datetime({ date => 'bet 28 Jul 1914 and 11 Nov 1918' });

	ok(scalar(@dts) == 2);
	isa($dts[0], 'DateTime');
	ok($dts[0]->dmy() eq '28-07-1914');
	isa($dts[1], 'DateTime');
	ok($dts[1]->dmy() eq '11-11-1918');
}
