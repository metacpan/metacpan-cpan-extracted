#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 4;

my $api = Test::MockObject::Extends->new(
	API::Instagram->new({
			client_id     => '123',
			client_secret => '456',
			redirect_uri  => 'http://localhost',
	})
);

my $data = join '', <DATA>;
my $json = decode_json $data;
$api->mock('_request', sub { $json });
$api->mock('_get_list', sub { [] });

my $location = $api->location( $json->{data} );
isa_ok( $location, 'API::Instagram::Location' );

is $location->id, undef;
is $location->name, undef;
is ref $location->recent_medias, 'ARRAY';

__DATA__
{
    "data": {
        "latitude": 37.782,
        "longitude": -122.387
    }
}