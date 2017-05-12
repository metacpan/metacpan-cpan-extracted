#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 2;

BEGIN {
  use_ok( 'AppleII::Disk' );
  use_ok( 'AppleII::ProDOS' );
}

diag( "Testing AppleII-LibA2 $AppleII::ProDOS::VERSION" );
