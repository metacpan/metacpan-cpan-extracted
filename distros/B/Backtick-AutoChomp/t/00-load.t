#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'Backtick::AutoChomp' );
}

diag( "Testing Backtick::AutoChomp $Backtick::AutoChomp::VERSION, Perl $], $^X" );
