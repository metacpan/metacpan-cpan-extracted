#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Digest::SHA1 qw(sha1_hex);

use_ok('Catalyst::Plugin::Session::Store::CouchDB');

my $uri = ( $ENV{'CDB_TEST_URI'} or 'http://localhost:5984/' );
my $db = ( $ENV{'CDB_TEST_DB'} or 'app_session' );

ok(
	my $s = Catalyst::Plugin::Session::Store::CouchDB->new(),
	'new'
);

if ( $ENV{'CDB_LIVE_TEST'} ) {

	$s->_my_config->{'couch_uri'}      = $uri;
	$s->_my_config->{'couch_database'} = $db;

	my $random_id = 'session:' . sha1_hex( $$ . time );

	$s->setup_session();

	is( ref( $s->_cdbc ), 'AnyEvent::CouchDB', 'client' );
	is( ref( $s->_cdb_session_db ), 'AnyEvent::CouchDB::Database', 'db' );
	is( $s->get_session_data($random_id), undef, 'empty session' );

	ok( $s->store_session_data( $random_id, 'random data' ), 'store session' );
	is( $s->get_session_data($random_id), 'random data', 'get session' );

	ok( $s->store_session_data( $random_id, 'random data2' ), 'store more session' );
	is( $s->get_session_data($random_id), 'random data2', 'get more session' );
	ok( $s->delete_session_data($random_id), 'delete session' );

	is( $s->get_session_data($random_id), undef, 'empty session after delete' );
}

done_testing();

1;
