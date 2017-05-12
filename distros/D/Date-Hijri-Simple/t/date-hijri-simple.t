#!/usr/bin/perl

use 5.006;
use Test::More tests => 10;
use strict; use warnings;
use Date::Hijri::Simple;

my $date = Date::Hijri::Simple->new({year => 1436, month => 1, day => 1});
is($date->as_string, '1, Muharram 1436');
is($date->to_julian, 2456955.5);
is($date->day_of_week, 6);
is(sprintf("%04d-%02d-%02d", $date->to_gregorian), '2014-10-25');

my $gdate = $date->from_gregorian(2014, 10, 25);
is($gdate->year, 1436);
is($gdate->month, 1);
is($gdate->day, 1);

my $jdate = $date->from_julian(2456955.5);
is($gdate->year, 1436);
is($gdate->month, 1);
is($gdate->day, 1);

done_testing();
