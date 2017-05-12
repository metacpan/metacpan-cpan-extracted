#!/usr/bin/perl -w

use strict;

use Test::More tests => 61;

use DateTime;
use DateTime::Event::Recurrence;

# DAILY
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence ( hours => 10 );
    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-29T10:00:00', 'next daily' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-30T10:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:00:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-27T10:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:00:00', 'closest' );
    $dt = $dt->subtract( hours => 20 );  # 2003-04-28T14:00:00
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-04-27T10:00:00', 'closest' );
}

# WEEKLY
{
    #  mon tue wed thu fri sat sun
    #   14  15  16  17  18  19  20
    #   21  22  23  24  25  26  27
    #   28  29  30
    #   +0  +1  +2

    my $dt1 = new DateTime( year => 2003, month => 4, day => 18,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $weekly = weekly DateTime::Event::Recurrence( days => 3 ); # Wed
    my $dt;

    $dt = $weekly->next( $dt1 );
    is ( $dt->datetime, '2003-04-23T00:00:00', 'next weekly' );
    $dt = $weekly->next( $dt );
    is ( $dt->datetime, '2003-04-30T00:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->previous( $dt1 );
    is ( $dt->datetime, '2003-04-16T00:00:00', 'previous' );
    $dt = $weekly->previous( $dt );
    is ( $dt->datetime, '2003-04-09T00:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-18T12:10:45', 'immutable' );

    $dt = $weekly->closest( $dt1 );
    is ( $dt->datetime, '2003-04-16T00:00:00', 'closest' );
    $dt = $dt->add( days => 5 );  # 2003-04-21T00:00:00
    $dt = $weekly->closest( $dt );
    is ( $dt->datetime, '2003-04-23T00:00:00', 'closest' );
}


# WEEKLY with "duration"
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 18,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $weekly = weekly DateTime::Event::Recurrence( 
          days => 3 );

    #     duration => new DateTime::Duration( days => 2 ) ); # Wed

    my $dt;

    $dt = $weekly->next( $dt1 );
    is ( $dt->datetime, '2003-04-23T00:00:00', 'next syntax' );
}

# -- test 18

# DAILY, many occurrences
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence ( 
         hours => [ -1, 10, 14 ] );

    #    duration => [ [
    #        new DateTime::Duration( hours => -1 ),
    #        new DateTime::Duration( hours => 10 ),
    #        new DateTime::Duration( hours => 14 ),
    #     ] ] );

    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:00:00', 'next daily many' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T23:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-29T10:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-29T14:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:00:00', 'previous ' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-27T23:00:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-27T14:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:00:00', 'closest' );
    $dt = $dt->subtract( hours => 3 );  # 2003-04-28T11:00:00
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-04-28T10:00:00', 'closest' );
}

# DAILY, many many occurrences
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence ( 
        hours => [ -1, 10, 14 ] ,
        minutes => [ -15, 15, 30 ] );

        # duration => [ [
        #    new DateTime::Duration( hours => -1 ),  # 23h
        #    new DateTime::Duration( hours => 10 ),
        #    new DateTime::Duration( hours => 14 ), ],
        # [
        #    new DateTime::Duration( minutes => -15 ),  # 45min
        #    new DateTime::Duration( minutes => 15 ),
        #    new DateTime::Duration( minutes => 30 ),
        # ],
        # ] );

    # 10:15 10:30 10:45
    # 14:15 14:30 14:45
    # 23:15 23:30 23:45

    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:15:00', 'next daily many many' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T14:30:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T14:45:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T23:15:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:45:00', 'previous '.$dt->datetime );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-28T10:30:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-28T10:15:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );      # 12:10
    is ( $dt->datetime, '2003-04-28T10:45:00', 'closest' );
    $dt = $dt->subtract( hours => 3 );  # 09:10:00
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-04-28T10:15:00', 'closest' );
}



# DAILY, many many occurrences + syntax sugar
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence ( 
        hours => [ 10, 14, -1 ],
        minutes => [ 30, -15, 15 ] );

    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:15:00', 'next daily many many syntax' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T14:30:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T14:45:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-28T23:15:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:45:00', 'previous '.$dt->datetime );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-28T10:30:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2003-04-28T10:15:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );
    is ( $dt->datetime, '2003-04-28T10:45:00', 'closest' );
    $dt = $dt->subtract( hours => 3 );  # 2003-04-28T09:10:00
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-04-28T10:15:00', 'closest' );
}


# YEARLY, many occurrences + syntax sugar
{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = yearly DateTime::Event::Recurrence (
        months =>  [ 9, 11 ],
        days =>    [ 15 ],
        hours =>   [ 14 ] );

    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-09-15T14:00:00', 'next yearly many syntax' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-11-15T14:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2004-09-15T14:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2004-11-15T14:00:00', 'next' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->previous( $dt1 );
    is ( $dt->datetime, '2002-11-15T14:00:00', 'previous '.$dt->datetime );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2002-09-15T14:00:00', 'previous' );
    $dt = $daily->previous( $dt );
    is ( $dt->datetime, '2001-11-15T14:00:00', 'previous' );

    is ( $dt1->datetime, '2003-04-28T12:10:45', 'immutable' );

    $dt = $daily->closest( $dt1 );
    is ( $dt->datetime, '2003-09-15T14:00:00', 'closest' );
    $dt = $dt->add( months => 3 ); 
    $dt = $daily->closest( $dt );
    is ( $dt->datetime, '2003-11-15T14:00:00', 'closest' );
}

