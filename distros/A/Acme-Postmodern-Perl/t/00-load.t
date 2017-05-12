#!perl -T

use Test::More tests => 1;

BEGIN {
  SKIP: {
    skip 'postmodern perl required', 1 if $] < 5.020;
    use_ok( 'Acme::Postmodern::Perl' );
    diag( "Testing Acme::Postmodern::Perl $Acme::Postmodern::Perl::VERSION, Perl $], $^X" );
  }
}

