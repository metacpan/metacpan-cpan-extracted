#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 38;
use DateTime;

use t::lib::helper;

my $curr_year = DateTime->now->year;

t::lib::helper::run_tests(
    "5-8   => $curr_year-05-08T00:00:00" ,
    "10-8  => $curr_year-10-08T00:00:00" ,
    "5-08  => $curr_year-05-08T00:00:00" ,
    "05-08 => $curr_year-05-08T00:00:00" ,

    "18-Mar   => $curr_year-03-18T00:00:00" ,
    "8-Mar    => $curr_year-03-08T00:00:00" ,
    "Mar-18   => $curr_year-03-18T00:00:00" ,
    "Mar-8    => $curr_year-03-08T00:00:00" ,
    "Dec-18   => $curr_year-12-18T00:00:00" ,
    "Dec-8    => $curr_year-12-08T00:00:00" ,
    "March-18 => $curr_year-03-18T00:00:00" ,
    "Dec-18   => $curr_year-12-18T00:00:00" ,

    "21 dec 17:05     => $curr_year-12-21T17:05:00" ,
    "21-dec 17:05     => $curr_year-12-21T17:05:00" ,
    "21/dec 17:05     => $curr_year-12-21T17:05:00" ,
    "///Dec///08      => $curr_year-12-08T00:00:00" ,
    "///Dec///08///// => $curr_year-12-08T00:00:00" ,
    "8:00pm December tenth => $curr_year-12-10T20:00:00",
    "Dec/10 at 05:30:25 => $curr_year-12-10T05:30:25",
    "Dec/10 at 05:30:25 GMT => $curr_year-12-10T05:30:25",
    "December/10 => $curr_year-12-10T00:00:00",
    "12/10 at 05:30:25 => $curr_year-12-10T05:30:25",
    "12/10 at 05:30:25 GMT => $curr_year-12-10T05:30:25 => UTC",

    "4:50:40DeC10 => $curr_year-12-10T04:50:40",
    "4:50:42DeCember10 => $curr_year-12-10T04:50:42",
    "4:50:5110DeC => $curr_year-12-10T04:50:51",
    "4:50:5210DeCember => $curr_year-12-10T04:50:52",
    "4:50:53 10DeC => $curr_year-12-10T04:50:53",
    "4:50:5410DeCember => $curr_year-12-10T04:50:54",
    "4:50:54DeCember10 => $curr_year-12-10T04:50:54",
    "4:50DeC10 => $curr_year-12-10T04:50:00",
    "4:50DeCember10 => $curr_year-12-10T04:50:00",

    "february 1st => $curr_year-02-01T00:00:00",
    "5:30 12-10 => $curr_year-12-10T05:30:00",
    "5:30 12/10 => $curr_year-12-10T05:30:00",
    "5:30 DeC 1 => $curr_year-12-01T05:30:00",
    "5:30 DeCember 1 => $curr_year-12-01T05:30:00",

);
