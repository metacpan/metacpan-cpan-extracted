# - perl -
use strict;
use warnings;
use Test::More tests => 13;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2026

is(is_holiday(2026,  1,  1), q{New Year's Day});
is(is_holiday(2026,  1, 19), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2026,  2, 16), q{Washington's Birthday});
is(is_holiday(2026,  5, 25), q{Memorial Day});
is(is_holiday(2026,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2026,  7,  3), q{Independence Day Observed});
is(is_holiday(2026,  7,  4), q{Independence Day});
is(is_holiday(2026,  9,  7), q{Labor Day});
is(is_holiday(2026, 10, 12), q{Columbus Day});
is(is_holiday(2026, 11, 11), q{Veterans Day});
is(is_holiday(2026, 11, 26), q{Thanksgiving Day});
is(is_holiday(2026, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2026)}), 12, 'count of holidays');
