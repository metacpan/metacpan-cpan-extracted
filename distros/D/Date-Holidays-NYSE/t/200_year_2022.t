# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20220601133900/https://www.nyse.com/markets/hours-calendars

my $year = 2022;
ok(!is_holiday($year,  1,  1), q{New Year's Day});
is( is_holiday($year,  1, 17), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 21), q{Washington's Birthday});
is( is_holiday($year,  4, 15), q{Good Friday});
is( is_holiday($year,  5, 30), q{Memorial Day});
is( is_holiday($year,  6, 20), q{Juneteenth National Independence Day Observed});
is( is_holiday($year,  7,  4), q{Independence Day});
is( is_holiday($year,  9,  5), q{Labor Day});
is( is_holiday($year, 11, 24), q{Thanksgiving Day});
is( is_holiday($year, 12, 26), q{Christmas Day Observed});

is(scalar(keys %{holidays($year)}), 9);
