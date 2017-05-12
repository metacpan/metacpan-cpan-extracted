#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::MPD' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::MPD $Dancer::Plugin::MPD::VERSION, Perl $], $^X" );
