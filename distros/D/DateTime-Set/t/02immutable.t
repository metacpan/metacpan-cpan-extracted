#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 11;

use DateTime;
use DateTime::Set;

#======================================================================
# SET ELEMENT IMMUTABILITY TESTS
#====================================================================== 

my $t1 = new DateTime( year => '1810', month => '11', day => '22' );
my $t2 = new DateTime( year => '1900', month => '11', day => '22' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

ok( $s1->min->ymd eq '1810-11-22', 
    'got 1810-11-22 - min' );

$t1->add( days => 3 );

ok( $t1->ymd eq '1810-11-25',
    'change object to 1810-11-25' );

ok( $s1->min->ymd eq '1810-11-22',
    'still getting '. $s1->min->ymd . ' - after changing original object' );

$s1->set_time_zone( 'America/Sao_Paulo' );
is( $s1->min->time_zone_long_name, 'America/Sao_Paulo',
    'changing object time zone in place' );

$s1->add( hours => 2 );
is( $s1->min->hour, 2 ,
    'changing object hour in place' );

# map

{
my $s2 = $s1->map( sub { $_->add( days => 2 ) } );
isa_ok( $s2, 'DateTime::Set' );
is( $s2->min->ymd.",".$s2->max->ymd, "1810-11-24,1900-11-24", "map" );
is( $s1->min->ymd.",".$s1->max->ymd, "1810-11-22,1900-11-22", "map does not mutate set" );
}

# grep

{
my $t = new DateTime( year => '1850' );
my $s2 = $s1->grep( sub { $_ > $t } );
isa_ok( $s2, 'DateTime::Set' );
is( $s2->min->ymd.",".$s2->max->ymd, "1900-11-22,1900-11-22", "grep" );
is( $s1->min->ymd.",".$s1->max->ymd, "1810-11-22,1900-11-22", "grep does not mutate set" );
}

1;

