#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'Data::Rebuilder' );
}

diag( "Testing Data::Rebuilder $Data::Rebuilder::VERSION, Perl $], $^X" );
