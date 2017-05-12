#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 19;

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

my $user = $api->user("1574083");
isa_ok( $user, 'API::Instagram::User' );

is $user->id, 1574083;
is $user->username, 'snoopdogg';
is $user->full_name, 'Snoop Dogg';
is $user->bio, 'This is my bio';
is $user->website, 'http://snoopdogg.com';
is $user->profile_picture, 'http://distillery.s3.amazonaws.com/profiles/profile_1574083_75sq_1295469061.jpg';

is $user->media, 1320;
is $user->follows, 420;
is $user->followed_by, 3410;

is $user->media(1), 1320;
is $user->follows(1), 420;
is $user->followed_by(1), 3410;

is ref $user->get_follows, 'ARRAY';
is ref $user->get_followers, 'ARRAY';
is ref $user->recent_medias, 'ARRAY';

is $user->feed, undef;
is $user->liked_media, undef;
is $user->requested_by, undef;

__DATA__
{
    "data": {
        "id": "1574083",
        "username": "snoopdogg",
        "full_name": "Snoop Dogg",
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