# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 12;
use Date::Holidays::US qw{is_holiday};

my $expect = 'Veterans Day';

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2021

is(is_holiday(2021,  1,  1), q{New Year's Day});
is(is_holiday(2021,  1, 18), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2021,  1, 20), q{Inauguration Day});
is(is_holiday(2021,  2, 15), q{Washington's Birthday});
is(is_holiday(2021,  5, 31), q{Memorial Day});
is(is_holiday(2021,  6, 18), q{Juneteenth National Independence Day Observed});
is(is_holiday(2021,  7,  5), q{Independence Day Observed});
is(is_holiday(2021,  9,  6), q{Labor Day});
is(is_holiday(2021, 10, 11), q{Columbus Day});
is(is_holiday(2021, 11, 11), q{Veterans Day});
is(is_holiday(2021, 11, 25), q{Thanksgiving Day});
is(is_holiday(2021, 12, 24), q{Christmas Day Observed});
