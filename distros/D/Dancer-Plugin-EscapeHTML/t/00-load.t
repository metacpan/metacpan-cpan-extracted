#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::EscapeHTML' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::EscapeHTML $Dancer::Plugin::EscapeHTML::VERSION, Perl $], $^X" );
