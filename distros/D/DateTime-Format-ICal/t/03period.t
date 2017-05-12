#!/usr/bin/perl -w

use strict;

use Test::More tests => 21;

use DateTime::Format::ICal;
use DateTime::Span;

my $ical = 'DateTime::Format::ICal';

{
    my $span = $ical->parse_period( '19920405T160708Z/19930405T160708Z' );
    my $dt = $span->start;
    is( $dt->sec, 8, "second accessor read is correct" );
    is( $dt->minute, 7, "minute accessor read is correct" );
    is( $dt->hour, 16, "hour accessor read is correct" );
    is( $dt->day, 5, "day accessor read is correct" );
    is( $dt->month, 4, "month accessor read is correct" );
    is( $dt->year, 1992, "year accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '19920405T160708Z', 'output should match input' );


    $dt = $span->end;
    is( $dt->sec, 8, "second accessor read is correct" );
    is( $dt->minute, 7, "minute accessor read is correct" );
    is( $dt->hour, 16, "hour accessor read is correct" );
    is( $dt->day, 5, "day accessor read is correct" );
    is( $dt->month, 4, "month accessor read is correct" );
    is( $dt->year, 1993, "year accessor read is correct" );

    is( $dt->time_zone->name, 'UTC', 'time zone should be UTC' );

    is( $ical->format_datetime($dt), '19930405T160708Z', 'output should match input' );

    my $str = $ical->format_period( $span );
    is( $str, '19920405T160708Z/19930405T160708Z', 'period as datetimes' );

    $str = $ical->format_period_with_duration( $span );
    # weird result, but looks correct
    is( $str, '19920405T160708Z/+PT31536001S', 'period as datetime and duration' );

    $span = $ical->parse_period( $str );
    is( $ical->format_period( $span ), '19920405T160708Z/19930405T160708Z', 'period as datetimes' );
}

{
    my $span = $ical->parse_period( 'TZID=America/Chicago:00241121/+P2D' );
    is( $ical->format_period( $span ),
        'TZID=America/Chicago:00241121T000000/TZID=America/Chicago:00241123T000000',
        'period as datetimes' );
    is( $ical->format_period_with_duration( $span ),
        'TZID=America/Chicago:00241121T000000/+PT172800S',
        'period as datetime and duration' );

}

