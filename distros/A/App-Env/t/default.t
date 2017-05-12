#!perl

use Test::More tests => 4;
use Test::Fatal;

use lib 't';

# set default SysFatal and watch everything explode
use App::Env { SysFatal => 1, Cache => 0 };

my $env = App::Env->new( 'App1' );

isnt(
     exception { $env->system( $^X, '-e', 'exit(1)' ) },
     undef,
     'system',
);

isnt(
     exception { $env->capture( $^X, '-e', 'exit(1)' ) },
     undef,
     'capture',
);

isnt(
     exception { $env->qexec( $^X, '-e', 'exit(1)' ) },
     undef,
     'qexec',
);

# now reset it and get the error messages
App::Env->import( { SysFatal => 0 } );

is(
   exception { App::Env->new( 'App1')->system( $^X, '-e', 'exit(1)' ) },
   undef,
   'system'
);
