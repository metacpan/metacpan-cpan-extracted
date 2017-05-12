#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok( "Calendar::Any::Gregorian" ); }

my $date = Calendar::Any::Gregorian->new(732312);
is(ref $date, "Calendar::Any::Gregorian", "constructor");

is($date->year, 2006, "year");
is($date->month, 1, "month");
is($date->day, 1, "day");
ok(!$date->is_leap_year, "is_leap_year");

$date = Calendar::Any::Gregorian->new(1, 1, 2006);
is($date->absolute_date, 732312, "constructor from date");

$date = Calendar::Any::Gregorian->new(-day => 1, -month => 1, -year => 2006);
is($date->absolute_date, 732312, "constructor from named parameters");
