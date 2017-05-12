#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Cache::Memcached::Fast::CGI' ) || print "Bail out!";
    use_ok( 'Cache::Memcached::Fast' ) || print "Bail out!";
    use_ok( 'IO::Capture::Stdout' ) || print "Bail out!";
}

diag( "Testing Cache::Memcached::Fast::CGI $Cache::Memcached::Fast::CGI::VERSION, Perl $], $^X" );
