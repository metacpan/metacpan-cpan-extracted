#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::dwcarder' ) || print "Bail out!\n";
}

diag( "Testing Acme::dwcarder $Acme::dwcarder::VERSION, Perl $], $^X" );
