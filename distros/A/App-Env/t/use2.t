#! perl

use Test2::V0;

use Test::Lib;

use App::Env qw( App1 App2 );

ok( $ENV{Site1_App1} == 1 &&
    $ENV{Site1_App2} == 1
    , 'use App1 App2' );

done_testing;
