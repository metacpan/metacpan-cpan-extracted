#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Date::Hijri::Simple') || print "Bail out!"; }

diag( "Testing Date::Hijri::Simple $Date::Hijri::Simple::VERSION, Perl $], $^X" );
