#!/bin/perl -w

use strict;

use Test::More tests => 1;

use DateTime;
use DateTime::Event::ICal;

{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           # nanosecond => 123456,
                           time_zone => 'UTC' );

    my $dt2 = new DateTime( year => 2003, month => 5, day => 01,
                           hour => 12, minute => 10, second => 45,
                           # nanosecond => 123456,
                           time_zone => 'UTC' );

    my ( $set, @dt, $r );

    # MINUTELY
    $set = DateTime::Event::ICal->recur( 
       freq => 'minutely',
       dtstart => $dt1,
       interval => 3,
       count => 3 );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( minutes => 30 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-04-28T12:10:45 2003-04-28T12:13:45 2003-04-28T12:16:45',
        "minutely, dtstart, dtend, interval, count" );

}

