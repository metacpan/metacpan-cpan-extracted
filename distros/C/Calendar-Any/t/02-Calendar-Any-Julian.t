#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok( "Calendar::Any::Julian" ); }

my $date = Calendar::Any::Julian->new(732312);
is(ref $date, "Calendar::Any::Julian", "constructor");

is($date->year, 2005, "year");
is($date->month, 12, "month");
is($date->day, 19, "day");
ok(!$date->is_leap_year, "is_leap_year");

$date = Calendar::Any::Julian->new(12, 19, 2005);
is($date->absolute_date, 732312, "constructor from date");

$date = Calendar::Any::Julian->new(-day => 19, -month => 12, -year => 2005);
is($date->absolute_date, 732312, "constructor from named parameters");
