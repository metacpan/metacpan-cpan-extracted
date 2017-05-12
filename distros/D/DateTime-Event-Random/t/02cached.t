#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

use DateTime;
use DateTime::Event::Random;

    my $dt1 = new DateTime( year => 2003, month => 4, day => 1,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

    my $dt2 = new DateTime( year => 2003, month => 4, day => 21,
                           hour => 12, minute => 10, second => 45,
                           nanosecond => 123456,
                           time_zone => 'UTC' );

{
    my $daily = DateTime::Event::Random->new_cached;
    my $dt_1 = $daily->next( $dt1 );
#warn "dt1           ". $dt1->datetime . "\n";
#warn "next=dt_1     ". $dt_1->datetime . "\n";
    my $dt_2 = $daily->next( $dt_1 );
#warn "next=dt_2     ". $dt_2->datetime . "\n";
    my $dt_3 = $daily->previous( $dt_2 );
#warn "previous=dt_3 ". $dt_3->datetime . "\n";
    my $tmp = join(" ", $dt_1->datetime, $dt_2->datetime, $dt_3->datetime );

    ok( $dt_1 == $dt_3,
        "next/next/previous compare ok: $tmp" );
}

{
    my $sum = 0;
    my $count = 0;
    for ( 1 .. 5 ) {
        my $daily = DateTime::Event::Random->new_cached;
        my @dt = $daily->as_list( start => $dt1, end => $dt2 );
        # warn "Count is ".( 1 + $#dt)." days\n";
        $sum += 1 + $#dt;
        $count++;
        my $r = join(' ', map { $_->datetime } @dt);
        # warn "# r=$r\n";
        # is( $r, 
        #    '2003-04-29T00:00:00 2003-04-30T00:00:00 2003-05-01T00:00:00',
        #    "as_list" );
    }
    my $mean = $sum/$count;
    ok( $mean > 8 && $mean < 36,
        "Average days in span = $mean, expected about 20" );

}

{
    my $sum = 0;
    my $count = 0;
    for ( 1 .. 5 ) {
        my $daily = DateTime::Event::Random->new_cached( days => 2 );
        my @dt = $daily->as_list( start => $dt1, end => $dt2 );
        # warn "Count is ".( 1 + $#dt)." days\n";
        $sum += 1 + $#dt;
        $count++;
        # my $r = join(' ', map { $_->datetime } @dt);
        # is( $r,
        #    '2003-04-29T00:00:00 2003-04-30T00:00:00 2003-05-01T00:00:00',
        #    "as_list" );
    }
    my $mean = $sum/$count;
    ok( $mean > 4 && $mean < 18,
        "Average days in span = $mean, expected about 10" );

}

