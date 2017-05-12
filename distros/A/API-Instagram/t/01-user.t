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
            no_cache      => 1
	})
);

my $data = join '', <DATA>;
my $json = decode_json $data;
$api->mock('_request', sub { $json });
$api->mock('_get_list', sub { [] });

my $user = $api->user( $json->{data} );
isa_ok( $user, 'API::Instagram::User' );

is $user->id, 'self';
is $user->profile_picture, 'http://distillery.s3.amazonaws.com/profiles/profile_1574083_75sq_1295469061.jpg';
is ref $user->feed, 'ARRAY';
is ref $user->liked_media, 'ARRAY';
is ref $user->requested_by, 'ARRAY';

__DATA__
{
    "data": {
        "id": "self",
        "username": "snoopdogg",
        "full_name": "Snoop Dogg",
        "profile_pic_url": "http://test.com/picture.jpg",
        "profile_picture": "http://distillery.s3.amazonaws.com/profiles/profile_1574083_75sq_1295469061.jpg",
        "bio": "This is my bio",
        "website": "http://snoopdogg.com",
        "counts": {
            "media": 1320,
            "follows": 420,
            "followed_by": 3410
        }
    }
}