#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Barcode::Code93' ) || print "Bail out!
";
}

diag( "Testing Barcode::Code93 $Barcode::Code93::VERSION, Perl $], $^X" );
