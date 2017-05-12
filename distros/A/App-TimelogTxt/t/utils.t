#!/usr/bin/perl

use Test::Most tests => 65;
use Test::NoWarnings;

use strict;
use warnings;

use Time::Local;
use App::TimelogTxt::Utils;

is( App::TimelogTxt::Utils::TODAY(), 'today', 'Verify today constant' );
is( App::TimelogTxt::Utils::STOP_CMD(), 'stop', 'Verify stop command constant' );

ok( App::TimelogTxt::Utils::is_stop_cmd( App::TimelogTxt::Utils::STOP_CMD() ), 'Verify stop command check.' );
ok( !App::TimelogTxt::Utils::is_stop_cmd( 'zyzzy' ), 'Non-stop command recognized' );

ok( App::TimelogTxt::Utils::has_project( '+Project @Task Detail' ), 'Project test' );
ok( !App::TimelogTxt::Utils::has_project( 'Project @Task Detail' ), 'Missing project' );
ok( !App::TimelogTxt::Utils::has_project( 'Project+ @Task Detail' ), '+ not at the beginning' );

ok( App::TimelogTxt::Utils::is_today( 'today' ), 'Today check succeeds' );
ok( App::TimelogTxt::Utils::is_today( '' ), 'Today check of none succeeds' );
ok( !App::TimelogTxt::Utils::is_today( 'yesterday' ), 'Today check of yesterday does not succeed' );

is( App::TimelogTxt::Utils::day_end( '2013-06-30' ), '2013-07-01', 'Day end is tomorrow' );

# Monkey motion to remove problems with different local times
is_deeply( App::TimelogTxt::Utils::stamp_to_localtime( '2013-06-30' ),
    Time::Local::timelocal( 59, 59, 23, 30, 5, 113 ),
    'Timestamp converted to correct time'
);

my @valid_stamps = (
    [ '2013-06-30', 'valid date with -s' ],
    [ '2013/06/30', 'valid date with /s' ],
    [ '0000-06-30', '4 digit unlikely year 0s' ],
    [ '9999-06-30', '4 digit unlikely year 9s' ],
    [ '2013-01-30', 'january' ],
    [ '2013-12-30', 'december' ],
    [ '2013-12-01', 'lowest day number' ],
    [ '2013-12-31', 'highest day number' ],
);

foreach my $s (@valid_stamps)
{
    ok( App::TimelogTxt::Utils::is_datestamp( $s->[0] ), "$s->[1] is a valid stamp" );
}

my @invalid_stamps = (
    [ '2013-06-30 12:00:00', 'trailing data' ],
    [ ' 2013-06-30', 'leading data' ],
    [ '2013:06:30', 'wrong separators' ],
    [ '13-06-30',   '2 digit year' ],
    [ '2013-6-30',  '1 digit month' ],
    [ '2013-06-3',  '1 digit day' ],
    [ '2013-00-30', '0 month' ],
    [ '2013-13-01', '13 month' ],
    [ '2013-12-00', '0 day' ],
    [ '2013-12-32', '32 day' ],
);

foreach my $s (@invalid_stamps)
{
    ok( !App::TimelogTxt::Utils::is_datestamp( $s->[0] ), "$s->[1] is an invalid stamp" );
}

is( App::TimelogTxt::Utils::canonical_datestamp( '2013/06/30' ), '2013-06-30', 'Canonicalized datestamp' );

my @days = (
    [ 'sunday',    0 ],
    [ 'monday',    1 ],
    [ 'tuesday',   2 ],
    [ 'wednesday', 3 ],
    [ 'thursday',  4 ],
    [ 'friday',    5 ],
    [ 'saturday',  6 ],
    [ 'SUNDAY',    0 ],
    [ 'MONDAY',    1 ],
    [ 'TUESDAY',   2 ],
    [ 'WEDNESDAY', 3 ],
    [ 'THURSDAY',  4 ],
    [ 'FRIDAY',    5 ],
    [ 'SATURDAY',  6 ],
);

foreach my $dt (@days)
{
    is( App::TimelogTxt::Utils::day_num_from_name( $dt->[0] ), $dt->[1], "$dt->[0] converted correctly" );
}

my $DATE_RE = qr<\A[0-9]{4}-[01][0-9]-[0-3][0-9]\z>;

foreach my $day ('', qw/today yesterday YESTERDAY/, '2013-06-30', map { $_->[0] } @days )
{
    like( App::TimelogTxt::Utils::day_stamp( $day ), $DATE_RE, "'$day' converted" );
}
