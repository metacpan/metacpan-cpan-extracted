#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests=>8;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Time qw(prevSunday);

#Ensuring the prevSunday method exists.
can_ok('Date::Lectionary::Time', qw(prevSunday));

#Ensuring that the prevSunday method returns a Time::Piece object
my $prevSundayTimePieceObject = prevSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d"));
isa_ok($prevSundayTimePieceObject, 'Time::Piece');

#Testing for the first of the year.
is(
	prevSunday(Time::Piece->strptime("2016-01-01", "%Y-%m-%d")),
	Time::Piece->strptime("2015-12-27", "%Y-%m-%d"),
	'Sunday previous to 2016-01-01 is 2015-12-27'
);

#Testing for giving a date that is already a Sunday
is(
	prevSunday(Time::Piece->strptime("2015-12-27", "%Y-%m-%d")),
	Time::Piece->strptime("2015-12-20", "%Y-%m-%d"),
	'Sunday previous to 2015-12-27 is 2015-12-20'
);

#Testing for a date far in the future
is(
	prevSunday(Time::Piece->strptime("3098-12-01", "%Y-%m-%d")),
	Time::Piece->strptime("3098-11-27", "%Y-%m-%d"),
	'Sunday previous 3098-12-01 is 3098-11-27'
);

#Testing for a leap day
is(
	prevSunday(Time::Piece->strptime("2016-02-29", "%Y-%m-%d")),
	Time::Piece->strptime("2016-02-28", "%Y-%m-%d"),
	'Sunday previous to 2016-02-29 is 2016-02-28'
);

#Testing for a non-Time::Piece input argument
throws_ok (
	sub{prevSunday('2016-01-01')}, 
	qr/Method \[prevSunday\] expects an input argument of type Time::Piece\./, 
	'String input argument given instead of Time::Piece'
);

#Testing for an undefined input argument
throws_ok (
	sub{prevSunday(undef)}, 
	qr/Method \[prevSunday\] expects an input argument of type Time::Piece\.  The given type could not be determined\./, 
	'Undefined input argument given instead of Time::Piece'
);