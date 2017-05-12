#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::ActionRole::ExpiresHeader' ) || print "Bail out!
";
}

diag( "Testing Catalyst::ActionRole::ExpiresHeader $Catalyst::ActionRole::ExpiresHeader::VERSION, Perl $], $^X" );
