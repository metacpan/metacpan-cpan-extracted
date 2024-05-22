#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Date::Holidays::USA';

my $dh = new_ok 'Date::Holidays::USA';

my $got = $dh->is_holiday(2024, 1, 1);
is $got, "New Year's Day", 'is_holiday';

$got = $dh->holidays(2024);
is $got->{'0331'}, 'Easter', 'holidays';

$got = $dh->us_holidays(2023);
is $got->{4}{9}, 'Easter', 'us_holidays';

done_testing();

