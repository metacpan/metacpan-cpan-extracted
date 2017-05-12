#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );
BEGIN { use_ok("Calendar::Any::Chinese"); }

my $date = Calendar::Any::Chinese->new(78, 22, 12, 2);
is($date->gyear, 2006, 'gyear');
is($date->gmonth, 1, 'gmonth');
is($date->gday, 1, 'gday');

