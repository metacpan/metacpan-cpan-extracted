#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
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
           days => 40 );

    my @dt = $yearly->as_list( start => $dt1, end => $dt2 );
    my $r = join(' ', map { $_->datetime } @dt);
    is( $r, 
        '2004-02-09T00:00:00 2005-02-09T00:00:00 2006-02-09T00:00:00',
        "yearly-by-day" );
}
