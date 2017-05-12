#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'App::Env', 'Login' );
}

diag( "Testing App::Env::Login $App::Env::Login::VERSION, Perl $], $^X" );
