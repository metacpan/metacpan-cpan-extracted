#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Hebrew::Simple') || print "Bail out!"; }

diag( "Testing Date::Hebrew::Simple $Date::Hebrew::Simple::VERSION, Perl $], $^X" );
