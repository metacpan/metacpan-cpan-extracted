use Test::More tests => 2;

BEGIN {
use_ok( 'Apache::LogF' );
use_ok( 'Apache2::LogF' );
}

diag( "Testing Apache::LogF $Apache::LogF::VERSION, Perl 5.008006, /usr/bin/perl" );
