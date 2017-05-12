#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ACL::Lite' ) || print "Bail out!\n";
}

diag( "Testing ACL::Lite $ACL::Lite::VERSION, Perl $], $^X" );
