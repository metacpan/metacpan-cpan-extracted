#!perl

use Test::More;

BEGIN { use_ok('Mango' ); }
BEGIN { use_ok( 'Dancer::Plugin::Mango' ); }

diag( "Testing Dancer::Plugin::Mango and Mango" );

done_testing;
