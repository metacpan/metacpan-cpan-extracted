#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Calendar::Bahai') || print "Bail out!"; }
diag( "Testing Calendar::Bahai $Calendar::Bahai::VERSION, Perl $], $^X" );
