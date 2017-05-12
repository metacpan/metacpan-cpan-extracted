#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Data::Money::Converter::WebserviceX'); }

diag("Testing Data::Money::Converter::WebserviceX $Data::Money::Converter::WebserviceX::VERSION, Perl $], $^X");

done_testing();
