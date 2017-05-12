#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 6;

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

my $location = $api->location('1');
isa_ok( $location, 'API::Instagram::Location' );

is $location->id, 1;
is $location->name, 'Dogpatch Labs';
is $location->latitude, 37.782;
is $location->longitude, -122.387;
is ref $location->recent_medias, 'ARRAY';

__DATA__
{
    "data": {
        "id": "1",
        "name": "Dogpatch Labs",
        "latitude": 37.782,
        "longitude": -122.387
    }
}