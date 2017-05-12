#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests=>5;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Time qw(closestSunday);

#Ensuring the closestSunday method exists.
can_ok('Date::Lectionary::Time', qw(closestSunday));

#Ensuring that the closestSunday method returns a Time::Piece object
my $closestSundayTimePieceObject = closestSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d"));
isa_ok($closestSundayTimePieceObject, 'Time::Piece');

#Testing for the first of the year.
is(
	closestSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d")),
	Time::Piece->strptime("2016-01-03", "%Y-%m-%d"),
	'Sunday closest to 2016-01-01 is 2016-01-03'
);

#Testing for a Sunday
is(
	closestSunday(Time::Piece->strptime("2016-01-03", "%Y-%m-%d")),
	Time::Piece->strptime("2016-01-03", "%Y-%m-%d"),
	'Sunday closest to 2016-01-03 is 2016-01-03'
);

#Testing for a Sunday before the date being closest.
is(
	closestSunday(Time::Piece->strptime("2016-08-09", "%Y-%m-%d")),
	Time::Piece->strptime("2016-08-07", "%Y-%m-%d"),
	'Sunday closest to 2016-08-09 is 2016-08-07'
);
