#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Utils') || print "Bail out!"; }

diag( "Testing Date::Utils $Date::Utils::VERSION, Perl $], $^X" );
