#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Daemon::Shutdown' ) || print "Bail out!
";
}

diag( "Testing Daemon::Shutdown $Daemon::Shutdown::VERSION, Perl $], $^X" );
use_ok( 'Daemon::Shutdown::Monitor::hdparm' );
use_ok( 'Daemon::Shutdown::Monitor::who' );
use_ok( 'Daemon::Shutdown::Monitor::smbstatus' );
