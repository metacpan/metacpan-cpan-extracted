#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
use DateTime;
use DateTime::Incomplete;

my $UNDEF_CHAR = 'x';
my $UNDEF4 = $UNDEF_CHAR x 4;
my $UNDEF2 = $UNDEF_CHAR x 2;

{
    my $dti;
    my $dt = DateTime->new( year => 2003 );
    my $error;

    $dti = DateTime::Incomplete->new( 
        year =>   $dt->year,
        month =>  $dt->month,
        day =>    $dt->day,
        hour =>   $dt->hour,
        minute => $dt->minute,
        second => $dt->second,
        nanosecond => $dt->nanosecond,
    );

    is( $dti->day_name , $dt->day_name, 
        'DTI->day_name matches DT->day_name' );

    $dti->set( year => undef );
    ok( ! defined $dti->day_name ,
        'day_name checks for valid parameter' );

    is( $dti->offset , $dt->offset,
        'DTI->offset matches DT->offset' );

    $dt->set_time_zone( 'America/Chicago' );
    $dti->set_time_zone( 'America/Chicago' );
    is( $dti->offset , $dt->offset,
        'DTI->offset matches DT->offset' );

    $dti->set( year => undef );
    ok( ! defined $dti->is_leap_year ,
        'is_leap_year checks for valid parameter' );
}

{
    my $dti;

    $dti = DateTime::Incomplete->now;
    ok( defined $dti ,
        "now() doesn't die: ".$dti->datetime );

    $dti = DateTime::Incomplete->today;
    my $str_today = $dti->datetime;
    ok( defined $dti ,
        "today() doesn't die: ".$str_today );

    $str_today =~ s/$UNDEF2:$UNDEF2$/00:00/;
    $dti->truncate( to => 'hour' );
    is( $dti->datetime , $str_today ,
        "truncate() defines min:sec ".$str_today );

    $dti = DateTime::Incomplete->from_epoch( epoch => 0 );
    ok( defined $dti ,
        "from_epoch() doesn't die: ".$dti->datetime );
}

1;

