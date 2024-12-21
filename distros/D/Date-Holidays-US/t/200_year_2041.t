# - perl -
use strict;
use warnings;
use Test::More tests => 13;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2024

ok(!is_holiday(2041, 1, 20), q{Not inauguration day});

is(is_holiday(2041,  1,  1), q{New Year's Day});
is(is_holiday(2041,  1, 21), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2041,  2, 18), q{Washington's Birthday});
is(is_holiday(2041,  5, 27), q{Memorial Day});
is(is_holiday(2041,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2041,  7,  4), q{Independence Day});
is(is_holiday(2041,  9,  2), q{Labor Day});
is(is_holiday(2041, 10, 14), q{Columbus Day});
is(is_holiday(2041, 11, 11), q{Veterans Day});
is(is_holiday(2041, 11, 28), q{Thanksgiving Day});
is(is_holiday(2041, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2041)}), 11);
