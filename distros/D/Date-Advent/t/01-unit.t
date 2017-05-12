#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 10;

use Time::Piece;
use Date::Advent;

#Test dates for January 1, 2016
my $testAdvent =
  Date::Advent->new(
    date => Time::Piece->strptime( "2016-01-01", "%Y-%m-%d" ) );

is(
    $testAdvent->firstSunday,
    Time::Piece->strptime( "2015-11-29", "%Y-%m-%d" ),
    'First Sunday of Advent for 2016-01-01'
);

is(
    $testAdvent->secondSunday,
    Time::Piece->strptime( "2015-12-06", "%Y-%m-%d" ),
    'Second Sunday of Advent for 2016-01-01'
);

is(
    $testAdvent->thirdSunday,
    Time::Piece->strptime( "2015-12-13", "%Y-%m-%d" ),
    'Third Sunday of Advent for 2016-01-01'
);

is(
    $testAdvent->fourthSunday,
    Time::Piece->strptime( "2015-12-20", "%Y-%m-%d" ),
    'Fourth Sunday of Advent for 2016-01-01'
);

#Test dates for December 12, 2009
$testAdvent =
  Date::Advent->new(
    date => Time::Piece->strptime( "2009-12-12", "%Y-%m-%d" ) );

is(
    $testAdvent->firstSunday,
    Time::Piece->strptime( "2009-11-29", "%Y-%m-%d" ),
    'First Sunday of Advent for 2009-12-12'
);

is(
    $testAdvent->secondSunday,
    Time::Piece->strptime( "2009-12-06", "%Y-%m-%d" ),
    'Second Sunday of Advent for 2009-12-12'
);

is(
    $testAdvent->thirdSunday,
    Time::Piece->strptime( "2009-12-13", "%Y-%m-%d" ),
    'Third Sunday of Advent for 2009-12-12'
);

is(
    $testAdvent->fourthSunday,
    Time::Piece->strptime( "2009-12-20", "%Y-%m-%d" ),
    'Fourth Sunday of Advent for 2009-12-12'
);

#Test a day that is one day before Advent
$testAdvent =
  Date::Advent->new(
    date => Time::Piece->strptime( "2015-11-28", "%Y-%m-%d" ) );

is(
    $testAdvent->firstSunday,
    Time::Piece->strptime( "2014-11-30", "%Y-%m-%d" ),
    'First Sunday of Advent for 2015-11-28'
);

#Test a day that is two days before Advent
$testAdvent =
  Date::Advent->new(
    date => Time::Piece->strptime( "2015-11-27", "%Y-%m-%d" ) );

is(
    $testAdvent->firstSunday,
    Time::Piece->strptime( "2014-11-30", "%Y-%m-%d" ),
    'First Sunday of Advent for 2015-11-27'
);
