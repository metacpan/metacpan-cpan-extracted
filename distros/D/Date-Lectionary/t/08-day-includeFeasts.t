#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use Time::Piece;
use Date::Lectionary;
use Date::Lectionary::Day;

my $sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2017-08-06", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    $sunday->displayName,
    "The Transfiguration",
    'Validating that 2017-08-06 returns [The Transfiguration] for the ACNA.'
);

$sunday = Date::Lectionary::Day->new(
    'date'       => Time::Piece->strptime( "2017-08-06", "%Y-%m-%d" ),
    'lectionary' => 'acna', 
    'includeFeasts' => 'no'
);
is(
    $sunday->displayName,
    "Sunday Closest to August 3",
    'Validating that 2017-08-06 returns [Sunday Closest to August 3] for the ACNA.'
);