#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Check::ISA') || print "Bail out!\n"; }
diag( "Testing Check::ISA $Check::ISA::VERSION, Perl $], $^X" );
