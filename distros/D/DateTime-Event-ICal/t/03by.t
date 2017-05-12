#!/bin/perl -w

use strict;

use Test::More tests => 7;

use DateTime;
use DateTime::Event::ICal;

{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           time_zone => 'UTC' );

    # $dt1 is monday, week 18

    my ( $set, @dt, $r );

    # DAILY BYMONTH
    $set = DateTime::Event::ICal->recur( 
       freq =>     'daily',
       dtstart =>  $dt1,
       bymonth =>  [ 2, 12 ],
       interval => 10  );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-04T12:10:45 2003-12-14T12:10:45 2003-12-24T12:10:45 '.
        '2004-02-02T12:10:45 2004-02-12T12:10:45 2004-02-22T12:10:45',
        "daily, dtstart, interval, bymonth" );

    # YEARLY BYMONTH BYMONTHDAY
    $set = DateTime::Event::ICal->recur( 
       freq =>       'yearly',
       dtstart =>    $dt1,
       bymonth =>    [ 2, 12 ],
       bymonthday => [ 3, 13 ]  );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-03T12:10:45 2003-12-13T12:10:45 '.
        '2004-02-03T12:10:45 2004-02-13T12:10:45',
        "yearly, dtstart, bymonthday, bymonth" );

    # YEARLY BYWEEKNO
    $set = DateTime::Event::ICal->recur( 
       freq =>       'yearly',
       dtstart =>    $dt1,
       byweekno =>   [ 2, 12 ],
    );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2004-01-05T12:10:45 2004-03-15T12:10:45',
        "yearly, dtstart, byweekno" );

    # CHANGE DTSTART WEEKDAY

    $set = DateTime::Event::ICal->recur( 
       freq =>       'yearly',
       dtstart =>    $dt1->clone->add( days => 1 ),
       byweekno =>   [ 2, 12 ],
    );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2004-01-06T12:10:45 2004-03-16T12:10:45',
        "yearly, dtstart, byweekno" );

    # YEARLY BYDAY=1FR
    $set = DateTime::Event::ICal->recur( 
       freq =>       'yearly',
       dtstart =>    $dt1,
       byday =>      [ '1fr', '2fr', '-1tu' ],
    );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-30T12:10:45 2004-01-02T12:10:45 2004-01-09T12:10:45',
        "yearly, dtstart, byday=1fr,2fr,-1tu" );


    # YEARLY BYDAY=1FR HOUR
    $set = DateTime::Event::ICal->recur(
       freq =>       'yearly',
       dtstart =>    $dt1,
       byday =>      [ '1fr', '2fr', '-1tu' ],
       byhour =>     [ 10, 14 ],
    );

    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( years => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-30T10:10:45 2003-12-30T14:10:45 '.
        '2004-01-02T10:10:45 2004-01-02T14:10:45 '.
        '2004-01-09T10:10:45 2004-01-09T14:10:45',
        "yearly, dtstart, byday=1fr,2fr,-1tu, byhour" );


    # MONTHLY BYSETPOS
    $set = DateTime::Event::ICal->recur(
       freq =>       'monthly',
       dtstart =>    $dt1,
       bymonthday => [ -1, -2, -3, -4, -5, -6 ],
       bysetpos =>   [ 3, -2 ],
    );


    @dt = $set->as_list( start => $dt1,
                         end => $dt1->clone->add( months => 3 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-04-29T12:10:45 '. 
        '2003-05-28T12:10:45 '. 
        '2003-05-30T12:10:45 2003-06-27T12:10:45 2003-06-29T12:10:45 '.
        '2003-07-28T12:10:45',
        "monthly, bymonthday, bysetpos" ); 


}

