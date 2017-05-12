#!perl

use Test::More tests => 12;

BEGIN {
	use lib "../lib";
	use_ok( 'Date::Holidays::UK::EnglandAndWales' );
}

for my $year (2004 .. 2014){
	is(
		Date::Holidays::UK::EnglandAndWales->is_holiday($year,12,25),
		"Christmas Day",
		'Christmas'
	);
}
