#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 175;
use Test::Exception;

use Time::Piece;
use Date::Lectionary;

my $christmas = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $christmas->day->name,
    'Christmas Day',
    'Ensure that December 25, 2016 is Christmas Day'
);

my $ashWednesday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $ashWednesday->day->name,
    'Ash Wednesday',
    'Ensure that February 10, 2016 is Ash Wednesday'
);

my $easter = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $easter->day->name,
    'Easter Day', 'Ensure that March 27, 2016 is Easter Day' );

my $holySat = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $holySat->day->name,
    'Holy Saturday',
    'Ensure that March 26, 2016 is Holy Saturday'
);

my $easterTuesday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $easterTuesday->day->name,
    'Tuesday of Easter Week',
    'Ensure that March 29, 2016 is Tuesday of Easter Week'
);

my $ascension = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $ascension->day->name,
    'Ascension of the Lord',
    'Ensure that May 05, 2016 is Ascension of the Lord'
);

my $pentecost = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $pentecost->day->name,
    'Day of Pentecost',
    'Ensure that May 15, 2016 is Day of Pentecost'
);

my $st_luke = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $st_luke->day->name,
    'Tuesday, October 18, 2016',
    'Ensure that October 18, 2016 is not St. Luke for the RCL'
);

my $christTheKing = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $christTheKing->day->name,
    'Christ the King',
    'Ensure that November 20, 2016 is Christ the King'
);

my $regularDay = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $regularDay->day->name,
    'Saturday, November 19, 2016',
    'Ensure that November 19, 2016 is a day without readings or a name.'
);

##Validating all the Sundays of 2015, 2016, and 2017.

my $sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-04", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday after Christmas Day",
    'Validating that 2015-01-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-11", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Baptism of the Lord",
    'Validating that 2015-01-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday after the Epiphany",
    'Validating that 2015-01-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, January 19, 2015",
    'Validating that 2015-01-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday after the Epiphany",
    'Validating that 2015-01-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, January 26, 2015",
    'Validating that 2015-01-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday after the Epiphany",
    'Validating that 2015-02-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday after the Epiphany",
    'Validating that 2015-02-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sixth Sunday after the Epiphany",
    'Validating that 2015-02-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday in Lent",
    'Validating that 2015-02-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday in Lent",
    'Validating that 2015-03-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday in Lent",
    'Validating that 2015-03-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday in Lent",
    'Validating that 2015-03-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday in Lent",
    'Validating that 2015-03-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2015-03-29 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2015-04-05 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Easter",
    'Validating that 2015-04-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Easter",
    'Validating that 2015-04-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Easter",
    'Validating that 2015-04-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday of Easter",
    'Validating that 2015-05-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sixth Sunday of Easter",
    'Validating that 2015-05-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Seventh Sunday of Easter",
    'Validating that 2015-05-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Day of Pentecost",
    'Validating that 2015-05-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-31", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2015-05-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "The Visitation",
    'Validating that 2015-06-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-07", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 5 and June 11 inclusive",
    'Validating that 2015-06-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-14", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 12 and June 18 inclusive",
    'Validating that 2015-06-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-21", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 19 and June 25 inclusive",
    'Validating that 2015-06-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-28", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 26 and July 2 inclusive",
    'Validating that 2015-06-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 3 and July 9 inclusive",
    'Validating that 2015-07-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 10 and July 16 inclusive",
    'Validating that 2015-07-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 17 and July 23 inclusive",
    'Validating that 2015-07-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 24 and July 30 inclusive",
    'Validating that 2015-07-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-02", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 31 and August 6 inclusive",
    'Validating that 2015-08-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-09", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 7 and August 13 inclusive",
    'Validating that 2015-08-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-16", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 14 and August 20 inclusive",
    'Validating that 2015-08-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-23", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 21 and August 27 inclusive",
    'Validating that 2015-08-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-30", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 28 and September 3 inclusive",
    'Validating that 2015-08-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-06", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 4 and September 10 inclusive",
    'Validating that 2015-09-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 11 and September 17 inclusive",
    'Validating that 2015-09-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 18 and September 24 inclusive",
    'Validating that 2015-09-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 25 and October 1 inclusive",
    'Validating that 2015-09-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-04", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 2 and October 8 inclusive",
    'Validating that 2015-10-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-11", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 9 and October 15 inclusive",
    'Validating that 2015-10-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 16 and October 22 inclusive",
    'Validating that 2015-10-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, October 19, 2015",
    'Validating that 2015-10-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 23 and October 29 inclusive",
    'Validating that 2015-10-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name, "All Saints",
    'Validating that 2015-11-01 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 6 and November 12 inclusive",
    'Validating that 2015-11-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 13 and November 19 inclusive",
    'Validating that 2015-11-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2015-11-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday of Advent",
    'Validating that 2015-11-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-06", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Advent",
    'Validating that 2015-12-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Advent",
    'Validating that 2015-12-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Advent",
    'Validating that 2015-12-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday after Christmas Day",
    'Validating that 2015-12-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-28", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, December 28, 2015",
    'Validating that 2015-12-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday after Christmas Day",
    'Validating that 2016-01-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Baptism of the Lord",
    'Validating that 2016-01-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday after the Epiphany",
    'Validating that 2016-01-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday after the Epiphany",
    'Validating that 2016-01-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-31", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday after the Epiphany",
    'Validating that 2016-01-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-07", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday after the Epiphany",
    'Validating that 2016-02-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-14", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday in Lent",
    'Validating that 2016-02-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-21", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday in Lent",
    'Validating that 2016-02-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-28", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday in Lent",
    'Validating that 2016-02-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-06", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday in Lent",
    'Validating that 2016-03-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday in Lent",
    'Validating that 2016-03-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2016-03-20 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2016-03-27 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Easter",
    'Validating that 2016-04-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Easter",
    'Validating that 2016-04-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Easter",
    'Validating that 2016-04-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday of Easter",
    'Validating that 2016-04-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sixth Sunday of Easter",
    'Validating that 2016-05-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-02", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, May 2, 2016",
    'Validating that 2016-05-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Seventh Sunday of Easter",
    'Validating that 2016-05-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Day of Pentecost",
    'Validating that 2016-05-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2016-05-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between May 29 and June 4 inclusive",
    'Validating that 2016-05-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 5 and June 11 inclusive",
    'Validating that 2016-06-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 12 and June 18 inclusive",
    'Validating that 2016-06-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 19 and June 25 inclusive",
    'Validating that 2016-06-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 26 and July 2 inclusive",
    'Validating that 2016-06-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 3 and July 9 inclusive",
    'Validating that 2016-07-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 10 and July 16 inclusive",
    'Validating that 2016-07-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 17 and July 23 inclusive",
    'Validating that 2016-07-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 24 and July 30 inclusive",
    'Validating that 2016-07-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-31", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 31 and August 6 inclusive",
    'Validating that 2016-07-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-07", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 7 and August 13 inclusive",
    'Validating that 2016-08-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-14", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 14 and August 20 inclusive",
    'Validating that 2016-08-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-21", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 21 and August 27 inclusive",
    'Validating that 2016-08-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-28", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 28 and September 3 inclusive",
    'Validating that 2016-08-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-04", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 4 and September 10 inclusive",
    'Validating that 2016-09-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-11", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 11 and September 17 inclusive",
    'Validating that 2016-09-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 18 and September 24 inclusive",
    'Validating that 2016-09-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 25 and October 1 inclusive",
    'Validating that 2016-09-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-02", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 2 and October 8 inclusive",
    'Validating that 2016-10-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-09", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 9 and October 15 inclusive",
    'Validating that 2016-10-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-16", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 16 and October 22 inclusive",
    'Validating that 2016-10-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-23", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 23 and October 29 inclusive",
    'Validating that 2016-10-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-30", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 30 and November 5 inclusive",
    'Validating that 2016-10-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-06", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 6 and November 12 inclusive",
    'Validating that 2016-11-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 13 and November 19 inclusive",
    'Validating that 2016-11-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2016-11-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday of Advent",
    'Validating that 2016-11-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-04", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Advent",
    'Validating that 2016-12-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-11", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Advent",
    'Validating that 2016-12-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Advent",
    'Validating that 2016-12-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Christmas Day",
    'Validating that 2016-12-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Holy Name of Jesus",
    'Validating that 2017-01-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Baptism of the Lord",
    'Validating that 2017-01-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday after the Epiphany",
    'Validating that 2017-01-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday after the Epiphany",
    'Validating that 2017-01-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday after the Epiphany",
    'Validating that 2017-01-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday after the Epiphany",
    'Validating that 2017-02-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sixth Sunday after the Epiphany",
    'Validating that 2017-02-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Seventh Sunday after the Epiphany",
    'Validating that 2017-02-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Last Sunday after the Epiphany",
    'Validating that 2017-02-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday in Lent",
    'Validating that 2017-03-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday in Lent",
    'Validating that 2017-03-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday in Lent",
    'Validating that 2017-03-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, March 20, 2017",
    'Validating that 2017-03-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday in Lent",
    'Validating that 2017-03-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-02", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday in Lent",
    'Validating that 2017-04-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-09", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2017-04-09 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-16", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2017-04-16 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-23", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Easter",
    'Validating that 2017-04-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-30", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Easter",
    'Validating that 2017-04-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-07", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Easter",
    'Validating that 2017-05-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-14", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fifth Sunday of Easter",
    'Validating that 2017-05-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-21", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sixth Sunday of Easter",
    'Validating that 2017-05-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-28", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Seventh Sunday of Easter",
    'Validating that 2017-05-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-04", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Day of Pentecost",
    'Validating that 2017-06-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-11", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2017-06-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Monday, June 12, 2017",
    'Validating that 2017-06-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-18", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 12 and June 18 inclusive",
    'Validating that 2017-06-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 19 and June 25 inclusive",
    'Validating that 2017-06-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-02", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between June 26 and July 2 inclusive",
    'Validating that 2017-07-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-09", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 3 and July 9 inclusive",
    'Validating that 2017-07-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-16", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 10 and July 16 inclusive",
    'Validating that 2017-07-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-23", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 17 and July 23 inclusive",
    'Validating that 2017-07-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-30", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 24 and July 30 inclusive",
    'Validating that 2017-07-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-06", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between July 31 and August 6 inclusive",
    'Validating that 2017-08-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 7 and August 13 inclusive",
    'Validating that 2017-08-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-20", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 14 and August 20 inclusive",
    'Validating that 2017-08-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-27", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 21 and August 27 inclusive",
    'Validating that 2017-08-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between August 28 and September 3 inclusive",
    'Validating that 2017-09-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 4 and September 10 inclusive",
    'Validating that 2017-09-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 11 and September 17 inclusive",
    'Validating that 2017-09-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 18 and September 24 inclusive",
    'Validating that 2017-09-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-01", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between September 25 and October 1 inclusive",
    'Validating that 2017-10-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-08", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 2 and October 8 inclusive",
    'Validating that 2017-10-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-15", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 9 and October 15 inclusive",
    'Validating that 2017-10-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-22", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 16 and October 22 inclusive",
    'Validating that 2017-10-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-29", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 23 and October 29 inclusive",
    'Validating that 2017-10-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-05", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between October 30 and November 5 inclusive",
    'Validating that 2017-11-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-12", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 6 and November 12 inclusive",
    'Validating that 2017-11-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-19", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Sunday between November 13 and November 19 inclusive",
    'Validating that 2017-11-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-26", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2017-11-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-03", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday of Advent",
    'Validating that 2017-12-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-10", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Second Sunday of Advent",
    'Validating that 2017-12-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-17", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Third Sunday of Advent",
    'Validating that 2017-12-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "Fourth Sunday of Advent",
    'Validating that 2017-12-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-31", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    $sunday->day->name,
    "First Sunday after Christmas Day",
    'Validating that 2017-12-31 returns the correct day.'
);
