#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 5;

my $api = Test::MockObject::Extends->new(
	API::Instagram->new({
			client_id     => '123',
			client_secret => '456',
			redirect_uri  => 'http://localhost',
            no_cache      => 1
	})
);

my $data = join '', <DATA>;
my $json = decode_json $data;
$api->mock('_request', sub { $json });
$api->mock('_post',    sub { $json });

my $user = $api->user( 123 );
isa_ok( $user, 'API::Instagram::User' );

is ref $user->relationship, 'HASH';
is $user->relationship->{incoming_status}, 'requested_by';
is ref $user->relationship('block'), 'HASH';
is ref $user->relationship('undef'), 'HASH';

__DATA__
{
    "meta": {
        "code": 200
    }, 
    "data": {
        "outgoing_status": "none", 
        "incoming_status": "requested_by"
    }
}