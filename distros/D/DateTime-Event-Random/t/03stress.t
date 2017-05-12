#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

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
        my $daily = DateTime::Event::Random->new( nanoseconds => 50 );
        my @dt = $daily->as_list( 
           start => $dt1, 
           end =>   $dt1 + DateTime::Duration->new( nanoseconds => 1000 ) );
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
        "Average days in 50 nanoseconds span = $mean, expected about 20" );

}

{
    my $sum = 0;
    my $count = 0;
    for ( 1 .. 5 ) {
        my $daily = DateTime::Event::Random->new( years => 500 );
        my @dt = $daily->as_list(
           start => $dt1,
           end =>   $dt1 + DateTime::Duration->new( years => 5000 ) );
        # warn "Count is ".( 1 + $#dt)." days\n";
        $sum += 1 + $#dt;
        $count++;
        # my $r = join(' ', map { $_->datetime } @dt);
        # is( $r,
        #    '2003-04-29T00:00:00 2003-04-30T00:00:00 2003-05-01T00:00:00',
        #    "as_list" );
    }
    my $mean = $sum/$count;
    ok( $mean > 4 && $mean < 16,
        "Average days in span = $mean, expected about 10" );

}

{
my $dur = DateTime::Event::Random->duration( nanoseconds => 50 );
ok( UNIVERSAL::isa( $dur, "DateTime::Duration" ),
    "50 nanoseconds duration() generates a duration: ".
       join(" ", $dur->deltas ) );
}

{
my $dur = DateTime::Event::Random->duration( years => 500 );
ok( UNIVERSAL::isa( $dur, "DateTime::Duration" ),
    "500 years duration() generates a duration: ".
       join(" ", $dur->deltas ) );
}

{
my $dt = DateTime::Event::Random->datetime( 
    after =>  DateTime->new( year => 2000 ),
    before => DateTime->new( year => 2000, nanosecond => 50 ) );
ok( UNIVERSAL::isa( $dt, "DateTime" ),
    "50 nanoseconds span datetime() generates a datetime: ".
       $dt->datetime . $dt->strftime( ".%N" ) );
}

{
my $dt = DateTime::Event::Random->datetime(
    after =>  DateTime->new( year => 2000 ),
    before => DateTime->new( year => 2500 ) );
ok( UNIVERSAL::isa( $dt, "DateTime" ),
    "500 years span datetime() generates a datetime: ".
       $dt->datetime . $dt->strftime( ".%N" ) );
}

