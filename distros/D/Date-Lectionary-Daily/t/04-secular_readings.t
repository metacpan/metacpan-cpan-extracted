#!perl -T
use v5.22;

use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Daily;

my $testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-12-24", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{morning}->{1},
    'Wisdom 8',
    'The first reading for morning prayer on 2018- should be Wisdom 8'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-03-12", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{morning}->{2},
    'Matthew 19:16-20:16',
    'The second reading for morning prayer on 2018-03-12 should be Matthew 19:16-20:16'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-12-01", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{evening}->{1},
    'Isaiah 44',
    'The first reading for evening prayer on 2018-12-01 should be Isaiah 44'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-01-25", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{evening}->{2},
    '1 Corinthians 9',
    'The second reading for evening prayer on 2018-01-25 should be 1 Corinthians 9'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-07-20", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{morning}->{1},
    '1 Samuel 11',
    'The first reading for morning prayer on 2018-07-20 should be 1 Samuel 11'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-07-04", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{morning}->{2},
    '1 Corinthians 4:1-17',
    'The second reading for morning prayer on 2018-07-04 should be 1 Corinthians 4:1-17'
);

$testReading = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2018-12-25", "%Y-%m-%d" ),
    'lectionary' => 'acna-sec'
);
is(
    $testReading->readings->{evening}->{1},
    'Song of Songs 2',
    'The first reading for evening prayer on 2018-12-25 should be Song of Songs 2'
);
