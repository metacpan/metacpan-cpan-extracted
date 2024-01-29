# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://www.nyse.com/markets/hours-calendars

is(is_holiday(2023,  1,  2), q{New Year's Day Observed});
is(is_holiday(2023,  1, 16), q{Martin Luther King, Jr. Day});
is(is_holiday(2023,  2, 20), q{Washington's Birthday});
is(is_holiday(2023,  4,  7), q{Good Friday});
is(is_holiday(2023,  5, 29), q{Memorial Day});
is(is_holiday(2023,  6, 19), q{Juneteenth National Independence Day});
is(is_holiday(2023,  7,  4), q{Independence Day});
is(is_holiday(2023,  9,  4), q{Labor Day});
is(is_holiday(2023, 11, 23), q{Thanksgiving Day});
is(is_holiday(2023, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2025)}), 10);
