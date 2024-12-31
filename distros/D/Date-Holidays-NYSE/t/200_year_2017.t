# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20170702003212/https://www.nyse.com/markets/hours-calendars

my $year = 2017;
is( is_holiday($year,  1,  2), q{New Year's Day Observed});
is( is_holiday($year,  1, 16), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 20), q{Washington's Birthday});
is( is_holiday($year,  4, 14), q{Good Friday});
is( is_holiday($year,  5, 29), q{Memorial Day});
ok(!is_holiday($year,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday($year,  7,  4), q{Independence Day});
is( is_holiday($year,  9,  4), q{Labor Day});
is( is_holiday($year, 11, 23), q{Thanksgiving Day});
is( is_holiday($year, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays($year)}), 9);
