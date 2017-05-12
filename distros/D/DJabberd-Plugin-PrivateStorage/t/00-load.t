#!perl -T

use Test::More tests => 2;

BEGIN {
    $ENV{LOGLEVEL} ||= "FATAL";
	use_ok( 'DJabberd::Plugin::PrivateStorage' );
	use_ok( 'DJabberd::Plugin::PrivateStorage::InMemoryOnly' );
}

diag( "Testing DJabberd::Plugin::PrivateStorage $DJabberd::Plugin::PrivateStorage::VERSION, Perl $], $^X" );
