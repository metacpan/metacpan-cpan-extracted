#!/usr/bin/perl -w

use strict;

use Test::More tests => 8;

use DateTimeX::Lite;


for my $y ( 0, 400, 2000, 2004 )
{
    ok( DateTimeX::Lite::Util::is_leap_year($y), "$y is a leap year" );
}

for my $y ( 1, 100, 1900, 2133 )
{
    ok( ! DateTimeX::Lite::Util::is_leap_year($y), "$y is not a leap year" );
}
