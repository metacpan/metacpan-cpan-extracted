# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20200530191718/https://www.nyse.com/markets/hours-calendars

my $year = 2020;
is( is_holiday($year,  1,  1), q{New Year's Day});
is( is_holiday($year,  1, 20), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 17), q{Washington's Birthday});
is( is_holiday($year,  4, 10), q{Good Friday});
is( is_holiday($year,  5, 25), q{Memorial Day});
ok(!is_holiday($year,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday($year,  7,  3), q{Independence Day Observed});
is( is_holiday($year,  9,  7), q{Labor Day});
is( is_holiday($year, 11, 26), q{Thanksgiving Day});
is( is_holiday($year, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays($year)}), 9);
