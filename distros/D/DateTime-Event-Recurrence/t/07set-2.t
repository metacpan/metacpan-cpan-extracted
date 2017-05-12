#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;

use DateTime;
use DateTime::SpanSet;
use DateTime::Event::Recurrence;

sub str { ref($_[0]) ? $_[0]->datetime : $_[0] }
sub span_str { str($_[0]->min) . '..' . str($_[0]->max) }

{
    # INTERSECTION

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $r1 = yearly DateTime::Event::Recurrence ( 
        months =>  [ 10, 14 ],
        days =>    [ 15 ],
        hours =>   [ 14 ],
        minutes => [ 15 ] );
    my $r2 = daily DateTime::Event::Recurrence (
        hours =>   [ 10, 14 ],
        minutes => [ 15 ] );

    my $dt;

    my $r = $r1->intersection( $r2 );

    $dt = $r->next( $dt1 );
    is ( $dt->datetime, '2003-10-15T14:15:00', 'next intersection' );
    $dt = $r->next( $dt );
    is ( $dt->datetime, '2004-10-15T14:15:00', 'next intersection' );
    $dt = $r->next( $dt );
    is ( $dt->datetime, '2005-10-15T14:15:00', 'next intersection' );
}

{
    # NO-INTERSECTION

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $r1 = yearly DateTime::Event::Recurrence (
        months =>  [ 10, 14 ],
        days =>    [ 15 ],
        hours =>   [ 14 ],
        minutes => [ 15 ] );

    my $r2 = daily DateTime::Event::Recurrence (
        hours =>   [ 11, 15 ],
        minutes => [ 15 ] );

    my $dt;

    my $r = $r1->intersection( $r2 );

    $dt = $r->next( $dt1 );
    is ( $dt, undef, 'next no-intersection' );
}


{
    # BUILD SPAN-SET

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $r1 = yearly DateTime::Event::Recurrence (
        months =>  [ 9, 11 ],
        days =>    [ 15 ],
        hours =>   [ 14 ] );

    my $r = DateTime::SpanSet->from_set_and_duration(
          set => $r1,
          hours => 1,
       );

    my $span;
    my $s;

    # test Set
    my $iterator =
        $r1->intersection( DateTime::Span->new( after => $dt1 ) )
          ->iterator;
    $span = $iterator->next;
    $s = str( $span );
    is ( $s, '2003-09-15T14:00:00', 'next set' );
    $span = $iterator->next;
    $s = str( $span );
    is ( $s, '2003-11-15T14:00:00', 'next set' );

    # test SpanSet
    $iterator = 
        $r->intersection( DateTime::Span->new( after => $dt1 ) )
          ->iterator;
    $span = $iterator->next;
    $s = span_str( $span );  
    is ( $s, '2003-09-15T14:00:00..2003-09-15T15:00:00', 'next span-set' );
    $span = $iterator->next;
    $s = span_str( $span );
    is ( $s, '2003-11-15T14:00:00..2003-11-15T15:00:00', 'next span-set' );

}

{
    # INTERSECTION TO SPAN-SET

    my $dt1 = new DateTime( year => 2003, month => 4, day => 28,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $r1 = yearly DateTime::Event::Recurrence (
        months =>  [ 10, 14 ],
        days =>    [ 15 ],
        hours =>   [ 14 ] );

    my $rs1 = DateTime::SpanSet->from_set_and_duration( 
          set => $r1,
          hours => 1, 
       );

    my $r2 = daily DateTime::Event::Recurrence (
        minutes => [ 15 ] );

    my $dt;

    my $r = $r2->intersection( $rs1 );

    $dt = $r->next( $dt1 );
    is ( $dt, undef, 'next intersection to span-set' );
}

