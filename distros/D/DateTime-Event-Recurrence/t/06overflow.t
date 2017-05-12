#!/usr/bin/perl -w

use strict;

use Test::More tests => 35;

use DateTime;
use DateTime::Event::Recurrence;

{
# multiple overflows

    my $dt1 = new DateTime( year => 2004, month => 3, day => 3,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $yearly = yearly DateTime::Event::Recurrence (
        months => [ 2, 12 ],
        days =>   [ 1 .. 31 ],
        hours =>  12,
        minutes => 10,
        seconds => 45,
    );

    my $dt;

    $dt = $yearly->next( $dt1 );
    is ( 
        $dt->datetime, '2004-12-01T12:10:45', 
        'next - multiple overflows' );
    $dt = $yearly->previous( $dt1 );
    is ( 
        $dt->datetime, '2004-02-29T12:10:45', 
        'previous - multiple overflows' );
}

{
# multiple overflows - negative indexes

    my $dt1 = new DateTime( year => 2004, month => 3, day => 3,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $yearly = yearly DateTime::Event::Recurrence (
        months => [ 2, 12 ],
        days =>   [ -31 .. -1 ],
        hours =>  12,
        minutes => 10,
        seconds => 45,
    );

    my $dt;

    $dt = $yearly->next( $dt1 );
    is (
        $dt->datetime, '2004-12-01T12:10:45', 
        'next - multiple overflows - negative' );
    $dt = $yearly->previous( $dt1 );
    is (
        $dt->datetime, '2004-02-29T12:10:45', 
        'previous - multiple overflows - negative' );
}

{
# two options, two levels

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = monthly DateTime::Event::Recurrence (
        days => [ 31, 15 ],
        minutes => [ 20, 30 ] );

    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt->datetime, '2003-05-15T00:20:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-05-15T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-05-31T00:20:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-05-31T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-06-15T00:20:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-06-15T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-07-15T00:20:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-07-15T00:30:00', 'next' );

#  TODO: {
#    local $TODO = "binary search breaks overflow checks";
    # PREVIOUS
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-07-15T00:20:00', 'previous' );

    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-06-15T00:30:00', 'previous' );
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-06-15T00:20:00', 'previous' );

    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-05-31T00:30:00', 'previous' );
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-05-31T00:20:00', 'previous' );

    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-05-15T00:30:00', 'previous' );
#  }

}


{
# two options

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = monthly DateTime::Event::Recurrence ( 
        days => [ 31, 15 ],
        minutes => [ 30 ] );

    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt->datetime, '2003-05-15T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-05-31T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-06-15T00:30:00', 'next' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-07-15T00:30:00', 'next' );

#  TODO: {
#    local $TODO = "binary search breaks overflow checks";
    # PREVIOUS
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-06-15T00:30:00', 'previous' );
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-05-31T00:30:00', 'previous' );
    $dt = $month->previous( $dt );
    is ( $dt->datetime, '2003-05-15T00:30:00', 'previous' );
#  }

}

{
# only one option

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = monthly DateTime::Event::Recurrence (
        days => [ 31 ],
        minutes => [ 30 ] );

    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt->datetime, '2003-05-31T00:30:00', 'next - only one option' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-07-31T00:30:00', 'next - only one option' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-08-31T00:30:00', 'next - only one option' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-10-31T00:30:00', 'next - only one option' );

}

{
# invalid value

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = monthly DateTime::Event::Recurrence (
        days => [ 32 ],
        minutes => [ 30 ] );

    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt, undef, 'next - with an invalid value' );
}

{
# detects an invalid argument

    my $month;
    eval {
        $month = monthly DateTime::Event::Recurrence (
                    months => [ 2 ],
                 );
    };
    is ( $month, undef, 'detects an invalid argument' );
}

{
# february-30

    my $dt1 = new DateTime( year => 2003, month => 1, day => 30,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = yearly DateTime::Event::Recurrence (
                 months => 2,
                 days => 30
             );
    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt, undef, 'next - feb-30' );

}

{
# february-29

    my $dt1 = new DateTime( year => 2003, month => 1, day => 20,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $month = monthly DateTime::Event::Recurrence (
        days => [ 29 ],
    );

    my $dt;

    $dt = $month->next( $dt1 );
    is ( $dt->datetime, '2003-01-29T00:00:00', 'next - feb-29' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-03-29T00:00:00', 'next - feb-29' );
    $dt = $month->next( $dt );
    is ( $dt->datetime, '2003-04-29T00:00:00', 'next - feb-29' );

}

