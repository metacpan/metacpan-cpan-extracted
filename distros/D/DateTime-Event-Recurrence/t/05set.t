#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;

use DateTime;
use DateTime::Event::Recurrence;

{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily_full = daily DateTime::Event::Recurrence ( 
        hours => [ 10, 14, -1 ],            # 10,14,23
        minutes => [ 30, -15, 15 ] );       # 15,30,45

    my $dt;

    # UNION

    my $dt_more = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 14, minute => 0, second => 0,
                           time_zone => 'UTC' );

    my $daily_join = $daily_full->union( $dt_more );

    $dt = $daily_join->next( $dt1 );
    #-- this datetime was added...
    is ( $dt->datetime, '2003-04-28T14:00:00', 'next union' );
    $dt = $daily_join->next( $dt );
    #--
    is ( $dt->datetime, '2003-04-28T14:15:00', 'next union' );
    $dt = $daily_join->next( $dt );
    
    is ( $dt->datetime, '2003-04-28T14:30:00', 'next union' );
    $dt = $daily_join->next( $dt );
    is ( $dt->datetime, '2003-04-28T14:45:00', 'next union' );

    # INTERSECTION

    my $dt_only = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 14, minute => 15, second => 0,
                           time_zone => 'UTC' );

    my $daily_selected = $daily_full->intersection( $dt_only );

    #-- this datetime was not selected...
    # $dt = $daily_selected->next( $dt1 );
    # is ( $dt->datetime, '2003-04-28T13:45:00', 'next intersection' );
    #--
    $dt = $daily_selected->next( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:15:00', 'next intersection' );
    #-- no more datetimes
    $dt = $daily_selected->next( $dt );
    is ( $dt, undef, 'no next intersection' );

    # COMPLEMENT

    my $dt_out = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 14, minute => 15, second => 0,
                           time_zone => 'UTC' );

    my $daily_except = $daily_full->complement( $dt_out );

    $dt = $daily_except->next( $dt1 );
    is ( $dt->datetime, '2003-04-28T14:30:00', 'next complement' );
    $dt = $daily_except->next( $dt );
    #-- this datetime was removed...
    # is ( $dt->datetime, '2003-04-28T14:15:00', 'next complement' );
    # $dt = $daily_except->next( $dt );
    #--
    is ( $dt->datetime, '2003-04-28T14:45:00', 'next complement' );
    $dt = $daily_except->next( $dt );
    is ( $dt->datetime, '2003-04-28T23:15:00', 'next complement' );

}

