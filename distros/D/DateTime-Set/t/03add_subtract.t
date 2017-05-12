#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 6;

use DateTime;
use DateTime::Duration;
use DateTime::Set;

#======================================================================
# ADD/SUBRACT DURATION ("OFFSET") TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

my $dur1 = new DateTime::Duration ( years => 1 );
my $s2 = $s1->add_duration( $dur1 );

is( $s2->count, 2, "count" );

is( $s2->min->ymd, '1811-11-22', 
    'got 1811-11-22 - min' );

$s2 = $s2->clone->add( months => 1 );
is( $s2->min->ymd, '1811-12-22',
    'got 1811-12-22 - min' );

my $s3 = $s2->clone->subtract_duration( DateTime::Duration->new( months => 1 ) );
is( $s3->min->ymd, '1811-11-22',
    'got 1811-11-22 - min' );

my $s4 = $s3->clone->subtract( years => 1 );
is( $s4->min->ymd, '1810-11-22',
    'got 1810-11-22 - min' );

# check for immutability
is( $s2->min->ymd, '1811-12-22',
    'got 1811-12-22 - min' );


1;

