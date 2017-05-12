#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Data::Money::Converter') || print "Bail out!\n"; }

diag( "Testing Data::Money::Converter $Data::Money::Converter::VERSION, Perl $], $^X" );

done_testing();
