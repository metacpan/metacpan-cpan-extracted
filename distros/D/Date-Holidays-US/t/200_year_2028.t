# - perl -
use strict;
use warnings;
use Test::More tests => 14;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2028

is(is_holiday(2027, 12, 31), q{New Year's Day Observed});
is(is_holiday(2028,  1 , 1), q{New Year's Day});
is(is_holiday(2028,  1, 17), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2028,  2, 21), q{Washington's Birthday});
is(is_holiday(2028,  5, 29), q{Memorial Day});
is(is_holiday(2028,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2028,  7,  4), q{Independence Day});
is(is_holiday(2028,  9,  4), q{Labor Day});
is(is_holiday(2028, 10,  9), q{Columbus Day});
is(is_holiday(2028, 11, 10), q{Veterans Day Observed});
is(is_holiday(2028, 11, 11), q{Veterans Day});
is(is_holiday(2028, 11, 23), q{Thanksgiving Day});
is(is_holiday(2028, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2028)}), 12, 'count of holidays');
