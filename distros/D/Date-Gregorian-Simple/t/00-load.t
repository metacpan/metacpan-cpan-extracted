#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Gregorian::Simple') || print "Bail out!"; }
diag( "Testing Date::Gregorian::Simple $Date::Gregorian::Simple::VERSION, Perl $], $^X" );
