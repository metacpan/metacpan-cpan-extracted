# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 8;
use Date::Holidays::US qw{is_holiday};

my $expect = 'Thanksgiving Day';

is(is_holiday(1869,11,25), undef); #before law
is(is_holiday(1870,11,24), $expect); #last
is(is_holiday(1938,11,24), $expect); #last
is(is_holiday(1939,11,23), $expect); #second from last
is(is_holiday(1940,11,21), $expect); #second from last
is(is_holiday(1941,11,20), $expect); #second from last
is(is_holiday(1942,11,26), $expect); #fourth
is(is_holiday(2025,11,27), $expect); #fourth


