#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Confluence::Client::XMLRPC' ) || print "Bail out!";
}

diag( "Testing Confluence::Client::XMLRPC $Confluence::Client::XMLRPC::VERSION, Perl $], $^X" );

