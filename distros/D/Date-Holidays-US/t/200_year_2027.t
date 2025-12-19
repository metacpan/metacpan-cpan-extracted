# - perl -
use strict;
use warnings;
use Test::More tests => 16;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2027

is(is_holiday(2027,  1,  1), q{New Year's Day});
is(is_holiday(2027,  1, 18), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2027,  2, 15), q{Washington's Birthday});
is(is_holiday(2027,  5, 31), q{Memorial Day});
is(is_holiday(2027,  6, 18), q{Juneteenth National Independence Day Observed});
is(is_holiday(2027,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2027,  7,  4), q{Independence Day});
is(is_holiday(2027,  7,  5), q{Independence Day Observed});
is(is_holiday(2027,  9,  6), q{Labor Day});
is(is_holiday(2027, 10, 11), q{Columbus Day});
is(is_holiday(2027, 11, 11), q{Veterans Day});
is(is_holiday(2027, 11, 25), q{Thanksgiving Day});
is(is_holiday(2027, 12, 24), q{Christmas Day Observed});
is(is_holiday(2027, 12, 25), q{Christmas Day});
is(is_holiday(2027, 12, 31), q{New Year's Day Observed});

is(scalar(keys %{holidays(2027)}), 15, 'count of holidays');
