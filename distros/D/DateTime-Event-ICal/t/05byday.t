#!/bin/perl -w

use strict;

use Test::More tests => 11;

use DateTime;
use DateTime::Event::ICal;

# yearly
{
    my $dt1 = new DateTime( year => 2000 );
    my ( $set, @dt, $r );

    # test contributed by John Bishop
    $set = DateTime::Event::ICal->recur( 
       freq => 'yearly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( years => 3 ),
       bymonth => 7,
       byday => '3mo' );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-07-17T00:00:00 2001-07-16T00:00:00 2002-07-15T00:00:00',
        "yearly, bymonth, byday" );


    $set = DateTime::Event::ICal->recur(
       freq => 'yearly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( years => 3 ),
       bymonth => 7,
       byday => '3mo',
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-07-17T10:00:00 2001-07-16T10:00:00 2002-07-15T10:00:00',
        "yearly, bymonth, byday, byhour" );


    $set = DateTime::Event::ICal->recur(
       freq => 'yearly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( years => 1 ),
       bymonth => 7,
       byday => ['3mo', 'fr' ],
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-07-07T10:00:00 2000-07-14T10:00:00 2000-07-17T10:00:00 2000-07-21T10:00:00 2000-07-28T10:00:00',
        "yearly, bymonth, byday index+nonindex, byhour" );

    $set = DateTime::Event::ICal->recur(
       freq => 'yearly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( years => 3 ),
       interval => 2,
       bymonth => 7,
       byday => ['3mo', 'fr' ],
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-07-07T10:00:00 2000-07-14T10:00:00 2000-07-17T10:00:00 2000-07-21T10:00:00 2000-07-28T10:00:00 '.
        '2002-07-05T10:00:00 2002-07-12T10:00:00 2002-07-15T10:00:00 2002-07-19T10:00:00 2002-07-26T10:00:00',
        "yearly, interval, bymonth, byday index+nonindex, byhour" );


    # all months
    $set = DateTime::Event::ICal->recur(
       freq => 'yearly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( years => 3 ),
       interval => 2,
       byday => ['3mo', 'fr' ],
       byhour => 10 );

    @dt = $set->as_list( start => $dt1, 
                         end   => $dt1->clone->add( months => 1 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-01-07T10:00:00 2000-01-14T10:00:00 2000-01-17T10:00:00 2000-01-21T10:00:00 2000-01-28T10:00:00',
        "(2000) yearly, interval, byday index+nonindex, byhour" );
    @dt = $set->as_list( start => $dt1->clone->add( months => 12 ),
                         end   => $dt1->clone->add( months => 13 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '',
        "(2001 = empty) yearly, interval, byday index+nonindex, byhour" );
    @dt = $set->as_list( start => $dt1->clone->add( months => 24 ),
                         end   => $dt1->clone->add( months => 25 ) );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2002-01-04T10:00:00 2002-01-11T10:00:00 2002-01-18T10:00:00 2002-01-21T10:00:00 2002-01-25T10:00:00',
        "(2002) yearly, interval, byday index+nonindex, byhour" );
}

# monthly
{
    my $dt1 = new DateTime( year => 2000 );
    my ( $set, @dt, $r );

    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( months => 4 ),
       byday => '3mo' );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-01-17T00:00:00 2000-02-21T00:00:00 2000-03-20T00:00:00 2000-04-17T00:00:00',
        "monthly, byday" );


    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( months => 4 ),
       byday => '3mo',
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-01-17T10:00:00 2000-02-21T10:00:00 2000-03-20T10:00:00 2000-04-17T10:00:00',
        "monthly, byday, byhour" );

    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( months => 2 ),
       byday => ['3mo', 'fr' ],
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-01-07T10:00:00 2000-01-14T10:00:00 2000-01-17T10:00:00 '.
        '2000-01-21T10:00:00 2000-01-28T10:00:00 2000-02-04T10:00:00 '.
        '2000-02-11T10:00:00 2000-02-18T10:00:00 2000-02-21T10:00:00 '.
        '2000-02-25T10:00:00',
        "monthly, byday index+nonindex, byhour" );

    $set = DateTime::Event::ICal->recur(
       freq => 'monthly',
       dtstart => $dt1,
       dtend => $dt1->clone->add( months => 3 ),
       interval => 2,
       byday => ['3mo', 'fr' ],
       byhour => 10 );

    @dt = $set->as_list;
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2000-01-07T10:00:00 2000-01-14T10:00:00 2000-01-17T10:00:00 '.
        '2000-01-21T10:00:00 2000-01-28T10:00:00 '.
        '2000-03-03T10:00:00 '.
        '2000-03-10T10:00:00 2000-03-17T10:00:00 2000-03-20T10:00:00 '.
        '2000-03-24T10:00:00 2000-03-31T10:00:00',
        "monthly, byday index+nonindex, byhour" );
}

