#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('App::Env');
}

diag( "Testing App::Env $App::Env::VERSION, Perl $], $^X" );
