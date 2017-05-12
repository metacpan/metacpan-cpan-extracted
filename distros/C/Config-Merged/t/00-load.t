#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'Config::Merged' );
}

diag( "Testing Config::Merged $Config::Merged::VERSION, Perl $], $^X" );
