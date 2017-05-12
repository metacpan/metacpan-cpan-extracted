#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Persian::Simple') || print "Bail out!"; }

diag( "Testing Date::Persian::Simple $Date::Persian::Simple::VERSION, Perl $], $^X" );
