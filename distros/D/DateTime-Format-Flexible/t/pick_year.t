#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 6;
use DateTime;

use t::lib::helper;

use DateTime::Format::Flexible;

my $base = 'DateTime::Format::Flexible';
my $curr_year = DateTime->now->year;

{
    my $dt = DateTime->new( year => 2006 );
    is( $base->_pick_year( '06' , $dt->clone ) , '2006' , '06 becomes 2006 in 2006' );
    is( $base->_pick_year( 6 ,    $dt->clone ) , '2006' , '6 becomes 2006 in 2006' );
}
{
    my $dt = DateTime->new( year => 1999 );
    is( $base->_pick_year( '06' , $dt->clone ) , '2006' , '06 becomes 2006 in 1999' );
    is( $base->_pick_year( 98 ,   $dt->clone ) , '1998' , '98 becomes 1998 in 1999' );
}
{
    my $dt = DateTime->new( year => 1969 );
    is( $base->_pick_year( 50 , $dt->clone ) , '1950' , '50 becomes 1950 in 1969' );
    is( $base->_pick_year( 5 ,  $dt->clone ) , '1905' , '5 becomes 1905 in 1969' );
}
