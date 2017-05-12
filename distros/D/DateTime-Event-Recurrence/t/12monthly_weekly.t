#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;
use DateTime;
use DateTime::Event::Recurrence;


    my $dt1 = new DateTime( year => 1997, month => 9, day => 1,
            time_zone => 'UTC' );

    my $dt2 = new DateTime( year => 1998, month => 6, day => 1,
                           time_zone => 'UTC' );
    
{
    my $monthly = monthly DateTime::Event::Recurrence(
           week_start_day => '1fr', weeks => 1, hours => 9 );

    my @dt = $monthly->as_list( start => $dt1, end => $dt2 );
    my $r = join(',', map { $_->datetime } @dt);
    is( $r, 
        '1997-09-05T09:00:00,1997-10-03T09:00:00,1997-11-07T09:00:00,'.
        '1997-12-05T09:00:00,1998-01-02T09:00:00,1998-02-06T09:00:00,'.
        '1998-03-06T09:00:00,1998-04-03T09:00:00,1998-05-01T09:00:00',
        "monthly-weekly" );
}

{
    my $monthly = monthly DateTime::Event::Recurrence(
           week_start_day => 'fr', weeks => 1, hours => 9 );

    my @dt = $monthly->as_list( start => $dt1, end => $dt2 );
    my $r = join(',', map { $_->datetime } @dt);
    is( $r, 
        '1997-10-03T09:00:00,1997-10-31T09:00:00,'.
        '1997-11-28T09:00:00,1998-01-02T09:00:00,'.
        '1998-01-30T09:00:00,1998-02-27T09:00:00,'.
        '1998-04-03T09:00:00,1998-05-01T09:00:00,1998-05-29T09:00:00',
        "monthly-weekly" );
}

