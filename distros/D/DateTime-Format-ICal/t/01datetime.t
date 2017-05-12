#!/usr/bin/perl -w

use strict;

use Test::More tests => 37;

use DateTime::Format::ICal;

my $ical = 'DateTime::Format::ICal';

{
    my $dt = $ical->parse_datetime( '19920405T160708Z' );
    is( $dt->sec, 8, "second accessor read is correct" );
    is( $dt->minute, 7, "minute accessor read is correct" );
    is( $dt->hour, 16, "hour accessor read is correct" );
    is( $dt->day, 5, "day accessor read is correct" );
    is( $dt->month, 4, "month accessor read is correct" );
    is( $dt->year, 1992, "year accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '19920405T160708Z', 'output should match input' );
}

{
    my $dt = $ical->parse_datetime( '18700523T164702Z' );
    is( $dt->year, 1870, 'Pre-epoch year' );
    is( $dt->month, 5, 'Pre-epoch month' );
    is( $dt->sec, 2, 'Pre-epoch seconds' );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '18700523T164702Z', 'output should match input' );
}

{
    my $dt = $ical->parse_datetime( '23481016T041612Z' );
    is( $dt->year, 2348, "Post-epoch year" );
    is( $dt->day, 16, "Post-epoch day");
    is( $dt->hour, 04, "Post-epoch hour");

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '23481016T041612Z', 'output should match input' );
}

{
    my $dt = $ical->parse_datetime( '00241121Z' );
    is( $dt->year, 24, "date-only year" );
    is( $dt->month, 11, "date-only month");
    is( $dt->day, 21, "date-only day");

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '00241121T000000Z',
        'output should match input (except as a datetime)' );
}

{
    my $dt = $ical->parse_datetime( '00241121' );
    is( $dt->year, 24, "date-only year" );
    is( $dt->month, 11, "date-only month");
    is( $dt->day, 21, "date-only day");

    ok( $dt->time_zone->is_floating, 'should be floating time zone' );

    is( $ical->format_datetime($dt), '00241121T000000',
        'output should match input (except as a datetime)' );
}

{
    my $dt = $ical->parse_datetime( 'TZID=America/Chicago:00241121' );
    is( $dt->year, 24, "date-only year" );
    is( $dt->month, 11, "date-only month");
    is( $dt->day, 21, "date-only day");
    is( $dt->hour, 0, "date-only hour" );
    is( $dt->minute, 0, "date-only minute" );
    is( $dt->second, 0, "date-only second" );

    is( $dt->time_zone->name, 'America/Chicago', 'should be America/Chicago time zone' );

    is( $ical->format_datetime($dt), 'TZID=America/Chicago:00241121T000000',
        'output should match input (except as a datetime)' );
}

{
    my $dt = DateTime->new( year => 1900, hour => 15, time_zone => '-0100' );

    is( $ical->format_datetime($dt), '19000101T160000Z',
        'offset only time zone should be formatted as UTC' );
}
