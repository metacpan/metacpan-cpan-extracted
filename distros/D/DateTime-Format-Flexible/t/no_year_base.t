#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 21;
use DateTime;
use DateTime::Format::Flexible;
my $base = 'DateTime::Format::Flexible';

use t::lib::helper;

my $curr_year = DateTime->now->year;

my ( $base_dt ) = $base->parse_datetime( '2005-06-07' );
$base->base( $base_dt );

t::lib::helper::run_tests(
    "5-8   => 2005-05-08T00:00:00" ,
    "10-8  => 2005-10-08T00:00:00" ,
    "5-08  => 2005-05-08T00:00:00" ,
    "05-08 => 2005-05-08T00:00:00" ,

    "18-Mar   => 2005-03-18T00:00:00" ,
    "8-Mar    => 2005-03-08T00:00:00" ,
    "Mar-18   => 2005-03-18T00:00:00" ,
    "Mar-8    => 2005-03-08T00:00:00" ,
    "Dec-18   => 2005-12-18T00:00:00" ,
    "Dec-8    => 2005-12-08T00:00:00" ,
    "March-18 => 2005-03-18T00:00:00" ,
    "Dec-18   => 2005-12-18T00:00:00" ,

    "21 dec 17:05     => 2005-12-21T17:05:00" ,
    "21-dec 17:05     => 2005-12-21T17:05:00" ,
    "21/dec 17:05     => 2005-12-21T17:05:00" ,
    "///Dec///08      => 2005-12-08T00:00:00" ,
    "///Dec///08///// => 2005-12-08T00:00:00" ,
    "8:00pm December tenth => 2005-12-10T20:00:00",
    "12/10 at 05:30:25 => 2005-12-10T05:30:25",
    "12/10 at 05:30:25 GMT => 2005-12-10T05:30:25 => UTC",
);
