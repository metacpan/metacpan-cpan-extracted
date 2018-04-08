#! perl

use Test2::V0;

use Test::Lib;

use App::Env qw( App1 );

ok( $ENV{Site1_App1} == 1, 'use App1' );

done_testing;
