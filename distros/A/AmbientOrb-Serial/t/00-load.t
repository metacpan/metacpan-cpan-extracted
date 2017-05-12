#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'AmbientOrb::Serial' );
}

diag( "Testing AmbientOrb::Serial $AmbientOrb::Serial::VERSION, Perl $], $^X" );
diag("These tests will attempt to connect to your orb\n");
diag("If your orb is not connected, it will fail\n");
diag("Futhermore, they expect to connect to COM1 (windows) or /dev/ttys0 (unix)");
