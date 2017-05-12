#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use API::Instagram;
use Test::More tests => 27;

my $api = Test::MockObject::Extends->new(
	API::Instagram->new({
			client_id     => '123', client_secret => '456', redirect_uri  => 'http://localhost', no_cache      => 1, })
);

my $data = join '', <DATA>;
my $json = decode_json $data;
$api->mock('_request', sub { $json });
$api->mock('_get_list', sub { {} });

# First Object
my $media = $api->media(3);
isa_ok( $media, 'API::Instagram::Media' );

is $media->id, 3;
is $media->type, 'video';
is $media->filter, 'Vesper';
is $media->likes, 1;
is $media->comments, 2;
is $media->users_in_photo, undef;
is $media->caption, undef;
is $media->link, 'http://instagr.am/p/D/';
is ref $media->images, 'HASH';
is ref $media->videos, 'HASH';
is ref $media->last_likes, 'ARRAY';
is ref $media->last_comments,'ARRAY';
is ref $media->get_likes, 'ARRAY';
is ref $media->get_comments, 'ARRAY';

my $user = $media->user;
isa_ok( $user, 'API::Instagram::User' );
is $user->username, 'kevin';

my $tags = $media->tags;
is ref $tags, 'ARRAY';
isa_ok( $tags->[0], 'API::Instagram::Tag' );

my $location = $media->location;
isa_ok( $location, 'API::Instagram::Location');
is $location->latitude, 0.2;

isa_ok( $media->created_time, 'Time::Moment' );
is $media->created_time->year, 2010;

$json = decode_json $data;
is $media->likes(1), 1;
is $media->comments(1), 2;

is ref $media->last_likes(1), 'ARRAY';
is ref $media->last_comments(1), 'ARRAY';


__DATA__
{
    "data": {
        "type": "video",
        "videos": {
            "low_resolution": {
                "url": "http://distilleryvesper9-13.ak.instagram.com/090d06dad9cd11e2aa0912313817975d_102.mp4",
                "width": 480,
                "height": 480
            },
            "standard_resolution": {
                "url": "http://distilleryvesper9-13.ak.instagram.com/090d06dad9cd11e2aa0912313817975d_101.mp4",
                "width": 640,
                "height": 640
            }
        },
        "users_in_photo": null,
        "filter": "Vesper",
        "tags": ["test"],
        "comments": {
            "data": [{
                "created_time": "1279332030",
                "text": "Love the sign here",
                "from": {
                    "username": "mikeyk",
                    "full_name": "Mikey Krieger",
                    "id": "4",
                    "profile_picture": "http://distillery.s3.amazonaws.com/profiles/profile_1242695_75sq_1293915800.jpg"
                },
                "id": "8"
            },
            {
                "created_time": "1279341004",
                "text": "Chilako taco",
                "from": {
                    "username": "kevin",
                    "full_name": "Kevin S",
                    "id": "3",
                    "profile_picture": "..."
                },
                "id": "3"
            }],
            "count": 2
        },
        "caption": null,
        "likes": {
            "count": 1,
            "data": [{
                "username": "mikeyk",
                "full_name": "Mikeyk",
                "id": "4",
                "profile_picture": "..."
            }]
        },
        "link": "http://instagr.am/p/D/",
        "user": {
            "username": "kevin",
            "full_name": "Kevin S",
            "profile_picture": "...",
            "bio": "...",
            "website": "...",
            "id": "3"
        },
        "created_time": "1279340983",
        "images": {
            "low_resolution": {
                "url": "http://distilleryimage2.ak.instagram.com/11f75f1cd9cc11e2a0fd22000aa8039a_6.jpg",
                "width": 306,
                "height": 306
            },
            "thumbnail": {
                "url": "http://distilleryimage2.ak.instagram.com/11f75f1cd9cc11e2a0fd22000aa8039a_5.jpg",
                "width": 150,
                "height": 150
            },
            "standard_resolution": {
                "url": "http://distilleryimage2.ak.instagram.com/11f75f1cd9cc11e2a0fd22000aa8039a_7.jpg",
                "width": 612,
                "height": 612
            }
        },
        "id": "3",
        "location": { "latitude":"0.2",
        "longitude":"0.3"}
    }
}