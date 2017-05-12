#!perl

use Test::More tests => 3;
use Test::Fatal;

use lib 't';
use App::Env;

my $env = App::Env->new( 'App1', { SysFatal => 1 } );

isnt(
     exception { $env->system( $^X, '-e', 'exit(1)' ) },
     undef,
     'system'
);

isnt (
      exception { $env->capture( $^X, '-e', 'exit(1)' ) },
      undef,
      'capture'
);

isnt (
      exception { $env->qexec( $^X, '-e', 'exit(1)' ) },
      undef,
      'qexec'
);
