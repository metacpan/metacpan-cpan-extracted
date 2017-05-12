#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Saka::Simple') || print "Bail out!"; }

diag( "Testing Date::Saka::Simple $Date::Saka::Simple::VERSION, Perl $], $^X" );
