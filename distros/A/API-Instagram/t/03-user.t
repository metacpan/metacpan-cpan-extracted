#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 2;

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

is $user->profile_picture, undef;

__DATA__
{
    "data": {
        "id": "1574083",
        "username": "snoopdogg",
        "full_name": "Snoop Dogg",
        "profile_pic_url": null,
        "profile_picture": null,
        "bio": "This is my bio",
        "website": "http://snoopdogg.com",
        "counts": {
            "media": 1320,
            "follows": 420,
            "followed_by": 3410
        }
    }
}