#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::DebugToolbar' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::DebugToolbar $Dancer::Plugin::DebugToolbar::VERSION, Perl $], $^X" );
