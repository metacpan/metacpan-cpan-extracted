#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::DebugDump' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::DebugDump $Dancer::Plugin::DebugDump::VERSION, Perl $], $^X" );
