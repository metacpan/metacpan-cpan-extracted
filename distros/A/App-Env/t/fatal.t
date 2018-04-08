#!perl

use Test2::V0;
use Test::Lib;

use App::Env;

my $env = App::Env->new( 'App1', { SysFatal => 1 } );

ok( dies { $env->system( $^X, '-e', 'exit(1)' ) }, 'system' );

ok( dies { $env->capture( $^X, '-e', 'exit(1)' ) }, 'capture' );

ok( dies { $env->qexec( $^X, '-e', 'exit(1)' ) }, 'qexec' );

done_testing;
