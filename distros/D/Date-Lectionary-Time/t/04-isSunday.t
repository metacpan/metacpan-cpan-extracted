#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests=>4;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Time qw(isSunday);

#Ensuring the closestSunday method exists.
can_ok('Date::Lectionary::Time', qw(isSunday));

#Testing for the first of the year.
is(
	isSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d")),
	0,
	'2016-01-01 is not a Sunday'
);

#Testing for a Sunday
is(
	isSunday(Time::Piece->strptime("2016-01-03", "%Y-%m-%d")),
	1,
	'2016-01-03 is a Sunday'
);

#Testing for a Sunday before the date
is(
	isSunday(Time::Piece->strptime("2016-08-09", "%Y-%m-%d")),
	0,
	'2016-08-09 is not a Sunday'
);
