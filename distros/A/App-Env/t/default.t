#!perl

use Test2::V0;
use Test::Lib;

# set default SysFatal and watch everything explode
use App::Env { SysFatal => 1, Cache => 0 };

my $env = App::Env->new( 'App1' );

ok(
   dies { $env->system( $^X, '-e', 'exit(1)' ) },
   'system',
);

ok(
   dies { $env->capture( $^X, '-e', 'exit(1)' ) },
   'capture',
);

ok(
   dies { $env->qexec( $^X, '-e', 'exit(1)' ) },
   'qexec',
);

# now reset it and get the error messages
App::Env->import( { SysFatal => 0 } );

ok(
   lives { App::Env->new( 'App1')->system( $^X, '-e', 'exit(1)' ) },
   'system'
);

done_testing;
