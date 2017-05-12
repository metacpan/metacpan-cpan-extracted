#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CloudApp::REST' ) || print "Bail out!
";
}

diag( "Testing CloudApp::REST $CloudApp::REST::VERSION, Perl $], $^X" );
