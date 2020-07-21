#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'CommonMark' );
    use_ok( 'CommonMark::Massage' );
}

diag( "Testing CommonMark::Massage $CommonMark::Massage::VERSION, ".
      "CommonMark $CommonMark::VERSION, ".
      "Perl $], $^X" );
