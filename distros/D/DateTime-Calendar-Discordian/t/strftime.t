#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime;
use DateTime::Calendar::Discordian;

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 28, month => 2, year =>, 2000,)
  )->strftime('%A %B %d %Y%t'), "Prickle-Prickle Chaos 59 3166\t", 'date 1');

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 28, month => 2, year =>, 2000,)
  )->strftime('%a %b %e %%%n'), "PP Chs 59th %\n", 'date 2');

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 29, month => 2, year =>, 2000,)
  )->strftime('%{%A, the %e day of %B%} in the YOLD %Y'), "St. Tib's Day in the YOLD 3166", 'date 3');

is(DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 28, month => 2, year =>, 2000,)
  )->strftime('%{%A, the %e day of %B%} in the YOLD %Y'), 'Prickle-Prickle, the 59th day of Chaos in the YOLD 3166', 'date 4');

is(DateTime::Calendar::Discordian->new(day => 50, season => 'Discord', 
  year => 3170,)->strftime('%NHappy %H'), 'Happy Discoflux', 'date 5');

is(DateTime::Calendar::Discordian->new(day => 51, season => 'Discord', 
  year => 3170,)->strftime('%NHappy %H'), q{}, 'date 6');

is_deeply([ DateTime::Calendar::Discordian->new(day => 51, season => 'Discord', 
  year => 3170,)->strftime('%%', '%Z') ], ['%', 'Z'], 'date 7');

done_testing();
