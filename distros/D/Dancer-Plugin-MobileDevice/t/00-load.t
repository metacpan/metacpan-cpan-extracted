#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::MobileDevice' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::MobileDevice $Dancer::Plugin::MobileDevice::VERSION, Perl $], $^X" );
