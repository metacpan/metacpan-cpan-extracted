#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Session::Store::Couchbase' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Session::Store::Couchbase $Catalyst::Plugin::Session::Store::Couchbase::VERSION, Perl $], $^X" );
