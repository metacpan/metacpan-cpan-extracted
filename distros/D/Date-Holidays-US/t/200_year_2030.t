# - perl -
use strict;
use warnings;
use Test::More tests => 13;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2030

is(is_holiday(2030,  1,  1), q{New Year's Day});
is(is_holiday(2030,  1, 21), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2030,  1, 20), undef);
is(is_holiday(2030,  2, 18), q{Washington's Birthday});
is(is_holiday(2030,  5, 27), q{Memorial Day});
is(is_holiday(2030,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2030,  7,  4), q{Independence Day});
is(is_holiday(2030,  9,  2), q{Labor Day});
is(is_holiday(2030, 10, 14), q{Columbus Day});
is(is_holiday(2030, 11, 11), q{Veterans Day});
is(is_holiday(2030, 11, 28), q{Thanksgiving Day});
is(is_holiday(2030, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2030)}), 11);
