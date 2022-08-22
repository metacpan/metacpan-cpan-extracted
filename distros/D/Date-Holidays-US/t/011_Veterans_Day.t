# - perl -
use strict;
use warnings;
use Data::Dumper qw{Dumper};
use Test::More tests => 18;
use Date::Holidays::US qw{is_holiday};

my $expect = 'Veterans Day';

is(is_holiday(2023,11,11), $expect);
is(is_holiday(2022,11,11), $expect);
is(is_holiday(2021,11,11), $expect);
is(is_holiday(2020,11,11), $expect);
is(is_holiday(2019,11,11), $expect);
is(is_holiday(2018,11,11), $expect);
is(is_holiday(2017,11,11), $expect);
is(is_holiday(2016,11,11), $expect);

is(is_holiday(1970,11,11), $expect);
is(is_holiday(1971,10,25), $expect); #from Wikipedia
is(is_holiday(1972,10,23), $expect); #from Wikipedia
is(is_holiday(1973,10,22), $expect); #from Wikipedia
is(is_holiday(1974,10,28), $expect); #from Wikipedia
is(is_holiday(1975,10,27), $expect); #from Wikipedia
is(is_holiday(1976,10,25), $expect); #from Wikipedia
is(is_holiday(1977,10,24), $expect); #from Wikipedia
is(is_holiday(1978,11,11), $expect);

is(is_holiday(2023,11,10), "$expect Observed");

