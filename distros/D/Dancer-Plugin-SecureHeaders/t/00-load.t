#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::SecureHeaders' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::SecureHeaders $Dancer::Plugin::SecureHeaders::VERSION, Perl $], $^X" );
