#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN { use_ok( 'Dancer2::Plugin::WebService' ) || print "Oups\n" }

diag( "Testing Dancer2::Plugin::WebService $Dancer2::Plugin::WebService::VERSION, Perl $], $^X" );
