#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {  use_ok( 'Calendar::Saka' ) || print "Bail out!"; }
diag( "Testing Calendar::Saka $Calendar::Saka::VERSION, Perl $], $^X" );
