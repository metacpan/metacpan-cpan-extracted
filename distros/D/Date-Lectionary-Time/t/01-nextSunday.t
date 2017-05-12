#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests=>8;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Time qw(nextSunday);

#Ensuring the nextSunday method exists.
can_ok('Date::Lectionary::Time', qw(nextSunday));

#Ensuring that the nextSunday method returns a Time::Piece object
my $nextSundayTimePieceObject = nextSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d"));
isa_ok($nextSundayTimePieceObject, 'Time::Piece');

#Testing for the first of the year.
is(
	nextSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d")),
	Time::Piece->strptime("2016-01-03", "%Y-%m-%d"),
	'Next Sunday after 2016-01-01 is 2016-01-03'
);

#Testing for giving a date that is already a Sunday
is(
	nextSunday(Time::Piece->strptime("2016-01-03", "%Y-%m-%d")),
	Time::Piece->strptime("2016-01-10", "%Y-%m-%d"),
	'Next Sunday after 2016-01-03 is 2016-01-10'
);

#Testing for a date far in the future
is(
	nextSunday(Time::Piece->strptime("3098-12-01", "%Y-%m-%d")),
	Time::Piece->strptime("3098-12-04", "%Y-%m-%d"),
	'Next Sunday after 3098-12-01 is 3098-12-04'
);

#Testing for a leap day
is(
	nextSunday(Time::Piece->strptime("2016-02-29", "%Y-%m-%d")),
	Time::Piece->strptime("2016-03-06", "%Y-%m-%d"),
	'Next Sunday after 2016-02-29 is 2016-03-06'
);

#Testing for a non-Time::Piece input argument
throws_ok (
	sub{nextSunday('2016-01-01')}, 
	qr/Method \[nextSunday\] expects an input argument of type Time::Piece\./, 
	'String input argument given instead of Time::Piece'
);

#Testing for an undefined input argument
throws_ok (
	sub{nextSunday(undef)}, 
	qr/Method \[nextSunday\] expects an input argument of type Time::Piece\.  The given type could not be determined\./, 
	'Undefined input argument given instead of Time::Piece'
);