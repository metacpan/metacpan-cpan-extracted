#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DateTime;
use DateTime::Calendar::Discordian;

my $locale = DateTime::Locale->load('en_US');
my $dtcd1 = DateTime::Calendar::Discordian->new
  (day => 1, season => 'Chaos', year => 3000, locale => $locale);

my $dtcd2 = $dtcd1->clone;

is_deeply($dtcd1, $dtcd2, 'clone');

done_testing();
