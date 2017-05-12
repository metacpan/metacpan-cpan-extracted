#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;

use DateTimeX::Lite qw(Arithmetic);
use DateTimeX::Lite::Duration;

{
    my $dt = DateTimeX::Lite->new( year => 2008, month => 2, day => 28 );
    my $du = DateTimeX::Lite::Duration->new( years => 1 );

    my $p;

    $p = $dt->set( year => 1882 );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "set() returns self" );

    $p = $dt->set_time_zone( 'Australia/Sydney' );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "set_time_zone() returns self" );

    $p = $dt->add_duration( $du );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "add_duration() returns self" );

    $p = $dt->add( years => 2 );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "add() returns self" );


    $p = $dt->subtract_duration( $du );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "subtract_duration() returns self" );

    $p = $dt->subtract( years => 3 );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "subtract() returns self" );

    $p = $dt->truncate( to => 'day' );
    is( DateTimeX::Lite->compare( $p, $dt ), 0, "truncate() returns self" );

}
