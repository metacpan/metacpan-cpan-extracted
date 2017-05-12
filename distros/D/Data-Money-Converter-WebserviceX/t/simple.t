#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan skip_all => "Set TEST_WEBSERVICEX for online tests." unless $ENV{TEST_WEBSERVICEX};

use Data::Money;
use Data::Money::Converter::WebserviceX;

my $curr = Data::Money->new(value => 10, code => 'USD');
my $conv = Data::Money::Converter::WebserviceX->new;

ok($conv->convert($curr, 'GBP'), 'conversion');

done_testing;
