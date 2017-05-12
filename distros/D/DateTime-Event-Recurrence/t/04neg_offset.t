#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;

use DateTime;
use DateTime::Event::Recurrence;

# MONTHLY
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    # last day of month
    my $monthly = monthly DateTime::Event::Recurrence ( days => -1 );
    my $dt;

    $dt = $monthly->next( $dt1 );
    is ( $dt->datetime, '2003-04-30T00:00:00', 'next' );
    $dt = $monthly->next( $dt );
    is ( $dt->datetime, '2003-05-31T00:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $monthly->previous( $dt1 );
    is ( $dt->datetime, '2003-03-31T00:00:00', 'previous' );
    $dt = $monthly->previous( $dt );
    is ( $dt->datetime, '2003-02-28T00:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $monthly->closest( $dt1 );
    is ( $dt->datetime, '2003-04-30T00:00:00', 'closest' );
    $dt = $dt->subtract( days => 20 );  # 2003-04-10T00:00:00
    $dt = $monthly->closest( $dt );
    is ( $dt->datetime, '2003-03-31T00:00:00', 'closest' );
}

# WEEKLY
{
    #  mon tue wed thu fri sat sun
    #   14  15  16  17  18  19  20
    #   21  22  23  24  25  26  27
    #   28  29  30
    #   +0  +1  +2      -3  -2  -1

    my $dt1 = new DateTime( year => 2003, month => 4, day => 18,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $weekly = weekly DateTime::Event::Recurrence( days => -2 ); # Sat
    my $dt;

    $dt = $weekly->next( $dt1 );
    is ( $dt->datetime, '2003-04-19T00:00:00', 'next' );
    $dt = $weekly->next( $dt );
    is ( $dt->datetime, '2003-04-26T00:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->previous( $dt1 );
    is ( $dt->datetime, '2003-04-12T00:00:00', 'previous' );
    $dt = $weekly->previous( $dt );
    is ( $dt->datetime, '2003-04-05T00:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->closest( $dt1 );
    is ( $dt->datetime, '2003-04-19T00:00:00', 'closest' );
    $dt = $dt->subtract( days => 5 );  # 2003-04-14T00:00:00
    $dt = $weekly->closest( $dt );
    is ( $dt->datetime, '2003-04-12T00:00:00', 'closest' );
}

