#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use Time::Piece;
use Date::Lectionary::Daily;

my $testWeek = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-03-11", "%Y-%m-%d" ) );
is(
    $testWeek->week,
    'The First Sunday in Lent',
	'Ensuring that 2017-03-11 is of the week of the First Sunday in Lent'
);

$testWeek = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-03-12", "%Y-%m-%d" ) );
is(
    $testWeek->week,
    'The Second Sunday in Lent',
	'Ensuring that 2017-03-12 is of the week of the Second Sunday in Lent'
);


$testWeek = Date::Lectionary::Daily->new(
    'date' => Time::Piece->strptime( "2017-03-13", "%Y-%m-%d" ) );
is(
    $testWeek->week,
    'The Second Sunday in Lent',
	'Ensuring that 2017-03-13 is of the week of the Second Sunday in Lent'
);