# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://www.nyse.com/markets/hours-calendars

is(is_holiday(2025,  1,  1), q{New Year's Day});
is(is_holiday(2025,  1, 20), q{Martin Luther King, Jr. Day});
is(is_holiday(2025,  2, 17), q{Washington's Birthday});
is(is_holiday(2025,  4, 18), q{Good Friday});
is(is_holiday(2025,  5, 26), q{Memorial Day});
is(is_holiday(2025,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2025,  7,  4), q{Independence Day});
is(is_holiday(2025,  9,  1), q{Labor Day});
is(is_holiday(2025, 11, 27), q{Thanksgiving Day});
is(is_holiday(2025, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2025)}), 10);
