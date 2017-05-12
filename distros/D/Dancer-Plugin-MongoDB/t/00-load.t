#!perl

use Test::More;

BEGIN { use_ok('Mango' ); }
BEGIN { use_ok( 'Dancer::Plugin::MongoDB' ); }

diag( "Testing Dancer::Plugin::Mongo and Mango" );

done_testing;
