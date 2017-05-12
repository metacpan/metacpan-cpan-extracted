#!/usr/bin/env perl

use strict;
use warnings;
use Test::MockObject::Extends; 

use JSON;
use Furl;
use Furl::Response;
use Inline::Files;

use API::Instagram;
use Test::More tests => 17;

my $data = join '', <DATA>;
my $ua   = Test::MockObject::Extends->new( Furl->new() );
my $res  = Test::MockObject::Extends->new( Furl::Response->new( 1, 200, 'OK', {}, $data) );

$ua->mock('get',  sub { $res });
$ua->mock('post', sub { $res });

my $api = API::Instagram->new({
			client_id     => '123',
			client_secret => '456',
			redirect_uri  => 'http://localhost',
            no_cache      => 1,
            _ua           => $ua,
});


isa_ok( $api, 'API::Instagram');
ok $api->get_auth_url;
is $api->get_access_token, undef;

$api->code('789');
is $api->code, 789;
ok $api->get_auth_url;
is $api->user->username, undef;
is ref $api->user(123)->relationship('unfollow'), 'HASH';

my ( $access_token, $me ) = $api->get_access_token;
is $access_token, 123456789;

$api->access_token( $access_token );
is $api->access_token, 123456789;

my $api2 = API::Instagram->instance;
isa_ok( $api2, 'API::Instagram');

is $api2->access_token, 123456789;

isa_ok( $me, 'API::Instagram::User');
is $me->username, "snoopdogg";

is ref $api->_request('get','media'), 'HASH';

my @list = $api->_get_list( { url => 'media', count => 2 } );
is ~~@list , 2;

# Tests Popular Medias method with new DATA (__POPULAR__)
my $popular = join '', <POPULAR>;
my $res2 = Test::MockObject::Extends->new( Furl::Response->new( 1, 200, 'OK', {}, $popular) );
$ua->mock('get',  sub { $res2 });

is ref $api2->popular_medias, 'ARRAY';
is $api2->popular_medias->[0]->user->username, 'cocomiin';

__DATA__
{
    "meta": {
        "code": 200
    },
    "pagination": {
        "next_url": "http://localhost"
    },
    "data":[1],
    "access_token": 123456789,
    "user": {
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

__POPULAR__
{
    "meta": {
        "code": 200
    },
    "data": [{
            "type": "image",
            "users_in_photo": [],
            "filter": "Gotham",
            "tags": [],
            "comments": {},
            "caption": {
                "created_time": "1296656006",
                "text": "ãã¼ãâ¥ã¢ããªå§ãã¦ä½¿ã£ã¦ã¿ãã(^^)",
                "from": {
                    "username": "cocomiin",
                    "full_name": "",
                    "type": "user",
                    "id": "1127272"
                },
                "id": "26329105"
            },
            "likes": {
                "count": 35,
                "data": [{
                    "username": "mikeyk",
                    "full_name": "Kevin S",
                    "id": "4",
                    "profile_picture": "..."
                }]
            },
            "link": "http://instagr.am/p/BV5v_/",
            "user": {
                "username": "cocomiin",
                "full_name": "Cocomiin",
                "profile_picture": "http://distillery.s3.amazonaws.com/profiles/profile_1127272_75sq_1296145633.jpg",
                "id": "1127272"
            },
            "created_time": "1296655883",
            "images": {
                "low_resolution": {
                    "url": "http://distillery.s3.amazonaws.com/media/2011/02/01/34d027f155204a1f98dde38649a752ad_6.jpg",
                    "width": 306,
                    "height": 306
                },
                "thumbnail": {
                    "url": "http://distillery.s3.amazonaws.com/media/2011/02/01/34d027f155204a1f98dde38649a752ad_5.jpg",
                    "width": 150,
                    "height": 150
                },
                "standard_resolution": {
                    "url": "http://distillery.s3.amazonaws.com/media/2011/02/01/34d027f155204a1f98dde38649a752ad_7.jpg",
                    "width": 612,
                    "height": 612
                }
            },
            "id": "22518783",
            "location": null
        }, {
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
                },
                "users_in_photo": null,
                "filter": "Vesper",
                "tags": [],
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
                    }, {
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
                "location": null
            }
        }
    ]
}