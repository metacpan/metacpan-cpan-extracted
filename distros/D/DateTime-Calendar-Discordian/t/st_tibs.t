#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime;
use DateTime::Calendar::Discordian;

is(eval{DateTime::Calendar::Discordian->new
  (day => q{St. Tib's day}, year => 3066)->day}, undef, 'date 1');

is(eval{DateTime::Calendar::Discordian->new
  (day => q{St. Tib's day}, year => 3165)->day}, undef, 'date 2');

is(eval{DateTime::Calendar::Discordian->new
  (day => q{St. Tib's day}, year => 3166)->day}, q{St. Tib's Day}, 'date 3');

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 29, month => 2, year =>, 2000,)
  )->strftime("%d"), q{St. Tib's Day}, 'date 4');

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 29, month => 2, year =>, 1996,)
  )->strftime("%d"), q{St. Tib's Day}, 'date 5');

is((DateTime::Calendar::Discordian->new
  (day => q{St. Tib's day}, year => 3166)->utc_rd_values)[0],
  (DateTime->new(day => 29, month => 2, year => 2000)->utc_rd_values)[0],
  'date 6');

done_testing();
