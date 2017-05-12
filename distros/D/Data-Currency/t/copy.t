#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 1;

my $value1 = Data::Currency->new(1.2);
my $value2 = $value1;
$value1 = $value1 + 2;
is $value2->value, 1.2, 'copy';
