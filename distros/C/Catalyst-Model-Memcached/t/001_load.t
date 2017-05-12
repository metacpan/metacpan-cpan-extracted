# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

package MyApp::Test;

use Moose;
extends 'Catalyst::Model::Memcached';
__PACKAGE__->set_primary_key( 'test' );
__PACKAGE__->set_ttl( 3 );

1;

package main;

use Test::More tests => 18;

BEGIN { use_ok( 'Catalyst::Model::Memcached' ); }

my $server = $ENV{MEMCACHED_SERVER};
MyApp::Test->config( args => {servers => [ $server ], namespace => 'test.'});
my $object = MyApp::Test->new();
isa_ok ($object, 'Catalyst::Model::Memcached');

my $data = { aaa => 'bbb', test => '1234' };

eval { $object->find( { aaa => 111 } ) };
like( $@, qr/^Find needs hash ref with primary_key/, 'Find without primary_key' );
eval { $object->find( 111 ) };
like( $@, qr/^Find needs hash ref with primary_key/, 'Find without hashref' );

eval { $object->search( { aaa => 111 } ) };
like( $@, qr/^Search needs hash ref with primary_key/, 'Search without primary_key' );
eval { $object->search( 111 ) };
like( $@, qr/^Search needs hash ref with primary_key/, 'Search without hashref' );

eval { $object->find_or_new( { aaa => 111 } ) };
like( $@, qr/^Find_or_new needs hash ref with primary_key/, 'Find_or_new without primary_key' );
eval { $object->find_or_new( 111 ) };
like( $@, qr/^Find_or_new needs hash ref with primary_key/, 'Find_or_new without hashref' );

eval { $object->create( { aaa => 111 } ) };
like( $@, qr/^Create needs hash ref/, 'Create without primary_key' );
eval { $object->create( 111 ) };
like( $@, qr/^Create needs hash ref/, 'Create without hashref' );

eval { $object->delete( { aaa => 111 } ) };
like( $@, qr/^Delete needs hash ref/, 'Delete without primary_key' );
eval { $object->delete( 111 ) };
like( $@, qr/^Delete needs hash ref/, 'Delete without hashref' );

$object->find( { test => '1234' } );

SKIP: {
	skip 'No MEMCACHED_SERVER environment var set', 6 unless $ENV{MEMCACHED_SERVER}; 
	ok($object->create( $data ), 'Create');
	my $res = $object->find( $data );
	is_deeply( $res, $data, 'Find stored data' );
	ok($object->delete( $data ), 'Delete');
	$res = $object->find( $data );
	is( $res, undef, 'Deleted data' );
	$res = $object->find_or_new( $data );
	$res = $object->search( $data );
	is_deeply( $res, $data, 'Search stored through find_or_new data' );
	sleep 3;
	$res = $object->search( $data );
	is( $res, undef,'Expired data' );
}
