#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 1;

my $value = -( Data::Currency->new(1.2) );
is $value->value, -1.2, 'negate';
