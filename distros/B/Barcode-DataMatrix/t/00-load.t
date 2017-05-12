#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Barcode::DataMatrix' ) || print "Bail out!\n";
}

diag( "Testing Barcode::DataMatrix $Barcode::DataMatrix::VERSION, Perl $], $^X" );
