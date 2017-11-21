#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Test::Simple tests => 2;
use App::WRT::Util qw(get_date);

my $year = get_date('year') + 1900;

ok(
  ($year =~ /^[0-9]+$/) && ($year > 1900),
  'sure looks like a year'
);

my (@values) = get_date('wday', 'yday', 'mon');
my $length = @values;
ok($length == 3, 'got multiple values');

1;
