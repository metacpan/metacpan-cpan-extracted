#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Date::Holidays';

my $dh = new_ok 'Date::Holidays' => [ countrycode => 'USExtended', nocheck => 1 ];

my $got = $dh->is_holiday(year => 2024, month => 1, day => 1);
is $got, "New Year's Day", 'is_holiday';

$got = $dh->holidays;
is $got->{'0101'}, "New Year's Day", 'holidays';

done_testing();
