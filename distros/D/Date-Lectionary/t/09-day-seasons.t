#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

use Time::Piece;
use Date::Lectionary;
use Date::Lectionary::Day;

my $sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-12-25", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Christmas',
    '12/25/2020 is Christmas Day and should be in the season of Christmas'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-04-12", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Easter',
    '4/12/2020 is Easter Day and should be in the season of Easter'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-04-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Easter',
    '4/13/2020 is Easter Monday and should be in the season of Easter'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2019-04-19", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Lent',
    '4/19/2019 is Good Friday and should be in the season of Lent'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2018-07-01", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Ordinary',
    '7/1/2018 should be in Ordinary time'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-01-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'Epiphany',
    '1/6/202 is Epiphany and should be in the season of Epiphany'
);

#These dates will presently report NaN for the season until the method is updated to do calculations for days other than Sunday and major holy days

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-12-24", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'NaN',
    '12/24/2020 is Christmas Eve and should be in the season of Advent'
);


$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2020-01-07", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->season,
    'NaN',
    '1/7/2020 should be in Ordinary time'
);