# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 26;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20101203013357/http://www.nyse.com/about/newsevents/1176373643795.html

is( is_holiday(2010,  1,  1), q{New Year's Day});
is( is_holiday(2010,  1, 18), q{Martin Luther King, Jr. Day});
is( is_holiday(2010,  2, 15), q{Washington's Birthday});
is( is_holiday(2010,  4,  2), q{Good Friday});
is( is_holiday(2010,  5, 31), q{Memorial Day});
ok(!is_holiday(2010,  6, 19), q{Juneteenth National Independence Day});
ok(!is_holiday(2010,  7,  4), q{Independence Day});
is( is_holiday(2010,  7,  5), q{Independence Day Observed});
is( is_holiday(2010,  9,  6), q{Labor Day});
is( is_holiday(2010, 11, 25), q{Thanksgiving Day});
is( is_holiday(2010, 12, 24), q{Christmas Day Observed});
ok(!is_holiday(2010, 12, 25), q{Christmas Day});
ok(!is_holiday(2010, 12, 31), q{New Year's Day Observed});

is(scalar(keys %{holidays(2010)}), 9);

ok(!is_holiday(2011,  1,  1), q{New Year's Day});
is( is_holiday(2011,  1, 17), q{Martin Luther King, Jr. Day});
is( is_holiday(2011,  2, 21), q{Washington's Birthday});
is( is_holiday(2011,  4, 22), q{Good Friday});
is( is_holiday(2011,  5, 30), q{Memorial Day});
ok(!is_holiday(2011,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday(2011,  7,  4), q{Independence Day});
is( is_holiday(2011,  9,  5), q{Labor Day});
is( is_holiday(2011, 11, 24), q{Thanksgiving Day});
is( is_holiday(2011, 12, 26), q{Christmas Day Observed});
ok(!is_holiday(2011, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays(2011)}), 8);
