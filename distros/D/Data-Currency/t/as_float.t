#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::More tests => 3;

is(Data::Currency->new( 1.2, 'USD' )->as_float, '1.20', '1.20 USD as float');
is(Data::Currency->new( 1.2, 'JPY' )->as_float, '1',    '1.2 JPY as float');
is(Data::Currency->new( 1.6, 'JPY' )->as_float, '2',    '1.6 JPY as float');
