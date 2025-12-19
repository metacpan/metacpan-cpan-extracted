# - perl -
use strict;
use warnings;
use Test::More tests => 15;
use Date::Holidays::US qw{is_holiday holidays};

#From: https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/#url=2025
#https://www.whitehouse.gov/briefing-room/presidential-actions/2024/12/30/executive-order-providing-for-the-closing-of-executive-departments-and-agencies-of-the-federal-government-on-january-9-2025/

is(is_holiday(2025,  1,  1), q{New Year's Day});
is(is_holiday(2025,  1,  9), q{National Day of Mourning for President James Earl Carter, Jr.});
is(is_holiday(2025,  1, 20), q{Birthday of Martin Luther King, Jr.});
is(is_holiday(2025,  2, 17), q{Washington's Birthday});
is(is_holiday(2025,  5, 26), q{Memorial Day});
is(is_holiday(2025,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2025,  7,  4), q{Independence Day});
is(is_holiday(2025,  9,  1), q{Labor Day});
is(is_holiday(2025, 10, 13), q{Columbus Day});
is(is_holiday(2025, 11, 11), q{Veterans Day});
is(is_holiday(2025, 11, 27), q{Thanksgiving Day});
is(is_holiday(2025, 12, 24), q{Day before Christmas Day});
is(is_holiday(2025, 12, 25), q{Christmas Day});
is(is_holiday(2025, 12, 26), q{Day following Christmas Day});

is(scalar(keys %{holidays(2025)}), 14);
