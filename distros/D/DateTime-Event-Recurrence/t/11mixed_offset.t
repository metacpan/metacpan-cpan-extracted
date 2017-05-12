#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use DateTime;
use DateTime::Event::Recurrence;

{
    # intermixed neg/pos args

    my $dt1 = new DateTime( year => 2003, month => 4, day => 30,
                           hour => 1, minute => 2, second => 3,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $daily = daily DateTime::Event::Recurrence ( 
            hours => [ 10, 10, 20, -10, -10, -20 ]
        );
    my $dt;

    $dt = $daily->next( $dt1 );
    is ( $dt->datetime, '2003-04-30T04:00:00', 'next daily' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-30T10:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-30T14:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-04-30T20:00:00', 'next' );
    $dt = $daily->next( $dt );
    is ( $dt->datetime, '2003-05-01T04:00:00', 'next' );
}

