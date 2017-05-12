#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Crypt::Smithy' ) || print "Bail out!
";
}

diag( "Testing Crypt::Smithy $Crypt::Smithy::VERSION, Perl $], $^X" );
