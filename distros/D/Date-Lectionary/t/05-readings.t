#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;

use Time::Piece;
use Date::Lectionary;

#Test ACNA readings
my $testReading = Date::Lectionary->new(
    'date' => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ) );
is(
    ${ $testReading->readings }[0],
    'Malachi 3:13-4:6',
'The first reading for the Sunday closest to November 16 in the default ACNA lectionary for year C should be Malachi 3:13-4:6.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    ${ $testReading->readings }[1],
    'Psalm 98',
'The second reading for the Sunday closest to November 16 in the ACNA lectionary for year C should be Psalm 98.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    ${ $testReading->readings }[2],
    '2 Thessalonians 3:6-16',
'The third reading for the Sunday closest to November 16 in the ACNA lectionary for year C should be 2 Thessalonians 3:6-16.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    ${ $testReading->readings }[3],
    'Luke 21:5-19',
'The fourth reading for the Sunday closest to November 16 in the ACNA lectionary for year C should be Luke 21:5-19.'
);

#Test RCL readings
$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    ${ $testReading->readings }[0],
    'Malachi 4:1-2a',
'The first reading for the Sunday closest to November 16 in the default RCL lectionary for year C should be Malachi 4:1-2a.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    ${ $testReading->readings }[1],
    'Psalm 98',
'The second reading for the Sunday closest to November 16 in the RCL lectionary for year C should be Psalm 98.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    ${ $testReading->readings }[2],
    '2 Thessalonians 3:6-13',
'The third reading for the Sunday closest to November 16 in the RCL lectionary for year C should be 2 Thessalonians 3:6-13.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-11-13", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);
is(
    ${ $testReading->readings }[3],
    'Luke 21:5-19',
'The fourth reading for the Sunday closest to November 16 in the RCL lectionary for year C should be Luke 21:5-19.'
);

$testReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2018-04-22", "%Y-%m-%d" ),
    'lectionary' => 'acna'
);
is(
    ${ $testReading->readings }[0],
    'Acts (4:23-31); 4:32-37 or Ezekiel 34:1-10',
'The first reading for the Fourth Sunday of Easter in the ACNA lectionary for year B should be Acts (4:23-31); 4:32-37 or Ezekiel 34:1-10'
);

#Testing readings on a day with multiple services; i.e. Christmas Day
my $multiReading = Date::Lectionary->new(
    'date'       => Time::Piece->strptime( "2016-12-25", "%Y-%m-%d" ),
    'lectionary' => 'rcl'
);

is( $multiReading->day->multiLect,
    'yes', 'Christmas Day should have multiple lectionary reading segments.' );

is(
    ${ $multiReading->readings }[0]{name},
    'Christmas, Proper I',
    'The first RCL lectionary for Christmas Day is Christmas, Proper I'
);

is(
    ${ $multiReading->readings }[1]{readings}[0],
    'Isaiah 62:6-12',
'The first reading for Christmas, Proper II in the RCL year A should be Isaiah 62:6-12.'
);
