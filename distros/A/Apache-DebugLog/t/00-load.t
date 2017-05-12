use Test::More tests => 3;

BEGIN {
use_ok( 'Apache::DebugLog' );
use_ok( 'Apache2::DebugLog' );
use_ok( 'Apache::DebugLog::Config' );
}

diag( "Testing Apache::DebugLog $Apache::DebugLog::VERSION, Perl 5.008006, /usr/bin/perl" );
