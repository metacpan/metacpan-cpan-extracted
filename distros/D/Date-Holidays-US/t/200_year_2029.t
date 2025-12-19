# - perl -
use strict;
use warnings;
use Test::More tests => 14;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2029

is(is_holiday(2029,  1,  1), q{New Year's Day});
is(is_holiday(2029,  1, 15), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2029,  1, 20), q{Inauguration Day});
is(is_holiday(2029,  2, 19), q{Washington's Birthday});
is(is_holiday(2029,  5, 28), q{Memorial Day});
is(is_holiday(2029,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2029,  7,  4), q{Independence Day});
is(is_holiday(2029,  9,  3), q{Labor Day});
is(is_holiday(2029, 10,  8), q{Columbus Day});
is(is_holiday(2029, 11, 11), q{Veterans Day});
is(is_holiday(2029, 11, 12), q{Veterans Day Observed});
is(is_holiday(2029, 11, 22), q{Thanksgiving Day});
is(is_holiday(2029, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2029)}), 13);
