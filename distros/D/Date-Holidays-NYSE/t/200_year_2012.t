# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 11;
use Date::Holidays::NYSE qw{is_holiday holidays};

#From: https://web.archive.org/web/20101203013357/http://www.nyse.com/about/newsevents/1176373643795.html

my $year = 2012;

is( is_holiday($year,  1,  2), q{New Year's Day Observed});
is( is_holiday($year,  1, 16), q{Martin Luther King, Jr. Day});
is( is_holiday($year,  2, 20), q{Washington's Birthday});
is( is_holiday($year,  4,  6), q{Good Friday});
is( is_holiday($year,  5, 28), q{Memorial Day});
ok(!is_holiday($year,  6, 19), q{Juneteenth National Independence Day});
is( is_holiday($year,  7,  4), q{Independence Day});
is( is_holiday($year,  9,  3), q{Labor Day});
is( is_holiday($year, 11, 22), q{Thanksgiving Day});
is( is_holiday($year, 12, 25), q{Christmas Day});

is(scalar(keys %{holidays($year)}), 9);
