#!perl -T

use Test::More tests => 1;

BEGIN {
    $ENV{LOGLEVEL} ||= "FATAL";
	use_ok( 'DJabberd::Plugin::JabberIqVersion' );
}

diag( "Testing DJabberd::Plugin::JabberIqVersion $DJabberd::Plugin::JabberIqVersion::VERSION, Perl $], $^X" );
