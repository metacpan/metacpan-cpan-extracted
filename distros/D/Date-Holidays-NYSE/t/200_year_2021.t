# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20200530191718/https://www.nyse.com/markets/hours-calendars

my $year = 2021;
is( is_holiday($year,  1,  1), q{New Year's Day});
is( is_holiday($year,  1, 18), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 15), q{Washington's Birthday});
is( is_holiday($year,  4,  2), q{Good Friday});
is( is_holiday($year,  5, 31), q{Memorial Day});
ok(!is_holiday($year,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday($year,  7,  5), q{Independence Day Observed});
is( is_holiday($year,  9,  6), q{Labor Day});
is( is_holiday($year, 11, 25), q{Thanksgiving Day});
is( is_holiday($year, 12, 24), q{Christmas Day Observed});

is(scalar(keys %{holidays($year)}), 9);
