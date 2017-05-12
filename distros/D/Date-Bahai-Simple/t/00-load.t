#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Bahai::Simple') || print "Bail out!"; }

diag( "Testing Date::Bahai::Simple $Date::Bahai::Simple::VERSION, Perl $], $^X" );
