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
    'lectionary' => 'acna'
);
is(
    $christmas->day->name,
    'Christmas Day',
    'Ensure that December 25, 2016 is Christmas Day'
);

my $ashWednesday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $ashWednesday->day->name,
    'Ash Wednesday',
    'Ensure that February 10, 2016 is Ash Wednesday'
);

my $easter = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $easter->day->name,
    'Easter Day', 'Ensure that March 27, 2016 is Easter Day' );

my $holySat = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $holySat->day->name,
    'Holy Saturday',
    'Ensure that March 26, 2016 is Holy Saturday'
);

my $easterTuesday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $easterTuesday->day->name,
    'Tuesday of Easter Week',
    'Ensure that March 29, 2016 is Tuesday of Easter Week'
);

my $ascension = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $ascension->day->name,
    'Ascension Day',
    'Ensure that May 05, 2016 is Ascension Day'
);

my $pentecost = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $pentecost->day->name,
    'Pentecost', 'Ensure that May 15, 2016 is Pentecost' );

my $st_luke = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $st_luke->day->name,
    'St. Luke', 'Ensure that October 10, 2016 is St. Luke' );

my $christTheKing = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $christTheKing->day->name,
    'Christ the King',
    'Ensure that November 20, 2016 is Christ the King'
);

my $regularDay = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $regularDay->day->name,
    'Saturday, November 19, 2016',
    'Ensure that November 19, 2016 is a day without readings or a name.'
);

##Validating all the Sundays of 2015, 2016, and 2017.

my $sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-04", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Christmas",
    'Validating that 2015-01-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-11", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday of Epiphany",
    'Validating that 2015-01-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Epiphany",
    'Validating that 2015-01-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Confession of St. Peter",
    'Validating that 2015-01-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Epiphany",
    'Validating that 2015-01-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-01-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Conversion of St. Paul",
    'Validating that 2015-01-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Epiphany",
    'Validating that 2015-02-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Epiphany",
    'Validating that 2015-02-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sixth Sunday of Epiphany",
    'Validating that 2015-02-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-02-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Lent",
    'Validating that 2015-02-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Lent",
    'Validating that 2015-03-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Lent",
    'Validating that 2015-03-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Lent",
    'Validating that 2015-03-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday in Lent",
    'Validating that 2015-03-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-03-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2015-03-29 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2015-04-05 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Easter",
    'Validating that 2015-04-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Easter",
    'Validating that 2015-04-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-04-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Easter",
    'Validating that 2015-04-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Easter",
    'Validating that 2015-05-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sixth Sunday of Easter",
    'Validating that 2015-05-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sunday after Ascension Day",
    'Validating that 2015-05-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Pentecost", 'Validating that 2015-05-24 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-05-31", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2015-05-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Visitation",
    'Validating that 2015-06-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-07", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 8",
    'Validating that 2015-06-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-14", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 15",
    'Validating that 2015-06-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-21", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 22",
    'Validating that 2015-06-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-06-28", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 29",
    'Validating that 2015-06-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 6",
    'Validating that 2015-07-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 13",
    'Validating that 2015-07-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 20",
    'Validating that 2015-07-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-07-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 27",
    'Validating that 2015-07-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-02", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 3",
    'Validating that 2015-08-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-09", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 10",
    'Validating that 2015-08-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-16", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 17",
    'Validating that 2015-08-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-23", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 24",
    'Validating that 2015-08-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-08-30", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 31",
    'Validating that 2015-08-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 7",
    'Validating that 2015-09-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 14",
    'Validating that 2015-09-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 21",
    'Validating that 2015-09-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-09-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 28",
    'Validating that 2015-09-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-04", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 5",
    'Validating that 2015-10-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-11", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 12",
    'Validating that 2015-10-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 19",
    'Validating that 2015-10-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "St. Luke", 'Validating that 2015-10-19 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-10-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 26",
    'Validating that 2015-10-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "All Saints' Day",
    'Validating that 2015-11-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 9",
    'Validating that 2015-11-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 16",
    'Validating that 2015-11-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2015-11-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-11-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Advent",
    'Validating that 2015-11-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Advent",
    'Validating that 2015-12-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Advent",
    'Validating that 2015-12-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Advent",
    'Validating that 2015-12-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday of Christmas",
    'Validating that 2015-12-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2015-12-28", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "St. John", 'Validating that 2015-12-28 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Christmas",
    'Validating that 2016-01-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday of Epiphany",
    'Validating that 2016-01-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Epiphany",
    'Validating that 2016-01-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Epiphany",
    'Validating that 2016-01-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-01-31", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Epiphany",
    'Validating that 2016-01-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-07", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Epiphany",
    'Validating that 2016-02-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-14", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Lent",
    'Validating that 2016-02-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-21", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Lent",
    'Validating that 2016-02-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-02-28", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Lent",
    'Validating that 2016-02-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Lent",
    'Validating that 2016-03-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday in Lent",
    'Validating that 2016-03-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2016-03-20 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-03-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2016-03-27 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Easter",
    'Validating that 2016-04-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Easter",
    'Validating that 2016-04-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Easter",
    'Validating that 2016-04-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-04-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Easter",
    'Validating that 2016-04-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sixth Sunday of Easter",
    'Validating that 2016-05-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-02", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "St. Philip & St. James",
    'Validating that 2016-05-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sunday after Ascension Day",
    'Validating that 2016-05-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Pentecost", 'Validating that 2016-05-15 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2016-05-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-05-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 1",
    'Validating that 2016-05-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 8",
    'Validating that 2016-06-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 15",
    'Validating that 2016-06-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 22",
    'Validating that 2016-06-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-06-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 29",
    'Validating that 2016-06-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 6",
    'Validating that 2016-07-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 13",
    'Validating that 2016-07-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 20",
    'Validating that 2016-07-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 27",
    'Validating that 2016-07-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-07-31", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 3",
    'Validating that 2016-07-31 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-07", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 10",
    'Validating that 2016-08-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-14", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 17",
    'Validating that 2016-08-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-21", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 24",
    'Validating that 2016-08-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-08-28", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 31",
    'Validating that 2016-08-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-04", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 7",
    'Validating that 2016-09-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-11", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 14",
    'Validating that 2016-09-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 21",
    'Validating that 2016-09-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-09-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 28",
    'Validating that 2016-09-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-02", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 5",
    'Validating that 2016-10-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-09", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 12",
    'Validating that 2016-10-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-16", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 19",
    'Validating that 2016-10-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-23", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 26",
    'Validating that 2016-10-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-10-30", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 2",
    'Validating that 2016-10-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 9",
    'Validating that 2016-11-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 16",
    'Validating that 2016-11-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2016-11-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Advent",
    'Validating that 2016-11-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-04", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Advent",
    'Validating that 2016-12-04 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-11", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Advent",
    'Validating that 2016-12-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Advent",
    'Validating that 2016-12-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Christmas Day",
    'Validating that 2016-12-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Holy Name", 'Validating that 2017-01-01 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday of Epiphany",
    'Validating that 2017-01-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Epiphany",
    'Validating that 2017-01-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Epiphany",
    'Validating that 2017-01-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-01-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Epiphany",
    'Validating that 2017-01-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Epiphany",
    'Validating that 2017-02-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sixth Sunday of Epiphany",
    'Validating that 2017-02-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Seventh Sunday of Epiphany",
    'Validating that 2017-02-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-02-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Last Sunday after Epiphany",
    'Validating that 2017-02-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Lent",
    'Validating that 2017-03-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Lent",
    'Validating that 2017-03-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Lent",
    'Validating that 2017-03-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "St. Joseph", 'Validating that 2017-03-20 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-03-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Lent",
    'Validating that 2017-03-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-02", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday in Lent",
    'Validating that 2017-04-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-09", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Palm Sunday", 'Validating that 2017-04-09 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-16", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Easter Day", 'Validating that 2017-04-16 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-23", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday of Easter",
    'Validating that 2017-04-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-04-30", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday of Easter",
    'Validating that 2017-04-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-07", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday of Easter",
    'Validating that 2017-05-07 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-14", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fifth Sunday of Easter",
    'Validating that 2017-05-14 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-21", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sixth Sunday of Easter",
    'Validating that 2017-05-21 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-05-28", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Sunday after Ascension Day",
    'Validating that 2017-05-28 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-04", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "Pentecost", 'Validating that 2017-06-04 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-11", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Trinity Sunday",
    'Validating that 2017-06-11 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is( $sunday->day->name,
    "St. Barnabas", 'Validating that 2017-06-12 returns the correct day.' );

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-18", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 15",
    'Validating that 2017-06-18 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-06-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 22",
    'Validating that 2017-06-25 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-02", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to June 29",
    'Validating that 2017-07-02 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-09", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 6",
    'Validating that 2017-07-09 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-16", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 13",
    'Validating that 2017-07-16 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-23", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 20",
    'Validating that 2017-07-23 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-07-30", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to July 27",
    'Validating that 2017-07-30 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Transfiguration",
    'Validating that 2017-08-06 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 10",
    'Validating that 2017-08-13 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-20", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 17",
    'Validating that 2017-08-20 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-08-27", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 24",
    'Validating that 2017-08-27 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to August 31",
    'Validating that 2017-09-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 7",
    'Validating that 2017-09-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 14",
    'Validating that 2017-09-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-09-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 21",
    'Validating that 2017-09-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to September 28",
    'Validating that 2017-10-01 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-08", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 5",
    'Validating that 2017-10-08 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-15", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 12",
    'Validating that 2017-10-15 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 19",
    'Validating that 2017-10-22 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-10-29", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to October 26",
    'Validating that 2017-10-29 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-05", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 2",
    'Validating that 2017-11-05 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 9",
    'Validating that 2017-11-12 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Sunday Closest to November 16",
    'Validating that 2017-11-19 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-11-26", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "Christ the King",
    'Validating that 2017-11-26 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-03", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday in Advent",
    'Validating that 2017-12-03 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-10", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Second Sunday in Advent",
    'Validating that 2017-12-10 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-17", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Third Sunday in Advent",
    'Validating that 2017-12-17 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The Fourth Sunday in Advent",
    'Validating that 2017-12-24 returns the correct day.'
);

$sunday = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2017-12-31", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->day->name,
    "The First Sunday of Christmas",
    'Validating that 2017-12-31 returns the correct day.'
);
