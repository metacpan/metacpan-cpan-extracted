#!/bin/perl -w
# Copyright (c) 2003 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# modified from Date::Set tests
#

use strict;
# use warnings;
use Test::More tests => 42;

use DateTime::Span;
BEGIN { use_ok('DateTime::Event::ICal') };

sub str {
    my $iter = $_[0]->iterator;
    my @result;
    while ( my $dt = $iter->next ) {
        push @result, $dt->datetime
            if ref( $dt ); 
    };
    return join( ',', @result );
}

my ($title, $a, $a2, $b, $period, $RFC);

# DATES

my $dt19950101 = DateTime->new( 
    year => 1995 );

my $dt19961105T090000 = DateTime->new(
    year => 1996, month => 11, day => 05, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19990101 = DateTime->new( 
    year => 1999 );

my $dt19970101T090000 = DateTime->new(
    year => 1997, month => 1, day => 1, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970310T090000 = DateTime->new(
    year => 1997, month => 3, day => 10, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970610T090000 = DateTime->new(
    year => 1997, month => 6, day => 10, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970805T090000 = DateTime->new(
    year => 1997, month => 8, day => 5, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970902T090000 = DateTime->new( 
    year => 1997, month => 9, day => 2, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970904T090000 = $dt19970902T090000->clone->add( days => 2 );

my $dt19970905T090000 = DateTime->new( 
    year => 1997, month => 9, day => 5, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19970902T170000 = DateTime->new(
    year => 1997, month => 9, day => 2, hour => 17,
    # time_zone => 'US-Eastern',
 );

my $dt19971007T000000= DateTime->new(
    year => 1997, month => 10, day => 7,
    # time_zone => 'US-Eastern',
 );

my $dt19971224T000000 = DateTime->new(
    year => 1997, month => 12, day => 24, 
    # time_zone => 'US-Eastern',
 );

my $dt19980101T090000 = DateTime->new(
    year => 1998, month => 1, day => 1, hour => 9,
    # time_zone => 'US-Eastern',
 );

my $dt19980201T000000 = DateTime->new(
    year => 1998, month => 2, day => 1, 
    # time_zone => 'US-Eastern',
 );

my $dt20000131T090000 = DateTime->new(
    year => 2000, month => 1, day => 31, hour => 9,
    # time_zone => 'US-Eastern',
 );


# PERIODS

my $period_1995_19970904T090000 = DateTime::Span->new(
            start => $dt19950101, end => $dt19970904T090000 );

my $period_1995_1999 = DateTime::Span->new(
            start => $dt19950101, end => $dt19990101 );

my $period_1995_1998 = DateTime::Span->new(
            start => $dt19950101, 
            end => $dt19990101->clone->subtract( years => 1 ) );

my $period_1995_19980201 = DateTime::Span->new(
            start => $dt19950101,
            end =>   $dt19980201T000000 );

my $period_1995_19980301 = DateTime::Span->new(
            start => $dt19950101,
            end =>   $dt19980201T000000->clone->add( months => 1 ) );

my $period_1995_19980401 = DateTime::Span->new(
            start => $dt19950101,
            end =>   $dt19980201T000000->clone->add( months => 2 ) );

my $period_1995_2000 = DateTime::Span->new(
            start => $dt19950101,
            end => $dt19990101->clone->add( years => 1 ) );

my $period_1995_2001 = DateTime::Span->new(
            start => $dt19950101,
            end => $dt19990101->clone->add( years => 2 ) );

my $period_1995_2004 = DateTime::Span->new(
            start => $dt19950101,
            end => $dt19990101->clone->add( years => 5 ) );

my $period_1995_2005 = DateTime::Span->new(
            start => $dt19950101,
            end => $dt19990101->clone->add( years => 6 ) );

my $period_1995_2007 = DateTime::Span->new(
            start => $dt19950101,
            end => $dt19990101->clone->add( years => 8 ) );


# TESTS

$title="***  Daily for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=DAILY;COUNT=10
#
#     ==> (1997 9:00 AM EDT)September 2-11
#
    $a = DateTime::Event::ICal->recur( 
            dtstart => $dt19970902T090000 ,
            freq => 'daily', 
            count => 10 )
            ->intersection( $period_1995_1999 );
    is("". str($a), 
        '1997-09-02T09:00:00,1997-09-03T09:00:00,' .
        '1997-09-04T09:00:00,1997-09-05T09:00:00,' .
        '1997-09-06T09:00:00,1997-09-07T09:00:00,' .
        '1997-09-08T09:00:00,1997-09-09T09:00:00,' .
        '1997-09-10T09:00:00,1997-09-11T09:00:00', $title);


$title="***  Daily until December 24, 1997  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=DAILY;UNTIL=1997-12-24T00:00:00
#
#     ==> (1997 9:00 AM EDT)September 2-30;October 1-25
#         (1997 9:00 AM EST)October 26-31;November 1-30;December 1-23
#
    $a = DateTime::Event::ICal->recur(
            dtstart => $dt19970902T090000 ,
            freq => 'daily',
            until => $dt19971224T000000 )
            ->intersection( $period_1995_1999 );
    is("". str($a),
        '1997-09-02T09:00:00,1997-09-03T09:00:00,' .
        '1997-09-04T09:00:00,1997-09-05T09:00:00,' .
        '1997-09-06T09:00:00,1997-09-07T09:00:00,' .
        '1997-09-08T09:00:00,1997-09-09T09:00:00,' .
        '1997-09-10T09:00:00,1997-09-11T09:00:00,' .
        '1997-09-12T09:00:00,1997-09-13T09:00:00,' .
        '1997-09-14T09:00:00,1997-09-15T09:00:00,' .
        '1997-09-16T09:00:00,1997-09-17T09:00:00,' .
        '1997-09-18T09:00:00,1997-09-19T09:00:00,' .
        '1997-09-20T09:00:00,1997-09-21T09:00:00,' .
        '1997-09-22T09:00:00,1997-09-23T09:00:00,' .
        '1997-09-24T09:00:00,1997-09-25T09:00:00,' .
        '1997-09-26T09:00:00,1997-09-27T09:00:00,' .
        '1997-09-28T09:00:00,1997-09-29T09:00:00,' .
        '1997-09-30T09:00:00,1997-10-01T09:00:00,' .
        '1997-10-02T09:00:00,1997-10-03T09:00:00,' .
        '1997-10-04T09:00:00,1997-10-05T09:00:00,' .
        '1997-10-06T09:00:00,1997-10-07T09:00:00,' .
        '1997-10-08T09:00:00,1997-10-09T09:00:00,' .
        '1997-10-10T09:00:00,1997-10-11T09:00:00,' .
        '1997-10-12T09:00:00,1997-10-13T09:00:00,' .
        '1997-10-14T09:00:00,1997-10-15T09:00:00,' .
        '1997-10-16T09:00:00,1997-10-17T09:00:00,' .
        '1997-10-18T09:00:00,1997-10-19T09:00:00,' .
        '1997-10-20T09:00:00,1997-10-21T09:00:00,' .
        '1997-10-22T09:00:00,1997-10-23T09:00:00,' .
        '1997-10-24T09:00:00,1997-10-25T09:00:00,' .
        '1997-10-26T09:00:00,1997-10-27T09:00:00,' .
        '1997-10-28T09:00:00,1997-10-29T09:00:00,' .
        '1997-10-30T09:00:00,1997-10-31T09:00:00,' .
        '1997-11-01T09:00:00,1997-11-02T09:00:00,' .
        '1997-11-03T09:00:00,1997-11-04T09:00:00,' .
        '1997-11-05T09:00:00,1997-11-06T09:00:00,' .
        '1997-11-07T09:00:00,1997-11-08T09:00:00,' .
        '1997-11-09T09:00:00,1997-11-10T09:00:00,' .
        '1997-11-11T09:00:00,1997-11-12T09:00:00,' .
        '1997-11-13T09:00:00,1997-11-14T09:00:00,' .
        '1997-11-15T09:00:00,1997-11-16T09:00:00,' .
        '1997-11-17T09:00:00,1997-11-18T09:00:00,' .
        '1997-11-19T09:00:00,1997-11-20T09:00:00,' .
        '1997-11-21T09:00:00,1997-11-22T09:00:00,' .
        '1997-11-23T09:00:00,1997-11-24T09:00:00,' .
        '1997-11-25T09:00:00,1997-11-26T09:00:00,' .
        '1997-11-27T09:00:00,1997-11-28T09:00:00,' .
        '1997-11-29T09:00:00,1997-11-30T09:00:00,' .
        '1997-12-01T09:00:00,1997-12-02T09:00:00,' .
        '1997-12-03T09:00:00,1997-12-04T09:00:00,' .
        '1997-12-05T09:00:00,1997-12-06T09:00:00,' .
        '1997-12-07T09:00:00,1997-12-08T09:00:00,' .
        '1997-12-09T09:00:00,1997-12-10T09:00:00,' .
        '1997-12-11T09:00:00,1997-12-12T09:00:00,' .
        '1997-12-13T09:00:00,1997-12-14T09:00:00,' .
        '1997-12-15T09:00:00,1997-12-16T09:00:00,' .
        '1997-12-17T09:00:00,1997-12-18T09:00:00,' .
        '1997-12-19T09:00:00,1997-12-20T09:00:00,' .
        '1997-12-21T09:00:00,1997-12-22T09:00:00,' .
        '1997-12-23T09:00:00' ,

        $title);



$title="***  Every other day - forever  ***"; 
# 
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=DAILY;INTERVAL=2
#     ==> (1997 9:00 AM EDT)September2,4,6,8...24,26,28,30;
#          October 2,4,6...20,22,24
#         (1997 9:00 AM EST)October 26,28,30;November 1,3,5,7...25,27,29;
#          Dec 1,3,...
#
    $a = DateTime::Event::ICal->recur(
            dtstart => $dt19970902T090000 ,
            freq => 'daily',
            interval => 2 )
            ->intersection( $period_1995_1998 );
    is("". str($a),

        '1997-09-02T09:00:00,1997-09-04T09:00:00,' .
        '1997-09-06T09:00:00,1997-09-08T09:00:00,1997-09-10T09:00:00,' .
        '1997-09-12T09:00:00,1997-09-14T09:00:00,1997-09-16T09:00:00,' .
        '1997-09-18T09:00:00,1997-09-20T09:00:00,1997-09-22T09:00:00,' .
        '1997-09-24T09:00:00,1997-09-26T09:00:00,1997-09-28T09:00:00,' .
        '1997-09-30T09:00:00,1997-10-02T09:00:00,1997-10-04T09:00:00,' .
        '1997-10-06T09:00:00,1997-10-08T09:00:00,1997-10-10T09:00:00,' .
        '1997-10-12T09:00:00,1997-10-14T09:00:00,1997-10-16T09:00:00,' .
        '1997-10-18T09:00:00,1997-10-20T09:00:00,1997-10-22T09:00:00,' .
        '1997-10-24T09:00:00,1997-10-26T09:00:00,1997-10-28T09:00:00,' .
        '1997-10-30T09:00:00,1997-11-01T09:00:00,1997-11-03T09:00:00,' .
        '1997-11-05T09:00:00,1997-11-07T09:00:00,1997-11-09T09:00:00,' .
        '1997-11-11T09:00:00,1997-11-13T09:00:00,1997-11-15T09:00:00,' .
        '1997-11-17T09:00:00,1997-11-19T09:00:00,1997-11-21T09:00:00,' .
        '1997-11-23T09:00:00,1997-11-25T09:00:00,1997-11-27T09:00:00,' .
        '1997-11-29T09:00:00,1997-12-01T09:00:00,1997-12-03T09:00:00,' .
        '1997-12-05T09:00:00,1997-12-07T09:00:00,1997-12-09T09:00:00,' .
        '1997-12-11T09:00:00,1997-12-13T09:00:00,1997-12-15T09:00:00,' .
        '1997-12-17T09:00:00,1997-12-19T09:00:00,1997-12-21T09:00:00,' .
        '1997-12-23T09:00:00,1997-12-25T09:00:00,1997-12-27T09:00:00,' .
        '1997-12-29T09:00:00,1997-12-31T09:00:00',

        $title);



$title="***  Every 10 days, 5 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=DAILY;INTERVAL=10;COUNT=5
#
#     ==> (1997 9:00 AM EDT)September 2,12,22;October 2,12
#
#

    $a = DateTime::Event::ICal->recur(
            dtstart => $dt19970902T090000 ,
            freq => 'daily',
            interval => 10,
            count => 5 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-12T09:00:00,1997-09-22T09:00:00,' .
        '1997-10-02T09:00:00,1997-10-12T09:00:00', 
        $title);


$title="***  Everyday in January, for 3 years  ***";
#
#     DTSTART;TZID=US-Eastern:19980101T090000
#     recur_by_rule:FREQ=YEARLY;UNTIL=2000-01-31T09:00:00;
#      BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA
#     or
#     recur_by_rule:FREQ=DAILY;UNTIL=2000-01-31T09:00:00;BYMONTH=1
#
#     ==> (1998 9:00 AM EDT)January 1-31
#         (1999 9:00 AM EDT)January 1-31
#         (2000 9:00 AM EDT)January 1-31
#
    # FIRST FORM

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'yearly',
            until =>    $dt20000131T090000,
            bymonth =>  [ 1 ],
            byday =>    [ qw( su mo tu we th fr sa ) ] )
            ->intersection( $period_1995_2001 );

    is("".str($a), 
        '1998-01-01T09:00:00,1998-01-02T09:00:00,' .
        '1998-01-03T09:00:00,1998-01-04T09:00:00,1998-01-05T09:00:00,' .
        '1998-01-06T09:00:00,1998-01-07T09:00:00,1998-01-08T09:00:00,' .
        '1998-01-09T09:00:00,1998-01-10T09:00:00,1998-01-11T09:00:00,' .
        '1998-01-12T09:00:00,1998-01-13T09:00:00,1998-01-14T09:00:00,' .
        '1998-01-15T09:00:00,1998-01-16T09:00:00,1998-01-17T09:00:00,' .
        '1998-01-18T09:00:00,1998-01-19T09:00:00,1998-01-20T09:00:00,' .
        '1998-01-21T09:00:00,1998-01-22T09:00:00,1998-01-23T09:00:00,' .
        '1998-01-24T09:00:00,1998-01-25T09:00:00,1998-01-26T09:00:00,' .
        '1998-01-27T09:00:00,1998-01-28T09:00:00,1998-01-29T09:00:00,' .
        '1998-01-30T09:00:00,1998-01-31T09:00:00,' . 
        '1999-01-01T09:00:00,1999-01-02T09:00:00,' .
        '1999-01-03T09:00:00,1999-01-04T09:00:00,1999-01-05T09:00:00,' .
        '1999-01-06T09:00:00,1999-01-07T09:00:00,1999-01-08T09:00:00,' .
        '1999-01-09T09:00:00,1999-01-10T09:00:00,1999-01-11T09:00:00,' .
        '1999-01-12T09:00:00,1999-01-13T09:00:00,1999-01-14T09:00:00,' .
        '1999-01-15T09:00:00,1999-01-16T09:00:00,1999-01-17T09:00:00,' .
        '1999-01-18T09:00:00,1999-01-19T09:00:00,1999-01-20T09:00:00,' .
        '1999-01-21T09:00:00,1999-01-22T09:00:00,1999-01-23T09:00:00,' .
        '1999-01-24T09:00:00,1999-01-25T09:00:00,1999-01-26T09:00:00,' .
        '1999-01-27T09:00:00,1999-01-28T09:00:00,1999-01-29T09:00:00,' .
        '1999-01-30T09:00:00,1999-01-31T09:00:00,' .
        '2000-01-01T09:00:00,2000-01-02T09:00:00,' .
        '2000-01-03T09:00:00,2000-01-04T09:00:00,2000-01-05T09:00:00,' .
        '2000-01-06T09:00:00,2000-01-07T09:00:00,2000-01-08T09:00:00,' .
        '2000-01-09T09:00:00,2000-01-10T09:00:00,2000-01-11T09:00:00,' .
        '2000-01-12T09:00:00,2000-01-13T09:00:00,2000-01-14T09:00:00,' .
        '2000-01-15T09:00:00,2000-01-16T09:00:00,2000-01-17T09:00:00,' .
        '2000-01-18T09:00:00,2000-01-19T09:00:00,2000-01-20T09:00:00,' .
        '2000-01-21T09:00:00,2000-01-22T09:00:00,2000-01-23T09:00:00,' .
        '2000-01-24T09:00:00,2000-01-25T09:00:00,2000-01-26T09:00:00,' .
        '2000-01-27T09:00:00,2000-01-28T09:00:00,2000-01-29T09:00:00,' .
        '2000-01-30T09:00:00,2000-01-31T09:00:00',
        $title);



    # SECOND FORM

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19980101T090000 ,
            freq =>     'daily',
            until =>    $dt20000131T090000,
            bymonth =>  [ 1 ],
            )
            ->intersection( $period_1995_2001 );

    is("".str($a), 
        '1998-01-01T09:00:00,1998-01-02T09:00:00,' .
        '1998-01-03T09:00:00,1998-01-04T09:00:00,1998-01-05T09:00:00,' .
        '1998-01-06T09:00:00,1998-01-07T09:00:00,1998-01-08T09:00:00,' .
        '1998-01-09T09:00:00,1998-01-10T09:00:00,1998-01-11T09:00:00,' .
        '1998-01-12T09:00:00,1998-01-13T09:00:00,1998-01-14T09:00:00,' .
        '1998-01-15T09:00:00,1998-01-16T09:00:00,1998-01-17T09:00:00,' .
        '1998-01-18T09:00:00,1998-01-19T09:00:00,1998-01-20T09:00:00,' .
        '1998-01-21T09:00:00,1998-01-22T09:00:00,1998-01-23T09:00:00,' .
        '1998-01-24T09:00:00,1998-01-25T09:00:00,1998-01-26T09:00:00,' .
        '1998-01-27T09:00:00,1998-01-28T09:00:00,1998-01-29T09:00:00,' .
        '1998-01-30T09:00:00,1998-01-31T09:00:00,' . 
        '1999-01-01T09:00:00,1999-01-02T09:00:00,' .
        '1999-01-03T09:00:00,1999-01-04T09:00:00,1999-01-05T09:00:00,' .
        '1999-01-06T09:00:00,1999-01-07T09:00:00,1999-01-08T09:00:00,' .
        '1999-01-09T09:00:00,1999-01-10T09:00:00,1999-01-11T09:00:00,' .
        '1999-01-12T09:00:00,1999-01-13T09:00:00,1999-01-14T09:00:00,' .
        '1999-01-15T09:00:00,1999-01-16T09:00:00,1999-01-17T09:00:00,' .
        '1999-01-18T09:00:00,1999-01-19T09:00:00,1999-01-20T09:00:00,' .
        '1999-01-21T09:00:00,1999-01-22T09:00:00,1999-01-23T09:00:00,' .
        '1999-01-24T09:00:00,1999-01-25T09:00:00,1999-01-26T09:00:00,' .
        '1999-01-27T09:00:00,1999-01-28T09:00:00,1999-01-29T09:00:00,' .
        '1999-01-30T09:00:00,1999-01-31T09:00:00,' .
        '2000-01-01T09:00:00,2000-01-02T09:00:00,' .
        '2000-01-03T09:00:00,2000-01-04T09:00:00,2000-01-05T09:00:00,' .
        '2000-01-06T09:00:00,2000-01-07T09:00:00,2000-01-08T09:00:00,' .
        '2000-01-09T09:00:00,2000-01-10T09:00:00,2000-01-11T09:00:00,' .
        '2000-01-12T09:00:00,2000-01-13T09:00:00,2000-01-14T09:00:00,' .
        '2000-01-15T09:00:00,2000-01-16T09:00:00,2000-01-17T09:00:00,' .
        '2000-01-18T09:00:00,2000-01-19T09:00:00,2000-01-20T09:00:00,' .
        '2000-01-21T09:00:00,2000-01-22T09:00:00,2000-01-23T09:00:00,' .
        '2000-01-24T09:00:00,2000-01-25T09:00:00,2000-01-26T09:00:00,' .
        '2000-01-27T09:00:00,2000-01-28T09:00:00,2000-01-29T09:00:00,' .
        '2000-01-30T09:00:00,2000-01-31T09:00:00',
        $title);


$title="***  Weekly for 10 occurrence  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=WEEKLY;COUNT=10
#
#     ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#         (1997 9:00 AM EST)October 28;November 4
#

    # 'FREQ=WEEKLY' MEANS THAT 'DTSTART' SPECIFIES DAY-OF-WEEK (=tuesday)

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'weekly',
            count =>    10,
            )
            ->intersection( $period_1995_1999 );

    is("".str($a),
        '1997-09-02T09:00:00,1997-09-09T09:00:00,' .
        '1997-09-16T09:00:00,1997-09-23T09:00:00,1997-09-30T09:00:00,' .
        '1997-10-07T09:00:00,1997-10-14T09:00:00,1997-10-21T09:00:00,' .
        '1997-10-28T09:00:00,1997-11-04T09:00:00',
        $title);


$title="***  Weekly until December 24, 1997  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=WEEKLY;UNTIL=1997-12-24T00:00:00
#
#     ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#         (1997 9:00 AM EST)October 28;November 4,11,18,25;
#                           December 2,9,16,23
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'weekly',
            until =>    $dt19971224T000000,
            )
            ->intersection( $period_1995_1999 );

    is("". str($a), 
        '1997-09-02T09:00:00,1997-09-09T09:00:00,' .
        '1997-09-16T09:00:00,1997-09-23T09:00:00,1997-09-30T09:00:00,' .
        '1997-10-07T09:00:00,1997-10-14T09:00:00,1997-10-21T09:00:00,' .
        '1997-10-28T09:00:00,' .
        '1997-11-04T09:00:00,1997-11-11T09:00:00,' .
        '1997-11-18T09:00:00,1997-11-25T09:00:00,' .
        '1997-12-02T09:00:00,1997-12-09T09:00:00,' .
        '1997-12-16T09:00:00,1997-12-23T09:00:00',
        $title);


$title="***  Every other week - forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=WEEKLY;INTERVAL=2;WKST=SU
#
#     ==> (1997 9:00 AM EDT)September 2,16,30;October 14
#         (1997 9:00 AM EST)October 28;November 11,25;December 9,23
#         (1998 9:00 AM EST)January 6,20;February
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'weekly',
            interval => 2,
            wkst =>     'su',  
            )
            ->intersection( $period_1995_19980201 );

    is("". str($a), 
        '1997-09-02T09:00:00,1997-09-16T09:00:00,1997-09-30T09:00:00,' .
        '1997-10-14T09:00:00,' .
        '1997-10-28T09:00:00,' .
        '1997-11-11T09:00:00,1997-11-25T09:00:00,' .
        '1997-12-09T09:00:00,1997-12-23T09:00:00,' .
        '1998-01-06T09:00:00,1998-01-20T09:00:00',
        $title);


#### TEST 11 ##########

$title="***  Weekly on Tuesday and Thursday for 5 weeks  ***";
#
#    DTSTART;TZID=US-Eastern:19970902T090000
#    recur_by_rule:FREQ=WEEKLY;UNTIL=1997-10-07T00:00:00;WKST=SU;BYDAY=TU,TH
#    or
#
#    recur_by_rule:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH
#
#    ==> (1997 9:00 AM EDT)September 2,4,9,11,16,18,23,25,30;October 2
#
    # FIRST

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000,
            freq =>     'weekly',
            until =>    $dt19971007T000000,
            wkst =>     'su',   
            byday =>    [ 'tu', 'th' ],
            )
            ->intersection( $period_1995_1999 );

    is("". str($a),
        '1997-09-02T09:00:00,1997-09-04T09:00:00,' .
        '1997-09-09T09:00:00,1997-09-11T09:00:00,1997-09-16T09:00:00,' .
        '1997-09-18T09:00:00,1997-09-23T09:00:00,1997-09-25T09:00:00,' .
        '1997-09-30T09:00:00,1997-10-02T09:00:00',
        $title);

    # SECOND

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000,
            freq =>     'weekly',
            count =>    10,
            wkst =>     'su',
            byday =>    [ 'tu', 'th' ],
            )
            ->intersection( $period_1995_1999 );

    is("". str($a), 
        '1997-09-02T09:00:00,1997-09-04T09:00:00,' .
        '1997-09-09T09:00:00,1997-09-11T09:00:00,1997-09-16T09:00:00,' .
        '1997-09-18T09:00:00,1997-09-23T09:00:00,1997-09-25T09:00:00,' .
        '1997-09-30T09:00:00,1997-10-02T09:00:00', 
        $title);


$title="***  Every other week on Monday, Wednesday and Friday until December 24  ***";
#   1997, but starting on Tuesday, September 2, 1997:
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=WEEKLY;INTERVAL=2;UNTIL=1997-12-24T00:00:00;WKST=SU;
#      BYDAY=MO,WE,FR
#     ==> (1997 9:00 AM EDT)September 2,3,5,15,17,19,29;October
#     1,3,13,15,17
#         (1997 9:00 AM EST)October 27,29,31;November 10,12,14,24,26,28;
#                           December 8,10,12,22
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000,
            freq =>     'weekly',
            interval => 2,
            until =>    $dt19971224T000000,
            wkst =>     'su',
            byday =>    [ 'mo', 'we', 'fr' ],
            )
            ->union( $dt19970902T090000 )
            ->intersection( $period_1995_1999 );

    is("". str($a),
    '1997-09-02T09:00:00,1997-09-03T09:00:00,' .
    '1997-09-05T09:00:00,1997-09-15T09:00:00,1997-09-17T09:00:00,' .
    '1997-09-19T09:00:00,1997-09-29T09:00:00,' .
    '1997-10-01T09:00:00,1997-10-03T09:00:00,' .
    '1997-10-13T09:00:00,1997-10-15T09:00:00,1997-10-17T09:00:00,' .
    '1997-10-27T09:00:00,1997-10-29T09:00:00,1997-10-31T09:00:00,' .
    '1997-11-10T09:00:00,1997-11-12T09:00:00,' .
    '1997-11-14T09:00:00,1997-11-24T09:00:00,1997-11-26T09:00:00,' .
    '1997-11-28T09:00:00,1997-12-08T09:00:00,1997-12-10T09:00:00,' .
    '1997-12-12T09:00:00,1997-12-22T09:00:00',
    $title);


######## TEST 14

$title="***  Every other week on Tuesday and Thursday, for 8 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH
#
#     ==> (1997 9:00 AM EDT)September 2,4,16,18,30;October 2,14,16
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000,
            freq =>     'weekly',
            interval => 2,
            count =>    8,
            wkst =>     'su',
            byday =>    [ 'tu', 'th' ],
            )
            ->union( $dt19970902T090000 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
    '1997-09-02T09:00:00,1997-09-04T09:00:00,' .
    '1997-09-16T09:00:00,1997-09-18T09:00:00,1997-09-30T09:00:00,' .
    '1997-10-02T09:00:00,1997-10-14T09:00:00,1997-10-16T09:00:00', 
    $title);


#### TEST 15

$title="***  Monthly on the 1st Friday for ten occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970905T090000
#     recur_by_rule:FREQ=MONTHLY;COUNT=10;BYDAY=1FR
#
#     ==> (1997 9:00 AM EDT)September 5;October 3
#         (1997 9:00 AM EST)November 7;Dec 5
#         (1998 9:00 AM EST)January 2;February 6;March 6;April 3
#         (1998 9:00 AM EDT)May 1;June 5
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            count =>    10,
            byday =>    [ '1fr' ],
            )
            ->union( $dt19970905T090000 )
            ->intersection( $period_1995_1999 );

    is("".str($a),
    '1997-09-05T09:00:00,' .
    '1997-10-03T09:00:00,' .
    '1997-11-07T09:00:00,' .
    '1997-12-05T09:00:00,' .
    '1998-01-02T09:00:00,' .
    '1998-02-06T09:00:00,' .
    '1998-03-06T09:00:00,' .
    '1998-04-03T09:00:00,' .
    '1998-05-01T09:00:00,' .
    '1998-06-05T09:00:00',
    $title);


$title="***  Monthly on the 1st Friday until December 24, 1997  ***";
#
#     DTSTART;TZID=US-Eastern:19970905T090000
#     recur_by_rule:FREQ=MONTHLY;UNTIL=1997-12-24T00:00:00;BYDAY=1FR
#
#     ==> (1997 9:00 AM EDT)September 5;October 3
#         (1997 9:00 AM EST)November 7;December 5
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            until =>    $dt19971224T000000,
            byday =>    [ '1fr' ],
            )
            ->union( $dt19970905T090000 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
    '1997-09-05T09:00:00,' .
    '1997-10-03T09:00:00,' .
    '1997-11-07T09:00:00,' .
    '1997-12-05T09:00:00',
    $title);


$title="***  Every other month on the 1st and last Sunday of the month for 1  ***";
#   occurrences:
#
#     DTSTART;TZID=US-Eastern:19970907T090000
#     recur_by_rule:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU
#
#     ==> (1997 9:00 AM EDT)September 7,28
#         (1997 9:00 AM EST)November 2,30
#
#         (1998 9:00 AM EST)January 4,25;March 1,29
#         (1998 9:00 AM EDT)May 3,31
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            interval => 2,
            count =>    10,
            byday =>    [ '1su', '-1su' ],
            )
            # ->union( $dt19970905T090000 )
            ->intersection( $period_1995_1999 );


    is("".str($a), 
    '1997-09-07T09:00:00,1997-09-28T09:00:00,' .
    '1997-11-02T09:00:00,1997-11-30T09:00:00,' .
    '1998-01-04T09:00:00,1998-01-25T09:00:00,' .
    '1998-03-01T09:00:00,1998-03-29T09:00:00,' .
    '1998-05-03T09:00:00,1998-05-31T09:00:00' ,
    $title);


$title="***  Monthly on the second to last Monday of the month for 6 months  ***";
#
#     DTSTART;TZID=US-Eastern:19970922T090000
#     recur_by_rule:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO
#
#     ==> (1997 9:00 AM EDT)September 22;October 20
#         (1997 9:00 AM EST)November 17;December 22
#         (1998 9:00 AM EST)January 19;February 16
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            count =>    6,
            byday =>    [ '-2mo' ],
            )
            # ->union( $dt19970905T090000 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
    '1997-09-22T09:00:00,1997-10-20T09:00:00,' .
    '1997-11-17T09:00:00,1997-12-22T09:00:00,' .
    '1998-01-19T09:00:00,1998-02-16T09:00:00',
    $title);




$title="***  Monthly on the third to the last day of the month, forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970928T090000
#     recur_by_rule:FREQ=MONTHLY;BYMONTHDAY=-3
#
#     ==> (1997 9:00 AM EDT)September 28
#         (1997 9:00 AM EST)October 29;November 28;December 29
#         (1998 9:00 AM EST)January 29;February 26
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            bymonthday =>  [ -3 ],
            )
            ->intersection( $period_1995_19980301 );

    is("".str($a), 
    '1997-09-28T09:00:00,' .
    '1997-10-29T09:00:00,1997-11-28T09:00:00,1997-12-29T09:00:00,' .
    '1998-01-29T09:00:00,1998-02-26T09:00:00',
    $title);





$title="***  Monthly on the 2nd and 15th of the month for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15
#
#     ==> (1997 9:00 AM EDT)September 2,15;October 2,15
#         (1997 9:00 AM EST)November 2,15;December 2,15
#         (1998 9:00 AM EST)January 2,15
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000,
            freq =>     'monthly',
            count =>    10,
            bymonthday =>  [ 2, 15 ],
            )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-15T09:00:00,' .
    '1997-10-02T09:00:00,1997-10-15T09:00:00,' .
    '1997-11-02T09:00:00,1997-11-15T09:00:00,' .
    '1997-12-02T09:00:00,1997-12-15T09:00:00,' .
    '1998-01-02T09:00:00,1998-01-15T09:00:00',
    $title);



$title="***  Monthly on the first and last day of the month for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970930T090000
#     recur_by_rule:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1
#
#     ==> (1997 9:00 AM EDT)September 30;October 1
#         (1997 9:00 AM EST)October 31;November 1,30;December 1,31
#         (1998 9:00 AM EST)January 1,31;February 1
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            count =>    10,
            bymonthday =>  [ 1, -1 ],
            )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-30T09:00:00,1997-10-01T09:00:00,' .
    '1997-10-31T09:00:00,1997-11-01T09:00:00,1997-11-30T09:00:00,' .
    '1997-12-01T09:00:00,1997-12-31T09:00:00,' .
    '1998-01-01T09:00:00,1998-01-31T09:00:00,' .
    '1998-02-01T09:00:00',
    $title);



$title="***  Every 18 months on the 10th thru 15th of the month for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970910T090000
#     recur_by_rule:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15
#
#     ==> (1997 9:00 AM EDT)September 10,11,12,13,14,15
#         (1999 9:00 AM EST)March 10,11,12,13
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970905T090000,
            freq =>     'monthly',
            interval => 18,
            count =>    10,
            bymonthday =>  [ 10 .. 15 ],
            )
            ->intersection( $period_1995_2000 );

    is("".str($a), 
        '1997-09-10T09:00:00,1997-09-11T09:00:00,' .
        '1997-09-12T09:00:00,1997-09-13T09:00:00,' .
        '1997-09-14T09:00:00,1997-09-15T09:00:00,' .
        '1999-03-10T09:00:00,1999-03-11T09:00:00,' .
        '1999-03-12T09:00:00,1999-03-13T09:00:00'
        , $title);


$title="***  Every Tuesday, every other month  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU
#
#     ==> (1997 9:00 AM EDT)September 2,9,16,23,30
#         (1997 9:00 AM EST)November 4,11,18,25
#         (1998 9:00 AM EST)January 6,13,20,27;March 3,10,17,24,31
#           ...
    $a = DateTime::Event::ICal->recur(
            dtstart =>     $dt19970902T090000,
            freq =>        'monthly',
            interval =>    2,
            byday =>       [ 'tu' ],
            )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-09T09:00:00,' .
        '1997-09-16T09:00:00,1997-09-23T09:00:00,1997-09-30T09:00:00,' .
        '1997-11-04T09:00:00,1997-11-11T09:00:00,' .
        '1997-11-18T09:00:00,1997-11-25T09:00:00,' .
        '1998-01-06T09:00:00,1998-01-13T09:00:00,' .
        '1998-01-20T09:00:00,1998-01-27T09:00:00,' .
        '1998-03-03T09:00:00,1998-03-10T09:00:00,' .
        '1998-03-17T09:00:00,1998-03-24T09:00:00,1998-03-31T09:00:00,' .
        '1998-05-05T09:00:00,1998-05-12T09:00:00,' .
        '1998-05-19T09:00:00,1998-05-26T09:00:00,1998-07-07T09:00:00,' .
        '1998-07-14T09:00:00,1998-07-21T09:00:00,1998-07-28T09:00:00,' .
        '1998-09-01T09:00:00,1998-09-08T09:00:00,1998-09-15T09:00:00,' .
        '1998-09-22T09:00:00,1998-09-29T09:00:00,1998-11-03T09:00:00,' .
        '1998-11-10T09:00:00,1998-11-17T09:00:00,1998-11-24T09:00:00'
        , $title);



$title="***  Yearly in June and July for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970610T090000
#     recur_by_rule:FREQ=YEARLY;COUNT=10;BYMONTH=6,7
#     ==> (1997 9:00 AM EDT)June 10;July 10
#         (1998 9:00 AM EDT)June 10;July 10
#         (1999 9:00 AM EDT)June 10;July 10
#         (2000 9:00 AM EDT)June 10;July 10
#         (2001 9:00 AM EDT)June 10;July 10
#     Note: Since none of the BYDAY, BYMONTHDAY or BYYEARDAY components
#     are specified, the day is gotten from DTSTART
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>     $dt19970610T090000,
            freq =>        'yearly',
            count    =>    10,
            bymonth =>     [ 6, 7 ],
            )
            ->intersection( $period_1995_2005 );

    is("".str($a), 
        '1997-06-10T09:00:00,1997-07-10T09:00:00,' .
        '1998-06-10T09:00:00,1998-07-10T09:00:00,' .
        '1999-06-10T09:00:00,1999-07-10T09:00:00,' .
        '2000-06-10T09:00:00,2000-07-10T09:00:00,' .
        '2001-06-10T09:00:00,2001-07-10T09:00:00', $title);



###### TEST 25

$title="***  Every other year on January, February, and March for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970310T090000
#     recur_by_rule:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3
#
#     ==> (1997 9:00 AM EST)March 10
#         (1999 9:00 AM EST)January 10;February 10;March 10
#         (2001 9:00 AM EST)January 10;February 10;March 10
#         (2003 9:00 AM EST)January 10;February 10;March 10
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>     $dt19970310T090000,
            freq =>        'yearly',
            interval =>    2,
            count    =>    10,
            bymonth =>     [ 1, 2, 3 ],
            )
            ->intersection( $period_1995_2004 );

    is("".str($a), 
        '1997-03-10T09:00:00,' .
        '1999-01-10T09:00:00,1999-02-10T09:00:00,1999-03-10T09:00:00,' .
        '2001-01-10T09:00:00,2001-02-10T09:00:00,2001-03-10T09:00:00,' .
        '2003-01-10T09:00:00,2003-02-10T09:00:00,2003-03-10T09:00:00', $title);


$title="***  Every 3rd year on the 1st, 100th and 200th day for 10 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970101T090000
#     recur_by_rule:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200
#
#     ==> (1997 9:00 AM EST)January 1
#         (1997 9:00 AM EDT)April 10;July 19
#         (2000 9:00 AM EST)January 1
#         (2000 9:00 AM EDT)April 9;July 18
#         (2003 9:00 AM EST)January 1
#         (2003 9:00 AM EDT)April 10;July 19
#         (2006 9:00 AM EST)January 1
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970101T090000 ,
            freq =>     'yearly',
            interval => 3,
            count   =>  10,
            byyearday => [ 1, 100, 200 ] )
            ->intersection( $period_1995_2007 );

    is("".str($a), 
    '1997-01-01T09:00:00,' .
    '1997-04-10T09:00:00,1997-07-19T09:00:00,' .
    '2000-01-01T09:00:00,' .
    '2000-04-09T09:00:00,2000-07-18T09:00:00,' .
    '2003-01-01T09:00:00,2003-04-10T09:00:00,2003-07-19T09:00:00,' .
    '2006-01-01T09:00:00',
    $title);

########### TEST 27

$title="***  Every 20th Monday of the year, forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970519T090000
#     recur_by_rule:FREQ=YEARLY;BYDAY=20MO
#
#     ==> (1997 9:00 AM EDT)May 19
#         (1998 9:00 AM EDT)May 18
#         (1999 9:00 AM EDT)May 17
#     ...
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970101T090000 ,
            freq =>     'yearly',
            byday =>    [ '20mo' ] )
            ->intersection( $period_1995_2000 );

    is("".str($a), 
        '1997-05-19T09:00:00,1998-05-18T09:00:00,1999-05-17T09:00:00', $title);

$title="***  Monday of week number 20 (where the default start of the week i  ***";
#   Monday), forever:
#
#     DTSTART;TZID=US-Eastern:19970512T090000
#     recur_by_rule:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO
#
#     ==> (1997 9:00 AM EDT)May 12
#         (1998 9:00 AM EDT)May 11
#         (1999 9:00 AM EDT)May 17
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970101T090000 ,
            freq =>     'yearly',
            byweekno => [ 20 ],
            byday =>    [ 'mo' ] )
            ->intersection( $period_1995_2000 );

    is("".str($a), 
        '1997-05-12T09:00:00,1998-05-11T09:00:00,1999-05-17T09:00:00', $title);

$title="***  Every Thursday in March, forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970313T090000
#     recur_by_rule:FREQ=YEARLY;BYMONTH=3;BYDAY=TH
#
#     ==> (1997 9:00 AM EST)March 13,20,27
#         (1998 9:00 AM EST)March 5,12,19,26
#         (1999 9:00 AM EST)March 4,11,18,25
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970310T090000 ,
            freq =>     'yearly',
            bymonth  => [ 3 ],
            byday =>    [ 'th' ] )
            ->intersection( $period_1995_2000 );

    is("".str($a), 
    '1997-03-13T09:00:00,1997-03-20T09:00:00,1997-03-27T09:00:00,' .
    '1998-03-05T09:00:00,1998-03-12T09:00:00,' .
    '1998-03-19T09:00:00,1998-03-26T09:00:00,' .
    '1999-03-04T09:00:00,1999-03-11T09:00:00,' .
    '1999-03-18T09:00:00,1999-03-25T09:00:00',
    $title);

$title="***  Every Thursday, but only during June, July, and August, forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970605T090000
#     recur_by_rule:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8
#
#     ==> (1997 9:00 AM EDT)June 5,12,19,26;July 3,10,17,24,31;
#                       August 7,14,21,28
#         (1998 9:00 AM EDT)June 4,11,18,25;July 2,9,16,23,30;
#                       August 6,13,20,27
#         (1999 9:00 AM EDT)June 3,10,17,24;July 1,8,15,22,29;
#                       August 5,12,19,26
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970310T090000 ,
            freq =>     'yearly',
            bymonth  => [ 6, 7, 8 ],
            byday =>    [ 'th' ] )
            ->intersection( $period_1995_2000 );

    is("".str($a),
    '1997-06-05T09:00:00,1997-06-12T09:00:00,' .
    '1997-06-19T09:00:00,1997-06-26T09:00:00,' .
    '1997-07-03T09:00:00,1997-07-10T09:00:00,' .
    '1997-07-17T09:00:00,1997-07-24T09:00:00,1997-07-31T09:00:00,' .
    '1997-08-07T09:00:00,1997-08-14T09:00:00,' .
    '1997-08-21T09:00:00,1997-08-28T09:00:00,' .

    '1998-06-04T09:00:00,1998-06-11T09:00:00,' .
    '1998-06-18T09:00:00,1998-06-25T09:00:00,' .
    '1998-07-02T09:00:00,1998-07-09T09:00:00,' .
    '1998-07-16T09:00:00,1998-07-23T09:00:00,1998-07-30T09:00:00,' .
    '1998-08-06T09:00:00,1998-08-13T09:00:00,' .
    '1998-08-20T09:00:00,1998-08-27T09:00:00,' .

    '1999-06-03T09:00:00,1999-06-10T09:00:00,' .
    '1999-06-17T09:00:00,1999-06-24T09:00:00,' .
    '1999-07-01T09:00:00,1999-07-08T09:00:00,' .
    '1999-07-15T09:00:00,1999-07-22T09:00:00,1999-07-29T09:00:00,' .
    '1999-08-05T09:00:00,1999-08-12T09:00:00,' .
    '1999-08-19T09:00:00,1999-08-26T09:00:00',
    $title);

$title="***  Every Friday the 13th, forever  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     EXDATE;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13
#
#     ==> (1998 9:00 AM EST)February 13;March 13;November 13
#         (1999 9:00 AM EDT)August 13
#         (2000 9:00 AM EDT)October 13
#     ...
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'monthly',
            bymonthday => [ 13 ],
            byday =>      [ 'fr' ] )
            ->intersection( $period_1995_2001 );
    # EXDATE doesn't make sense here, because the date is not in the set

    is("".str($a), 
    '1998-02-13T09:00:00,1998-03-13T09:00:00,1998-11-13T09:00:00,' .
    '1999-08-13T09:00:00,2000-10-13T09:00:00', $title);


$title="***  The first Saturday that follows the first Sunday of the month  ***";
#    forever:
#
#     DTSTART;TZID=US-Eastern:19970913T090000
#     recur_by_rule:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13
#
#     ==> (1997 9:00 AM EDT)September 13;October 11
#         (1997 9:00 AM EST)November 8;December 13
#         (1998 9:00 AM EST)January 10;February 7;March 7
#         (1998 9:00 AM EDT)April 11;May 9;June 13...
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>  $dt19970902T090000 ,
            freq =>     'monthly',
            bymonthday => [ 7,8,9,10,11,12,13 ],
            byday =>      [ 'sa' ] )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
    '1997-09-13T09:00:00,1997-10-11T09:00:00,' .
    '1997-11-08T09:00:00,1997-12-13T09:00:00,' .
    '1998-01-10T09:00:00,1998-02-07T09:00:00,1998-03-07T09:00:00,' .
    '1998-04-11T09:00:00,1998-05-09T09:00:00,1998-06-13T09:00:00,' .
    '1998-07-11T09:00:00,1998-08-08T09:00:00,1998-09-12T09:00:00,' .
    '1998-10-10T09:00:00,1998-11-07T09:00:00,1998-12-12T09:00:00',
    $title);


# test 33

$title="***  Every four years, the first Tuesday after a Monday in November  ***";
#   forever (U.S. Presidential Election day):
#
#     DTSTART;TZID=US-Eastern:19961105T090000
#     recur_by_rule:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,
#      5,6,7,8
#
#     ==> (1996 9:00 AM EST)November 5
#         (2000 9:00 AM EST)November 7
#         (2004 9:00 AM EST)November 2
#     ...
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19961105T090000 ,
            freq =>       'yearly',
            interval =>   4,
            bymonthday => [ 2,3,4,5,6,7,8 ],
            byday =>      [ 'tu' ],
            bymonth =>    [ 11 ], )
            ->intersection( $period_1995_2005 );

    is("".str($a), 
        '1996-11-05T09:00:00,2000-11-07T09:00:00,2004-11-02T09:00:00',
    $title);

# test 34

$title="***  The 3rd instance into the month of one of Tuesday, Wednesday or Thursday, for the next 3 months:  ***";
#
#     DTSTART;TZID=US-Eastern:19970904T090000
#     recur_by_rule:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3
#
#     ==> (1997 9:00 AM EDT)September 4;October 7
#         (1997 9:00 AM EST)November 6
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970904T090000 ,
            freq =>       'monthly',
            count =>      3,
            byday =>      [ 'tu', 'we', 'th' ],
            bysetpos =>   3 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-04T09:00:00,1997-10-07T09:00:00,1997-11-06T09:00:00', $title);


$title="***  The 2nd to last weekday of the month:  ***";
#
#     DTSTART;TZID=US-Eastern:19970929T090000
#     recur_by_rule:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2
#
#     ==> (1997 9:00 AM EDT)September 29
#         (1997 9:00 AM EST)October 30;November 27;December 30
#         (1998 9:00 AM EST)January 29;February 26;March 30
#     ...
#


    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970904T090000 ,
            freq =>       'monthly',
            byday =>      [ 'mo', 'tu', 'we', 'th', 'fr' ],
            bysetpos =>   -2 )
            ->intersection( $period_1995_19980401 );

    is("".str($a), 
        '1997-09-29T09:00:00,1997-10-30T09:00:00,' .
        '1997-11-27T09:00:00,1997-12-30T09:00:00,1998-01-29T09:00:00,' .
        '1998-02-26T09:00:00,1998-03-30T09:00:00', $title);


$title="***  Every 3 hours from 9:00 AM to 5:00 PM on a specific day  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=HOURLY;INTERVAL=3;UNTIL=1997-09-02T17:00:00
#
#     ==> (September 2, 1997 EDT)09:00,12:00,15:00
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970902T090000 ,
            freq =>       'hourly',
            interval =>   3,
            until =>      $dt19970902T170000 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-02T12:00:00,1997-09-02T15:00:00', $title);

$title="***  Every 15 minutes for 6 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=MINUTELY;INTERVAL=15;COUNT=6
#
#     ==> (September 2, 1997 EDT)09:00,09:15,' .
#        '09:30,09:45,10:00,10:15
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970902T090000 ,
            freq =>       'minutely',
            interval =>   15,
            count =>      6 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-02T09:15:00,' .
        '1997-09-02T09:30:00,1997-09-02T09:45:00,' .
        '1997-09-02T10:00:00,1997-09-02T10:15:00',
    $title);


$title="***  Every hour and a half for 4 occurrences  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=MINUTELY;INTERVAL=90;COUNT=4
#
#     ==> (September 2, 1997 EDT)09:00,10:30;12:00;13:30
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970902T090000 ,
            freq =>       'minutely',
            interval =>   90,
            count =>      4 )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-02T10:30:00,' .
        '1997-09-02T12:00:00,1997-09-02T13:30:00', $title);


########## TEST 39

$title="***  Every 20 minutes from 9:00 AM to 4:40 PM every day  ***";
#
#     DTSTART;TZID=US-Eastern:19970902T090000
#     recur_by_rule:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40
#     or
#     recur_by_rule:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16
#
#     ==> (September 2, 1997 EDT)9:00,9:20,' .
#        '9:40,10:00,10:20,
#                                ... 16:00,16:20,16:40
#         (September 3, 1997 EDT)9:00,9:20,' .
#        '9:40,10:00,10:20,
#                               ...16:00,16:20,16:40
#     ...
#

    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970902T090000 ,
            freq =>       'daily',
            byhour =>     [ 9,10,11,12,13,14,15,16 ],
            byminute =>   [ 0,20,40 ] )
            ->intersection( $period_1995_19970904T090000 );

    is("".str($a), 
        '1997-09-02T09:00:00,1997-09-02T09:20:00,' .
        '1997-09-02T09:40:00,1997-09-02T10:00:00,1997-09-02T10:20:00,' .
        '1997-09-02T10:40:00,1997-09-02T11:00:00,' .
        '1997-09-02T11:20:00,1997-09-02T11:40:00,1997-09-02T12:00:00,' .
        '1997-09-02T12:20:00,1997-09-02T12:40:00,' .
        '1997-09-02T13:00:00,1997-09-02T13:20:00,1997-09-02T13:40:00,' .
        '1997-09-02T14:00:00,1997-09-02T14:20:00,' .
        '1997-09-02T14:40:00,1997-09-02T15:00:00,1997-09-02T15:20:00,' .
        '1997-09-02T15:40:00,1997-09-02T16:00:00,' .
        '1997-09-02T16:20:00,1997-09-02T16:40:00,' .

        '1997-09-03T09:00:00,1997-09-03T09:20:00,' .
        '1997-09-03T09:40:00,1997-09-03T10:00:00,1997-09-03T10:20:00,' .
        '1997-09-03T10:40:00,1997-09-03T11:00:00,' .
        '1997-09-03T11:20:00,1997-09-03T11:40:00,1997-09-03T12:00:00,' .
        '1997-09-03T12:20:00,1997-09-03T12:40:00,' .
        '1997-09-03T13:00:00,1997-09-03T13:20:00,1997-09-03T13:40:00,' .
        '1997-09-03T14:00:00,1997-09-03T14:20:00,' .
        '1997-09-03T14:40:00,1997-09-03T15:00:00,1997-09-03T15:20:00,' .
        '1997-09-03T15:40:00,1997-09-03T16:00:00,' .
        '1997-09-03T16:20:00,1997-09-03T16:40:00,1997-09-04T09:00:00',
    $title);

#     recur_by_rule:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16


    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970902T090000 ,
            freq =>       'minutely',
            interval =>   20,
            byhour =>     [ 9,10,11,12,13,14,15,16 ], )
            ->intersection( $period_1995_19970904T090000 );

    is("".str($a),
        '1997-09-02T09:00:00,1997-09-02T09:20:00,' .
        '1997-09-02T09:40:00,1997-09-02T10:00:00,1997-09-02T10:20:00,' .
        '1997-09-02T10:40:00,1997-09-02T11:00:00,' .
        '1997-09-02T11:20:00,1997-09-02T11:40:00,1997-09-02T12:00:00,' .
        '1997-09-02T12:20:00,1997-09-02T12:40:00,' .
        '1997-09-02T13:00:00,1997-09-02T13:20:00,1997-09-02T13:40:00,' .
        '1997-09-02T14:00:00,1997-09-02T14:20:00,' .
        '1997-09-02T14:40:00,1997-09-02T15:00:00,1997-09-02T15:20:00,' .
        '1997-09-02T15:40:00,1997-09-02T16:00:00,' .
        '1997-09-02T16:20:00,1997-09-02T16:40:00,' .

        '1997-09-03T09:00:00,1997-09-03T09:20:00,' .
        '1997-09-03T09:40:00,1997-09-03T10:00:00,1997-09-03T10:20:00,' .
        '1997-09-03T10:40:00,1997-09-03T11:00:00,' .
        '1997-09-03T11:20:00,1997-09-03T11:40:00,1997-09-03T12:00:00,' .
        '1997-09-03T12:20:00,1997-09-03T12:40:00,' .
        '1997-09-03T13:00:00,1997-09-03T13:20:00,1997-09-03T13:40:00,' .
        '1997-09-03T14:00:00,1997-09-03T14:20:00,' .
        '1997-09-03T14:40:00,1997-09-03T15:00:00,1997-09-03T15:20:00,' .
        '1997-09-03T15:40:00,1997-09-03T16:00:00,' .
        '1997-09-03T16:20:00,1997-09-03T16:40:00,1997-09-04T09:00:00',
    $title);


$title="***  An example where the days generated makes a difference because of WKST  ***";
#
#     DTSTART;TZID=US-Eastern:19970805T090000
#     recur_by_rule:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO
#
#     ==> (1997 EDT)Aug 5,10,19,24
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970805T090000 ,
            freq =>       'weekly',
            interval =>   2,
            count =>      4,
            byday =>      [ 'tu', 'su' ], 
            wkst =>       'mo' )
            ->intersection( $period_1995_1999 );

    is("".str($a), 
        '1997-08-05T09:00:00,1997-08-10T09:00:00,' .
        '1997-08-19T09:00:00,1997-08-24T09:00:00', $title);

$title="***  changing only WKST from MO to SU, yields different results...  ***";
#
#     DTSTART;TZID=US-Eastern:19970805T090000
#     recur_by_rule:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU
#     ==> (1997 EDT)August 5,17,19,31
#
    $a = DateTime::Event::ICal->recur(
            dtstart =>    $dt19970805T090000 ,
            freq =>       'weekly',
            interval =>   2,
            count =>      4,
            byday =>      [ 'tu', 'su' ],
            wkst =>       'su' )
            ->intersection( $period_1995_1999 );


    is("".str($a), 
        '1997-08-05T09:00:00,1997-08-17T09:00:00,' .
        '1997-08-19T09:00:00,1997-08-31T09:00:00', $title);

__END__
    # another test using this result:
    is( "" . $a->exclude_by_date( list => ['1997-08-17T09:00:00', '1997-08-31T09:00:00'] ) ,
        '1997-08-05T09:00:00,1997-08-19T09:00:00', "***  EXDATE removing 2 days  ***" );

    # yet another test using this result:
    is( "" . $a->recur_by_date( list => ['19970817Z', '19970831Z'] ) ,
        '1997-08-05T09:00:00,19970817Z,1997-08-17T09:00:00,' .
        '1997-08-19T09:00:00,19970831Z,1997-08-31T09:00:00', "***  RDATE adding 2 days  ***" );

$a = Date::Set->event(
    dtstart => '1970-03-29T02:00:00',
    rule => 'FREQ=MONTHLY;BYMONTH=3;BYDAY=-3SU',
    start=>'2003-01-01T00:00:00', end=>'2005-01-01T00:00:00' );
is ( "". $a ,
  '2003-03-16T02:00:00,2004-03-14T02:00:00',
  'BYDAY works well with FREQ=MONTH' );

$a = Date::Set->event(
    dtstart => '1970-03-29T02:00:00',
    rule => 'FREQ=YEARLY;BYMONTH=3;BYDAY=-3SU',
    start=> '2003-01-01T00:00:00', end=>'2005-01-01T00:00:00' );
is ( "". $a ,
  '2003-03-16T02:00:00,2004-03-14T02:00:00',
  'BYDAY works well with FREQ=YEARLY;BYMONTH' );


1;
