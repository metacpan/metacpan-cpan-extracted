#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Session::ID::crypt_openssl' ) || print "Bail out!
";
}

diag( "Testing CGI::Session::ID::crypt_openssl $CGI::Session::ID::crypt_openssl::VERSION, Perl $], $^X" );
