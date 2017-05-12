#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Data::Decycle' ) || print "Bail out!
";
}

diag( "Testing Data::Decycle $Data::Decycle::VERSION, Perl $], $^X" );
