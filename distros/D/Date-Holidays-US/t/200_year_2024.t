# - perl -
use strict;
use warnings;
use Test::More tests => 13;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2024

is(is_holiday(2024,  1,  1), q{New Year's Day});
is(is_holiday(2024,  1, 15), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2024,  2, 19), q{Washington's Birthday});
is(is_holiday(2024,  5, 27), q{Memorial Day});
is(is_holiday(2024,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2024,  7,  4), q{Independence Day});
is(is_holiday(2024,  9,  2), q{Labor Day});
is(is_holiday(2024, 10, 14), q{Columbus Day});
is(is_holiday(2024, 11, 11), q{Veterans Day});
is(is_holiday(2024, 11, 28), q{Thanksgiving Day});
is(is_holiday(2024, 12, 24), q{Day before Christmas Day});
is(is_holiday(2024, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2024)}), 12);
