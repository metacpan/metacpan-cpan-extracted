#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;
use DateTime;
use DateTime::Event::Recurrence;

{
    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $dt2 = new DateTime( year => 2006, month => 5, day => 01,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );


    
    my $yearly = yearly DateTime::Event::Recurrence(
           weeks => 1 );

           #              year_type => 'weekly' );

    my @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    my $r = join(' ', map { $_->datetime } @dt);
    is( $r, 
        '2003-12-29T00:00:00 2005-01-03T00:00:00 2006-01-02T00:00:00',
        "yearly-weekly" );

    $yearly = yearly DateTime::Event::Recurrence(
                         # year_type => 'weekly',
                         weeks => [ 2 ] );
    @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2004-01-05T00:00:00 2005-01-10T00:00:00 2006-01-09T00:00:00',
        "yearly-weekly week 2" );


    $yearly = yearly DateTime::Event::Recurrence(
                         weeks => -1 );

    @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-22T00:00:00 2004-12-27T00:00:00 2005-12-26T00:00:00',
        "yearly-weekly weeks -1" );


    $yearly = yearly DateTime::Event::Recurrence(
                         # year_type => 'weekly',
                         weeks => [ -1 ] );
    @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-22T00:00:00 2004-12-27T00:00:00 2005-12-26T00:00:00',
        "yearly-weekly week -1" );

    $yearly = yearly DateTime::Event::Recurrence(
                         # year_type => 'weekly',
                         weeks => [ -1, 2 ] );
    @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-22T00:00:00 2004-01-05T00:00:00 '.
        '2004-12-27T00:00:00 2005-01-10T00:00:00 '.
        '2005-12-26T00:00:00 2006-01-09T00:00:00',
        "yearly-weekly week -1, 2" );

    # YEARLY TYPE AUTO-DETECTION
    $yearly = yearly DateTime::Event::Recurrence(
                         # year_type => 'weekly',
                         weeks => [ -1, 2 ] );
    @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    $r = join(' ', map { $_->datetime } @dt);
    is( $r,
        '2003-12-22T00:00:00 2004-01-05T00:00:00 '.
        '2004-12-27T00:00:00 2005-01-10T00:00:00 '.
        '2005-12-26T00:00:00 2006-01-09T00:00:00',
        "yearly-weekly week -1, 2" );

}

