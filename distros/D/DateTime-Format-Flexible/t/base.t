#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::MockTime ();

use DateTime::Format::Flexible;
my $base = 'DateTime::Format::Flexible';

# my ( $base_dt ) = $base->parse_datetime( '2005-06-07T13:14:15' );
# $base->base( $base_dt );

my $base_dt = DateTime->new( year => 2009, month => 6, day => 22 );

{
    my $dt  = DateTime::Format::Flexible->parse_datetime( 'now' );
    Test::MockTime::set_relative_time( 120 );
    my $dt2 = DateTime::Format::Flexible->parse_datetime( 'now' );

    isnt( $dt->datetime, $dt2->datetime, 'parsing now is not always the same as module load' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '23:59',
        base => $base_dt
    );
    is( $dt->datetime, '2009-06-22T23:59:00' , 'base works with just a time' );
}
{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        'now',
        base => $base_dt
    );
    is( $dt->datetime, '2009-06-22T00:00:00', 'base works with a string' );
}
