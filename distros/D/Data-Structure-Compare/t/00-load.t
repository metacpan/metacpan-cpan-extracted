#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Structure::Compare' ) || print "Bail out!\n";
}

diag( "Testing Data::Structure::Compare $Data::Structure::Compare::VERSION, Perl $], $^X" );
