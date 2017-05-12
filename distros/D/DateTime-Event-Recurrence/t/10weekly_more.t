#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;
use DateTime;
use DateTime::Event::Recurrence;

my $dt1;
my $dt2;

sub calc 
{
    my @dt = $_[0]->as_list( start => $dt1, end => $dt2 );
    my $r = join(' ', map { $_->datetime } @dt);
    return $r;
}


    $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    $dt2 = new DateTime( year => 2006, month => 5, day => 01,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => 'mo' );
    is( calc( $yearly ), 
        '2003-12-29T00:00:00 2005-01-03T00:00:00 2006-01-02T00:00:00',
        "yearly-weekly mo" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => 'su' );
    is( calc( $yearly ),
        '2004-01-04T00:00:00 2005-01-02T00:00:00 2006-01-01T00:00:00',
        "yearly-weekly su" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => 'tu' );
    is( calc( $yearly ),
        '2003-12-30T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly tu" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, days => 'tu', week_start_day => 'tu' );
    is( calc( $yearly ),
        '2003-12-30T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly tu - named week-day" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, days => 2, week_start_day => 'tu' );
    is( calc( $yearly ),
        '2003-12-30T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly tu - numbered week-day" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1mo' );
    is( calc( $yearly ),
        '2004-01-05T00:00:00 2005-01-03T00:00:00 2006-01-02T00:00:00',
        "yearly-weekly 1mo" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1su' );
    is( calc( $yearly ),
        '2004-01-04T00:00:00 2005-01-02T00:00:00 2006-01-01T00:00:00',
        "yearly-weekly 1su" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1tu' );
    is( calc( $yearly ),
        '2004-01-06T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly 1tu" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, days => 'tu', week_start_day => '1tu' );
    is( calc( $yearly ),
        '2004-01-06T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly 1tu - named week-day" );

    $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1, days => 2, week_start_day => '1tu' );
    is( calc( $yearly ),
        '2004-01-06T00:00:00 2005-01-04T00:00:00 2006-01-03T00:00:00',
        "yearly-weekly 1tu - numbered week-day" );


    # MONTHLY

    $dt2 = new DateTime( year => 2004, month => 2, day => 01,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $monthly = monthly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1mo' );
    is( calc( $monthly ),
        '2003-05-05T00:00:00 2003-06-02T00:00:00 2003-07-07T00:00:00 2003-08-04T00:00:00 2003-09-01T00:00:00 2003-10-06T00:00:00 2003-11-03T00:00:00 2003-12-01T00:00:00 2004-01-05T00:00:00',
        "monthly-weekly 1mo" );

    $monthly = monthly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1su' );
    is( calc( $monthly ),
        '2003-05-04T00:00:00 2003-06-01T00:00:00 2003-07-06T00:00:00 2003-08-03T00:00:00 2003-09-07T00:00:00 2003-10-05T00:00:00 2003-11-02T00:00:00 2003-12-07T00:00:00 2004-01-04T00:00:00 2004-02-01T00:00:00',
        "monthly-weekly 1su" );

    $monthly = monthly DateTime::Event::Recurrence(
           weeks => 1, week_start_day => '1tu' );
    is( calc( $monthly ),
        '2003-05-06T00:00:00 2003-06-03T00:00:00 2003-07-01T00:00:00 2003-08-05T00:00:00 2003-09-02T00:00:00 2003-10-07T00:00:00 2003-11-04T00:00:00 2003-12-02T00:00:00 2004-01-06T00:00:00',
        "monthly-weekly 1tu" );


    # WEEKLY

    $dt2 = new DateTime( year => 2003, month => 6, day => 10,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $weekly = weekly DateTime::Event::Recurrence(
           week_start_day => '1su' );
    is( calc( $weekly ),
        '2003-05-04T00:00:00 2003-05-11T00:00:00 2003-05-18T00:00:00 2003-05-25T00:00:00 2003-06-01T00:00:00 2003-06-08T00:00:00',
        "weekly 1su" );

    $weekly = weekly DateTime::Event::Recurrence(
           days => 7, week_start_day => '1su' );
    is( calc( $weekly ),
        '2003-05-04T00:00:00 2003-05-11T00:00:00 2003-05-18T00:00:00 2003-05-25T00:00:00 2003-06-01T00:00:00 2003-06-08T00:00:00',
        "weekly 1su - numbered week-day" );

    $weekly = weekly DateTime::Event::Recurrence(
           days => 'su', week_start_day => '1su' );
    is( calc( $weekly ),
        '2003-05-04T00:00:00 2003-05-11T00:00:00 2003-05-18T00:00:00 2003-05-25T00:00:00 2003-06-01T00:00:00 2003-06-08T00:00:00',
        "weekly 1su - named week-day" );



