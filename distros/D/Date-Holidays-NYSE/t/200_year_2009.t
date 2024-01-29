# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 12;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20090421201501/http://www.nyse.com/about/newsevents/1176373643795.html

is( is_holiday(2009,  1,  1), q{New Year's Day});
is( is_holiday(2009,  1, 19), q{Martin Luther King, Jr. Day});
is( is_holiday(2009,  2, 16), q{Washington's Birthday});
is( is_holiday(2009,  4, 10), q{Good Friday});
is( is_holiday(2009,  5, 25), q{Memorial Day});
ok(!is_holiday(2009,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday(2009,  7,  3), q{Independence Day Observed});
ok(!is_holiday(2009,  7,  4), q{Independence Day});
is( is_holiday(2009,  9,  7), q{Labor Day});
is( is_holiday(2009, 11, 26), q{Thanksgiving Day});
is( is_holiday(2009, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2009)}), 9);
