#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;

use DateTime;
use DateTime::Event::Recurrence;

# DAILY
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence;
    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-29T00:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-30T00:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2003-04-28T00:00:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-27T00:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );
    is ( $dt->datetime, '2003-04-29T00:00:00', 'closest' );
    $dt = $dt->subtract( hours => 14 );  # 2003-04-28T10:00:00
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-04-28T00:00:00', 'closest' );
}

# WEEKLY
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 18,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $weekly = weekly DateTime::Event::Recurrence;
    my $dt;

    $dt = $weekly->next( $dt1 );
    is ( $dt->datetime, '2003-04-21T00:00:00', 'next' );
    $dt = $weekly->next( $dt );
    is ( $dt->datetime, '2003-04-28T00:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->previous( $dt1 );
    is ( $dt->datetime, '2003-04-14T00:00:00', 'previous' );
    $dt = $weekly->previous( $dt );
    is ( $dt->datetime, '2003-04-07T00:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->closest( $dt1 );
    is ( $dt->datetime, '2003-04-21T00:00:00', 'closest' );
    $dt = $dt->subtract( days => 5 );  # 2003-04-17T00:00:00
    $dt = $weekly->closest( $dt );
    is ( $dt->datetime, '2003-04-14T00:00:00', 'closest' );
}

