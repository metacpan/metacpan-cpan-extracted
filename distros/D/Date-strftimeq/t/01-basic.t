#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Date::DayOfWeek;
use Date::strftimeq;

my @localtime = (30, 9, 11, 19, 10, 119, 2, 322, 0); #"Tue Nov 19 11:09:30 2019"

my @tests = (
    ['<%%>', "<%>"],
    ['%Y-%m-%d', "2019-11-19"],
    ['%5Y-%3m-%-3d', "02019-011- 19"],
    ['%Y-%m-%d<%( 1+1 )q>', "2019-11-19<2>"],
    ['%Y-%m-%d<%( dayofweek($_[3], $_[4]+1, $_[5]+1900) == 7 ? "sun":"" )q>', "2019-11-19<>"],
    ['%Y-%m-%d<%( dayofweek($_[3], $_[4]+1, $_[5]+1900) == 2 ? "tue":"" )q>', "2019-11-19<tue>"],
);

for my $test (@tests) {
    my ($fmt, $res) = @$test;
    is(strftimeq($fmt, @localtime), $res, "$fmt = $res");
}

DONE_TESTING:
done_testing;
