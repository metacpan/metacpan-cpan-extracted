#!perl -T
use v5.22;

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Daily;

my $testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ), 'lectionary' => 'acna-xian' );
is(
    $testReading->readings->{morning}->{1},
    '-',
	'The first reading for morning prayer on 2017-12-24 should be -'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ), 'lectionary' => 'acna-xian' );
is(
    $testReading->readings->{morning}->{2},
    '-',
	'The second reading for morning prayer on 2017-12-24 should be -'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ), 'lectionary' => 'acna-xian' );
is(
    $testReading->readings->{evening}->{1},
    'Zechariah 2:10-end',
	'The first reading for evening prayer on 2017-12-24 should be Zechariah 2:10-end'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-12-24", "%Y-%m-%d" ), 'lectionary' => 'acna-xian' );
is(
    $testReading->readings->{evening}->{2},
    'Hebrews 2:10-18',
	'The second reading for evening prayer on 2017-12-24 should be Hebrews 2:10-18'
);