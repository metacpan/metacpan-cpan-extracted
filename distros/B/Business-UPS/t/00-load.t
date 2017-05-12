#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::UPS' );
  }

diag( "Testing Business::UPS $Business::UPS::VERSION, Perl $], $^X" );
