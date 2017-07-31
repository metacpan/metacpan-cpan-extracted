#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Julian::Simple') || print "Bail out!"; }

diag( "Testing Date::Julian::Simple $Date::Julian::Simple::VERSION, Perl $], $^X" );
