#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;

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
    my $sum = 0;
    my $count = 0;
    for ( 1 .. 5 ) {
        my $daily = DateTime::Event::Random->new;
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
    ok( $mean > 8 && $mean < 32,
        "Average days in span = $mean, expected about 20" );

}


my $sum1 = 0;
my $count1 = 0;
my $todo_count = 10;
for my $unit ( qw( nanoseconds seconds minutes hours days weeks months years ) )
{
    my $sum = 0;
    my $count = 0;
    for ( 1 .. 5 ) {
        my $daily = DateTime::Event::Random->new( $unit => 200 );
        my @dt = $daily->as_list( 
                     start => $dt1, 
                     end =>   $dt1->clone->add( $unit => 200 * $todo_count ) );
        # warn "Count is ".( 1 + $#dt)." $unit\n";
        $sum += 1 + $#dt;
        $count++;
        # my $r = join(' ', map { $_->datetime } @dt);
        # is( $r,
        #    ' ? ',
        #    "as_list" );
    }
    my $mean = $sum/$count;
    ok( $mean > ( 0.4 * $todo_count ) && 
        $mean < ( 1.6 * $todo_count ),
        "Average $unit in span = $mean, expected about $todo_count" );

    $sum1 += $mean;
    $count1 ++;
}
my $mean1 = $sum1/$count1;
ok( $mean1 > ( 0.4 * $todo_count ) && 
    $mean1 < ( 1.6 * $todo_count ),
    "Average mean = $mean1, expected close to $todo_count" );

{
my $dur = DateTime::Event::Random->duration;
ok( UNIVERSAL::isa( $dur, "DateTime::Duration" ),
    "duration() generates a duration: ".
       join(" ", $dur->deltas ) );

my $dt = DateTime::Event::Random->datetime;
ok( UNIVERSAL::isa( $dt, "DateTime" ),
    "datetime() generates a datetime: ".
       $dt->datetime  );
}

