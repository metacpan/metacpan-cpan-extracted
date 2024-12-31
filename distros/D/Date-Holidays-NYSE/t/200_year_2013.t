# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20110928075239/http://corporate.nyx.com/en/holidays-and-hours/nyse

my $year = 2013;

is( is_holiday($year,  1,  1), q{New Year's Day});
is( is_holiday($year,  1, 21), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 18), q{Washington's Birthday});
is( is_holiday($year,  3, 29), q{Good Friday});
is( is_holiday($year,  5, 27), q{Memorial Day});
ok(!is_holiday($year,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday($year,  7,  4), q{Independence Day});
is( is_holiday($year,  9,  2), q{Labor Day});
is( is_holiday($year, 11, 28), q{Thanksgiving Day});
is( is_holiday($year, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays($year)}), 9);
