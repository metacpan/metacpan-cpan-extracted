#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 24;
use DateTime;

use t::lib::helper;

my $today = DateTime->now->ymd;

t::lib::helper::run_tests(
    "23:59:59   => ${today}T23:59:59" ,
    "23:59      => ${today}T23:59:00" ,
    "1:00 a.m.  => ${today}T01:00:00" ,
    "00:00      => ${today}T00:00:00" ,
    "12:00      => ${today}T12:00:00" ,
    "12:00 a.m. => ${today}T00:00:00" ,
    "12:00 p.m. => ${today}T12:00:00" ,
    "noon       => ${today}T12:00:00" ,
    "midnight   => ${today}T00:00:00" ,
    "12:01 a.m. => ${today}T00:01:00" ,
    "12:01 p.m. => ${today}T12:01:00" ,
    "12:59 a.m. => ${today}T00:59:00" ,
    "9:30 pm    => ${today}T21:30:00" ,
    "9.30 pm    => ${today}T21:30:00" ,
    "9.30 p.m.  => ${today}T21:30:00" ,
    "5:30       => ${today}T05:30:00" ,
    "5:30:02    => ${today}T05:30:02" ,
    "3p         => ${today}T15:00:00" ,
    "3:15p      => ${today}T15:15:00" ,
    "15:15      => ${today}T15:15:00" ,
    "01:58:59 PM => ${today}T13:58:59" ,
    "01:58:59PM => ${today}T13:58:59" ,
    "01:58:59 AM => ${today}T01:58:59" ,
    "01:58:59AM => ${today}T01:58:59" ,
);
