#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::ProxyPath' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::ProxyPath $Dancer::Plugin::ProxyPath::VERSION, Perl $], $^X" );
