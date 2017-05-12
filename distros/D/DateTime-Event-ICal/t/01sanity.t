#!/bin/perl -w

use strict;

use Test::More tests => 6;

use DateTime;
use DateTime::Event::ICal;

{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $dt2 = new DateTime( year => 2003, month => 5, day => 01,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my ( $set, @dt, $r );

    # DAILY
    $set = DateTime::Event::ICal->recur( freq => 'daily' );
    @dt = $set->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r, 
        '2003-04-29T00:00:00 2003-04-30T00:00:00 2003-05-01T00:00:00',
        "daily without args" );

    # SECONDLY
    $set = DateTime::Event::ICal->recur( freq => 'secondly' );
    @dt = $set->as_list( start => $dt1, 
                         end => $dt1->clone->add( seconds => 2 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-04-28T12:10:46 2003-04-28T12:10:47',
        "secondly" );

    # MINUTELY
    $set = DateTime::Event::ICal->recur( 
       freq => 'minutely',
       dtstart => $dt1 );
    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( minutes => 2 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-04-28T12:11:45 2003-04-28T12:12:45',
        "minutely and dtstart" );

    # HOURLY
    $set = DateTime::Event::ICal->recur(
       freq => 'hourly',
       dtstart => $dt1,
       bysecond => [ 1, 3 ] );
    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( hours => 2 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-04-28T13:10:01 2003-04-28T13:10:03 '.
        '2003-04-28T14:10:01 2003-04-28T14:10:03',
        "hourly, dtstart, bysecond" );

    # MONTHLY 
    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
    );
    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( months => 2 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-05-28T12:10:45 2003-06-28T12:10:45',
        "monthly, dtstart" );

    # MONTHLY BYMONTHDAY
    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
       bymonthday => [ 1, 3 ] );
    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( months => 2 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-05-01T12:10:45 2003-05-03T12:10:45 '.
        '2003-06-01T12:10:45 2003-06-03T12:10:45',
        "monthly, dtstart, bymonthday" );
}

