#!/home/acme/perl-5.12.3/bin/perl
use strict;
use warnings;
use 5.12.0;
use lib 'lib';
use App::Twimap;
use Data::Dumper;
use Test::More;
use Test::Differences::Color;

my $tweet = App::Twimap::Tweet->new(
    oembed_urls => 1,
    data        => {
        'retweeted' => 0,
        'source' =>
            '<a href="http://www.echofon.com/" rel="nofollow">Echofon</a>',
        'favorited'     => 0,
        'coordinates'   => undef,
        'place'         => undef,
        'retweet_count' => 0,
        'entities'      => {
            'hashtags'      => [],
            'user_mentions' => [],
            'urls'          => [
                {   'display_url'  => 'lockerz.com/s/135515455',
                    'expanded_url' => 'http://lockerz.com/s/135515455',
                    'url'          => 'http://t.co/kkxnMoL',
                    'indices'      => [ 10, 29 ]
                }
            ]
        },
        'truncated'                 => 0,
        'created_at'                => 'Sat Sep 03 19:39:51 +0000 2011',
        'in_reply_to_status_id_str' => undef,
        'contributors'              => undef,
        'text'                      => 'Breakfast http://t.co/kkxnMoL',
        'in_reply_to_user_id'       => undef,
        'user'                      => {
            'friends_count'       => 505,
            'follow_request_sent' => 0,
            'profile_image_url' =>
                'http://a3.twimg.com/profile_images/427205513/arty_normal.jpg',
            'profile_background_image_url_https' =>
                'https://si0.twimg.com/profile_background_images/38511862/antisocial.gif',
            'profile_sidebar_fill_color' => 'e0ff92',
            'profile_background_color'   => '6699cc',
            'notifications'              => 0,
            'url'                        => 'http://thegestalt.org/simon/',
            'id'                         => 9066762,
            'is_translator'              => 0,
            'following'                  => 1,
            'screen_name'                => 'deflatermouse',
            'lang'                       => 'en',
            'location'                   => 'San Francisco',
            'followers_count'            => 583,
            'statuses_count'             => 1852,
            'name'                       => 'Simon Wistow',
            'description'                => '',
            'favourites_count'           => 2,
            'profile_background_tile'    => 0,
            'listed_count'               => 44,
            'contributors_enabled'       => 0,
            'profile_link_color'         => '0000ff',
            'profile_image_url_https' =>
                'https://si0.twimg.com/profile_images/427205513/arty_normal.jpg',
            'profile_sidebar_border_color' => '87bc44',
            'created_at'            => 'Mon Sep 24 09:59:53 +0000 2007',
            'utc_offset'            => -28800,
            'verified'              => 0,
            'show_all_inline_media' => 0,
            'profile_background_image_url' =>
                'http://a3.twimg.com/profile_background_images/38511862/antisocial.gif',
            'default_profile'              => 0,
            'protected'                    => 0,
            'id_str'                       => '9066762',
            'profile_text_color'           => '000000',
            'default_profile_image'        => 0,
            'time_zone'                    => 'Pacific Time (US & Canada)',
            'geo_enabled'                  => 0,
            'profile_use_background_image' => 1
        },
        'id'                      => '110074547411238913',
        'in_reply_to_status_id'   => undef,
        'geo'                     => undef,
        'possibly_sensitive'      => 0,
        'in_reply_to_user_id_str' => undef,
        'id_str'                  => '110074547411238913',
        'in_reply_to_screen_name' => undef
    }
);

eq_or_diff(
    $tweet->to_email->as_string,
    'From: "Simon Wistow" <deflatermouse@twitter> (deflatermouse)
Subject: Breakfast http://lockerz.com/s/135515455
Date: Sat, 3 Sep 2011 20:39:51 +0100
Message-Id: <110074547411238913@twitter>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="1317546824.2C8b2BC51.4794"; charset="utf-8"


--1317546824.2C8b2BC51.4794
Date: Sat, 3 Sep 2011 20:39:51 +0100
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Disposition: inline

Breakfast http://lockerz.com/s/135515455

https://twitter.com/deflatermouse/status/110074547411238913
--1317546824.2C8b2BC51.4794
Date: Sat, 3 Sep 2011 20:39:51 +0100
MIME-Version: 1.0
Content-Type: text/html; charset="utf-8"
Content-Disposition: inline

Breakfast <a href="http://lockerz.com/s/135515455">http://lockerz.com/s/135515455</a>
<br/><br/>
<a href="http://c0013938.cdn1.cloudfiles.rackspacecloud.com/x2_813cd3f" title="x2_813cd3f"><img alt="x2_813cd3f" height="79" src="http://c0013942.cdn1.cloudfiles.rackspacecloud.com/x2_813cd3f" width="79" /></a><br/><br/>

<a href="https://twitter.com/deflatermouse/status/110074547411238913">https://twitter.com/deflatermouse/status/110074547411238913</a>
--1317546824.2C8b2BC51.4794--
'
);

$tweet = App::Twimap::Tweet->new(
    data => {
        'retweeted' => 0,
        'source' =>
            '<a href="http://twitter.com/#!/download/iphone" rel="nofollow">Twitter for iPhone</a>',
        'favorited'        => 0,
        'coordinates'      => undef,
        'place'            => undef,
        'retweeted_status' => {
            'retweeted' => 0,
            'source' =>
                '<a href="http://twitterrific.com" rel="nofollow">Twitterrific</a>',
            'favorited'     => 0,
            'coordinates'   => undef,
            'place'         => undef,
            'retweet_count' => 18,
            'entities'      => {
                'hashtags'      => [],
                'user_mentions' => [
                    {   'name'        => 'Paul Haddad',
                        'id'          => 18247541,
                        'indices'     => [ 74, 86 ],
                        'id_str'      => '18247541',
                        'screen_name' => 'tapbot_paul'
                    }
                ],
                'urls' => [
                    {   'display_url'  => 'bit.ly/nvlT9z',
                        'expanded_url' => 'http://bit.ly/nvlT9z',
                        'url'          => 'http://t.co/v4uqK45',
                        'indices'      => [ 49, 68 ]
                    }
                ]
            },
            'truncated'                 => 0,
            'created_at'                => 'Sat Sep 03 19:55:08 +0000 2011',
            'in_reply_to_status_id_str' => undef,
            'contributors'              => undef,
            'text' =>
                'More on iCloud, Microsoft Azure, and Amazon AWS: http://t.co/v4uqK45 (via @tapbot_paul)',
            'in_reply_to_user_id' => undef,
            'user'                => {
                'friends_count'       => 115,
                'follow_request_sent' => 0,
                'profile_image_url' =>
                    'http://a2.twimg.com/profile_images/1501070030/John_2011_1_500x500_normal.png',
                'profile_background_image_url_https' =>
                    'https://si0.twimg.com/images/themes/theme1/bg.png',
                'profile_sidebar_fill_color' => 'DDEEF6',
                'profile_background_color'   => 'C0DEED',
                'notifications'              => 0,
                'url' => 'http://arstechnica.com/author/john-siracusa/',
                'id'  => 636923,
                'is_translator'           => 0,
                'following'               => 0,
                'screen_name'             => 'siracusa',
                'lang'                    => 'en',
                'location'                => 'Newton, MA',
                'followers_count'         => 16045,
                'statuses_count'          => 11661,
                'name'                    => 'John Siracusa',
                'description'             => '',
                'favourites_count'        => 586,
                'profile_background_tile' => 0,
                'listed_count'            => 1236,
                'contributors_enabled'    => 0,
                'profile_link_color'      => '0084B4',
                'profile_image_url_https' =>
                    'https://si0.twimg.com/profile_images/1501070030/John_2011_1_500x500_normal.png',
                'profile_sidebar_border_color' => 'C0DEED',
                'created_at'            => 'Mon Jan 15 17:57:00 +0000 2007',
                'utc_offset'            => -18000,
                'verified'              => 0,
                'show_all_inline_media' => 0,
                'profile_background_image_url' =>
                    'http://a0.twimg.com/images/themes/theme1/bg.png',
                'protected'             => 0,
                'default_profile'       => 1,
                'id_str'                => '636923',
                'profile_text_color'    => '333333',
                'default_profile_image' => 0,
                'time_zone'             => 'Eastern Time (US & Canada)',
                'geo_enabled'           => 0,
                'profile_use_background_image' => 1
            },
            'id'                      => '110078391436316672',
            'in_reply_to_status_id'   => undef,
            'geo'                     => undef,
            'possibly_sensitive'      => 0,
            'in_reply_to_user_id_str' => undef,
            'id_str'                  => '110078391436316672',
            'in_reply_to_screen_name' => undef
        },
        'retweet_count' => 18,
        'entities'      => {
            'hashtags'      => [],
            'user_mentions' => [
                {   'name'        => 'John Siracusa',
                    'id'          => 636923,
                    'indices'     => [ 3, 12 ],
                    'id_str'      => '636923',
                    'screen_name' => 'siracusa'
                },
                {   'name'        => 'Paul Haddad',
                    'id'          => 18247541,
                    'indices'     => [ 88, 100 ],
                    'id_str'      => '18247541',
                    'screen_name' => 'tapbot_paul'
                }
            ],
            'urls' => [
                {   'display_url'  => 'bit.ly/nvlT9z',
                    'expanded_url' => 'http://bit.ly/nvlT9z',
                    'url'          => 'http://t.co/v4uqK45',
                    'indices'      => [ 63, 82 ]
                }
            ]
        },
        'truncated'                 => 0,
        'created_at'                => 'Sat Sep 03 22:13:06 +0000 2011',
        'in_reply_to_status_id_str' => undef,
        'contributors'              => undef,
        'text' =>
            'RT @siracusa: More on iCloud, Microsoft Azure, and Amazon AWS: http://t.co/v4uqK45 (via @tapbot_paul)',
        'in_reply_to_user_id' => undef,
        'user'                => {
            'friends_count'       => 157,
            'follow_request_sent' => 0,
            'profile_image_url' =>
                'http://a1.twimg.com/profile_images/83453615/Tim_Bunce_shoulder_width_8x10_normal.jpg',
            'profile_background_image_url_https' =>
                'https://si0.twimg.com/images/themes/theme7/bg.gif',
            'profile_sidebar_fill_color' => 'F3F3F3',
            'profile_background_color'   => 'EBEBEB',
            'notifications'              => 0,
            'url'                        => 'http://blog.timbunce.org',
            'id'                         => 15018629,
            'is_translator'              => 0,
            'following'                  => 1,
            'screen_name'                => 'timbunce',
            'lang'                       => 'en',
            'location'                   => 'Limerick, Ireland',
            'followers_count'            => 569,
            'statuses_count'             => 2881,
            'name'                       => 'Tim Bunce',
            'description' =>
                'Working by Listening Reflecting Exploring Solving, usually with modern Perl programming. Fathering by Listening Accepting Loving.',
            'favourites_count'        => 1039,
            'profile_background_tile' => 0,
            'listed_count'            => 85,
            'contributors_enabled'    => 0,
            'profile_link_color'      => '990000',
            'profile_image_url_https' =>
                'https://si0.twimg.com/profile_images/83453615/Tim_Bunce_shoulder_width_8x10_normal.jpg',
            'profile_sidebar_border_color' => 'DFDFDF',
            'created_at'            => 'Thu Jun 05 14:50:56 +0000 2008',
            'utc_offset'            => 0,
            'verified'              => 0,
            'show_all_inline_media' => 0,
            'profile_background_image_url' =>
                'http://a1.twimg.com/images/themes/theme7/bg.gif',
            'protected'                    => 0,
            'default_profile'              => 0,
            'id_str'                       => '15018629',
            'profile_text_color'           => '333333',
            'default_profile_image'        => 0,
            'time_zone'                    => 'Dublin',
            'geo_enabled'                  => 1,
            'profile_use_background_image' => 1
        },
        'id'                      => '110113112895660033',
        'in_reply_to_status_id'   => undef,
        'geo'                     => undef,
        'possibly_sensitive'      => 0,
        'in_reply_to_user_id_str' => undef,
        'id_str'                  => '110113112895660033',
        'in_reply_to_screen_name' => undef
    }
);

eq_or_diff(
    $tweet->to_email->as_string,
    'From: "Tim Bunce" <timbunce@twitter> (timbunce)
Subject: RT @siracusa: More on iCloud, Microsoft Azure, and Amazon AWS:
 http://www.
 theregister.co.uk/2011/09/02/icloud_runs_on_microsoft_azure_and_amazon/ ( via
 @tapbot_paul)
Date: Sat, 3 Sep 2011 23:13:06 +0100
Message-Id: <110113112895660033@twitter>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="1317546824.2C8b2BC51.4794"; charset="utf-8"


--1317546824.2C8b2BC51.4794
Date: Sat, 3 Sep 2011 23:13:06 +0100
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Disposition: inline

RT @siracusa: More on iCloud, Microsoft Azure, and Amazon AWS:
http://www.theregister.co.uk/2011/09/02/icloud_runs_on_microsoft_azure_and_amazon/
(via @tapbot_paul)

https://twitter.com/timbunce/status/110113112895660033
--1317546824.2C8b2BC51.4794
Date: Sat, 3 Sep 2011 23:13:06 +0100
MIME-Version: 1.0
Content-Type: text/html; charset="utf-8"
Content-Disposition: inline

RT @siracusa: More on iCloud, Microsoft Azure, and Amazon AWS: <a href="http://www.theregister.co.uk/2011/09/02/icloud_runs_on_microsoft_azure_and_amazon/">http://www.theregister.co.uk/2011/09/02/icloud_runs_on_microsoft_azure_and_amazon/</a> (via @tapbot_paul)
<br/><br/>
<br/><br/>

<a href="https://twitter.com/timbunce/status/110113112895660033">https://twitter.com/timbunce/status/110113112895660033</a>
--1317546824.2C8b2BC51.4794--
'
);

$tweet = App::Twimap::Tweet->new(
    data => {
        'retweeted' => 0,
        'source' =>
            '<a href="http://www.instapaper.com/" rel="nofollow">Instapaper</a>',
        'favorited'     => 0,
        'coordinates'   => undef,
        'place'         => undef,
        'retweet_count' => 3,
        'entities'      => {
            'hashtags'      => [],
            'user_mentions' => [],
            'urls'          => [
                {   'expanded_url' => undef,
                    'url'          => 'http://j.mp/qRYF8q',
                    'indices'      => [ 31, 49 ]
                }
            ]
        },
        'truncated'                 => 0,
        'created_at'                => 'Sun Sep 04 07:28:58 +0000 2011',
        'in_reply_to_status_id_str' => undef,
        'contributors'              => undef,
        'text' =>
            "\x{201c}Could You Afford to be Poor?\x{201d} http://j.mp/qRYF8q",
        'in_reply_to_user_id' => undef,
        'user'                => {
            'friends_count'       => 633,
            'follow_request_sent' => 0,
            'profile_image_url' =>
                'http://a3.twimg.com/profile_images/1393608228/wheeler_square_normal.jpg',
            'profile_background_image_url_https' =>
                'https://si0.twimg.com/images/themes/theme14/bg.gif',
            'profile_sidebar_fill_color' => 'efefef',
            'profile_background_color'   => '131516',
            'notifications'              => 0,
            'url'                        => 'http://www.justatheory.com/',
            'id'                         => 656233,
            'is_translator'              => 0,
            'following'                  => 1,
            'screen_name'                => 'theory',
            'lang'                       => 'en',
            'location'                   => 'Portland, OR, USA',
            'followers_count'            => 1350,
            'statuses_count'             => 10436,
            'name'                       => 'David E. Wheeler',
            'description' =>
                'Perl, PostgreSQL, iOS hacker; US politics junkie; Webapp developer; Portvangelist; profane iconoclast.',
            'favourites_count'        => 418,
            'profile_background_tile' => 1,
            'listed_count'            => 100,
            'contributors_enabled'    => 0,
            'profile_link_color'      => '009999',
            'profile_image_url_https' =>
                'https://si0.twimg.com/profile_images/1393608228/wheeler_square_normal.jpg',
            'profile_sidebar_border_color' => 'eeeeee',
            'created_at'            => 'Wed Jan 17 19:31:24 +0000 2007',
            'utc_offset'            => -28800,
            'verified'              => 0,
            'show_all_inline_media' => 0,
            'profile_background_image_url' =>
                'http://a1.twimg.com/images/themes/theme14/bg.gif',
            'default_profile'              => 0,
            'protected'                    => 0,
            'id_str'                       => '656233',
            'profile_text_color'           => '333333',
            'default_profile_image'        => 0,
            'time_zone'                    => 'Pacific Time (US & Canada)',
            'geo_enabled'                  => 1,
            'profile_use_background_image' => 1
        },
        'id'                      => '110253001725321216',
        'in_reply_to_status_id'   => undef,
        'geo'                     => undef,
        'possibly_sensitive'      => 0,
        'in_reply_to_user_id_str' => undef,
        'id_str'                  => '110253001725321216',
        'in_reply_to_screen_name' => undef
    }
);

eq_or_diff(
    $tweet->to_email->as_string,
    "From: \"David E. Wheeler\" <theory\@twitter> (theory)
Subject:
 =?UTF-8?Q?=E2=80=9CCould=20You=20Afford=20t?==?UTF-8?Q?o=20be=20Poor?=?
 =?UTF-8?Q?=E2=80=9D=20http?=://ehrenreich.blogs.com/barbaras_blog/2006/07/
 could_you_affor.html
Date: Sun, 4 Sep 2011 08:28:58 +0100
Message-Id: <110253001725321216\@twitter>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary=\"1317546824.2C8b2BC51.4794\"; charset=\"utf-8\"


--1317546824.2C8b2BC51.4794
Date: Sun, 4 Sep 2011 08:28:58 +0100
MIME-Version: 1.0
Content-Type: text/plain; charset=\"utf-8\"
Content-Disposition: inline

\x{201c}Could You Afford to be Poor?\x{201d}
http://ehrenreich.blogs.com/barbaras_blog/2006/07/could_you_affor.html

https://twitter.com/theory/status/110253001725321216
--1317546824.2C8b2BC51.4794
Date: Sun, 4 Sep 2011 08:28:58 +0100
MIME-Version: 1.0
Content-Type: text/html; charset=\"utf-8\"
Content-Disposition: inline

\x{201c}Could You Afford to be Poor?\x{201d} <a href=\"http://ehrenreich.blogs.com/barbaras_blog/2006/07/could_you_affor.html\">http://ehrenreich.blogs.com/barbaras_blog/2006/07/could_you_affor.html</a>
<br/><br/>
<br/><br/>

<a href=\"https://twitter.com/theory/status/110253001725321216\">https://twitter.com/theory/status/110253001725321216</a>
--1317546824.2C8b2BC51.4794--
"
);

$tweet = App::Twimap::Tweet->new(
    data => {
        'retweeted' => 0,
        'source' =>
            '<a href="http://itunes.apple.com/us/app/twitter/id409789998?mt=12" rel="nofollow">Twitter for Mac</a>',
        'favorited'     => 0,
        'coordinates'   => undef,
        'place'         => undef,
        'retweet_count' => 0,
        'entities'      => {
            'hashtags' => [
                {   'text'    => 'SpaceChem',
                    'indices' => [ 108, 118 ]
                }
            ],
            'user_mentions' => [],
            'urls'          => [
                {   'display_url' => "spacechem.net/solution/no-or\x{2026}",
                    'expanded_url' =>
                        'http://spacechem.net/solution/no-ordinary-headache/22106',
                    'url'     => 'http://t.co/83GKUnF',
                    'indices' => [ 42, 61 ]
                },
                {   'display_url' => "spacechem.net/solution/no-or\x{2026}",
                    'expanded_url' =>
                        'http://spacechem.net/solution/no-ordinary-headache/1717',
                    'url'     => 'http://t.co/YavM3cs',
                    'indices' => [ 87, 106 ]
                }
            ]
        },
        'truncated'                 => 0,
        'created_at'                => 'Sun Sep 04 06:28:25 +0000 2011',
        'in_reply_to_status_id_str' => undef,
        'contributors'              => undef,
        'text' =>
            'The difference between a good programmer (http://t.co/83GKUnF) and a GREAT programmer (http://t.co/YavM3cs) #SpaceChem',
        'in_reply_to_user_id' => undef,
        'user'                => {
            'friends_count'       => 202,
            'follow_request_sent' => 0,
            'profile_image_url' =>
                'http://a3.twimg.com/profile_images/1351310559/MSCHWERN_HAS_A_PAUSEID_normal.jpg',
            'profile_background_image_url_https' =>
                'https://si0.twimg.com/profile_background_images/2458594/It_s_A_Waffle_Window_Day_.jpg',
            'profile_sidebar_fill_color' => 'A8FF82',
            'profile_background_color'   => 'F36A28',
            'notifications'              => 0,
            'url'                        => 'http://schwern.net',
            'id'                         => 8263212,
            'is_translator'              => 0,
            'following'                  => 1,
            'screen_name'                => 'schwern',
            'lang'                       => 'en',
            'location'                   => 'Portland, OR, USA',
            'followers_count'            => 960,
            'statuses_count'             => 4342,
            'name'                       => 'Schwern',
            'description' => 'Bystanders were amazed at the volume of blood',
            'favourites_count'        => 0,
            'profile_background_tile' => 0,
            'listed_count'            => 139,
            'contributors_enabled'    => 0,
            'profile_link_color'      => '0000ff',
            'profile_image_url_https' =>
                'https://si0.twimg.com/profile_images/1351310559/MSCHWERN_HAS_A_PAUSEID_normal.jpg',
            'profile_sidebar_border_color' => '41E62D',
            'created_at'            => 'Sat Aug 18 09:16:37 +0000 2007',
            'utc_offset'            => -28800,
            'verified'              => 0,
            'show_all_inline_media' => 0,
            'profile_background_image_url' =>
                'http://a1.twimg.com/profile_background_images/2458594/It_s_A_Waffle_Window_Day_.jpg',
            'default_profile'              => 0,
            'protected'                    => 0,
            'id_str'                       => '8263212',
            'profile_text_color'           => '000000',
            'default_profile_image'        => 0,
            'time_zone'                    => 'Pacific Time (US & Canada)',
            'geo_enabled'                  => 0,
            'profile_use_background_image' => 1
        },
        'id'                      => '110237761818210305',
        'in_reply_to_status_id'   => undef,
        'geo'                     => undef,
        'possibly_sensitive'      => 0,
        'in_reply_to_user_id_str' => undef,
        'id_str'                  => '110237761818210305',
        'in_reply_to_screen_name' => undef
    }
);

eq_or_diff(
    $tweet->to_email->as_string,
    'From: "Schwern" <schwern@twitter> (schwern)
Subject: The difference between a good programmer
 (http://spacechem.net/solution/ no-ordinary-headache/22106) and a GREAT
 programmer (http://spacechem.net/ solution/no-ordinary-headache/1717)
 #SpaceChem
Date: Sun, 4 Sep 2011 07:28:25 +0100
Message-Id: <110237761818210305@twitter>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="1317546824.2C8b2BC51.4794"; charset="utf-8"


--1317546824.2C8b2BC51.4794
Date: Sun, 4 Sep 2011 07:28:25 +0100
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Disposition: inline

The difference between a good programmer
(http://spacechem.net/solution/no-ordinary-headache/22106) and a GREAT
programmer (http://spacechem.net/solution/no-ordinary-headache/1717)
#SpaceChem

https://twitter.com/schwern/status/110237761818210305
--1317546824.2C8b2BC51.4794
Date: Sun, 4 Sep 2011 07:28:25 +0100
MIME-Version: 1.0
Content-Type: text/html; charset="utf-8"
Content-Disposition: inline

The difference between a good programmer (<a href="http://spacechem.net/solution/no-ordinary-headache/22106">http://spacechem.net/solution/no-ordinary-headache/22106</a>) and a GREAT programmer (<a href="http://spacechem.net/solution/no-ordinary-headache/1717">http://spacechem.net/solution/no-ordinary-headache/1717</a>) #SpaceChem
<br/><br/>
<br/><br/>

<a href="https://twitter.com/schwern/status/110237761818210305">https://twitter.com/schwern/status/110237761818210305</a>
--1317546824.2C8b2BC51.4794--
'
);

$tweet = App::Twimap::Tweet->new(
    data => {
        'source' =>
            '<a href="http://www.hootsuite.com" rel="nofollow">HootSuite</a>',
        'retweeted'     => 0,
        'favorited'     => 0,
        'coordinates'   => undef,
        'place'         => undef,
        'retweet_count' => 0,
        'entities'      => {
            'hashtags'      => [],
            'user_mentions' => [
                {   'name'        => 'Shingo Hatazawa',
                    'id'          => 135685499,
                    'indices'     => [ 18, 29 ],
                    'id_str'      => '135685499',
                    'screen_name' => 'lunashingo'
                },
                {   'name'        => 'Dan Kogai',
                    'id'          => 4143991,
                    'indices'     => [ 80, 89 ],
                    'id_str'      => '4143991',
                    'screen_name' => 'dankogai'
                }
            ],
            'urls' => [
                {   'expanded_url' => undef,
                    'url'          => 'http://j.mp/fzyiTx',
                    'indices'      => [ 91, 109 ]
                }
            ]
        },
        'truncated'                 => 0,
        'in_reply_to_status_id_str' => undef,
        'created_at'                => 'Tue Sep 13 16:27:16 +0000 2011',
        'contributors'              => undef,
        'text' =>
            "\x{6539}\x{3081}\x{3066}\x{5fa1}\x{793c}\x{306a}\x{3046}m(__)m&lt; \@lunashingo: reply\x{3042}\x{308a}\x{304c}\x{3068}\x{3046}\x{3054}\x{3056}\x{3044}\x{307e}\x{3059}\x{3002}\x{65e9}\x{901f}\x{8cfc}\x{5165}\x{3057}\x{307e}\x{3057}\x{305f}\x{3002}\x{300c}\x{65b0}\x{66f8}\x{304c}\x{30d9}\x{30b9}\x{30c8}\x{300d}\x{3082}\x{597d}\x{304d}\x{3067}\x{3088}\x{304f}\x{8aad}\x{3093}\x{3067}\x{3044}\x{307e}\x{3059}&lt;\@dankogai: http://j.mp/fzyiTx",
        'in_reply_to_user_id' => undef,
        'user'                => {
            'friends_count'       => 2584,
            'follow_request_sent' => 0,
            'profile_background_image_url_https' =>
                'https://si0.twimg.com/profile_background_images/55559817/hisashinis-512x512.jpg',
            'profile_image_url' =>
                'http://a3.twimg.com/profile_images/1198753933/dan-by-tanaka_normal.png',
            'profile_sidebar_fill_color' => 'DDEEF6',
            'profile_background_color'   => 'C0DEED',
            'notifications'              => 0,
            'url'             => 'http://blog.livedoor.jp/dankogai/',
            'id'              => 4143991,
            'is_translator'   => 0,
            'following'       => 1,
            'screen_name'     => 'dankogai',
            'lang'            => 'en',
            'location'        => 'In front of your timeline',
            'followers_count' => 44914,
            'statuses_count'  => 20061,
            'name'            => 'Dan Kogai',
            'description' =>
                '404 Blog Not Found -- only tweets. http://www.google.com/search?q=dankogai',
            'favourites_count'        => 11,
            'profile_background_tile' => 1,
            'listed_count'            => 5763,
            'contributors_enabled'    => 0,
            'profile_link_color'      => '0084B4',
            'profile_image_url_https' =>
                'https://si0.twimg.com/profile_images/1198753933/dan-by-tanaka_normal.png',
            'profile_sidebar_border_color' => 'C0DEED',
            'created_at' => 'Wed Apr 11 08:26:14 +0000 2007',
            'utc_offset' => 32400,
            'verified'   => 0,
            'profile_background_image_url' =>
                'http://a3.twimg.com/profile_background_images/55559817/hisashinis-512x512.jpg',
            'show_all_inline_media'        => 0,
            'protected'                    => 0,
            'default_profile'              => 0,
            'id_str'                       => '4143991',
            'profile_text_color'           => '333333',
            'default_profile_image'        => 0,
            'time_zone'                    => 'Tokyo',
            'profile_use_background_image' => 1,
            'geo_enabled'                  => 1
        },
        'id'                      => '113649960246980608',
        'in_reply_to_status_id'   => undef,
        'geo'                     => undef,
        'possibly_sensitive'      => 0,
        'in_reply_to_user_id_str' => undef,
        'id_str'                  => '113649960246980608',
        'in_reply_to_screen_name' => undef
    }
);

eq_or_diff(
    $tweet->to_email->as_string,
    "From: \"Dan Kogai\" <dankogai\@twitter> (dankogai)
Subject:
 =?UTF-8?Q?=E6=94=B9=E3=82=81=E3=81=A6=E5=BE=A1=E7=A4=BC=E3=81=AA=E3=81=86?=
 =?UTF-8?Q?m?=(__)m< \@lunashingo:
 =?UTF-8?Q?=20reply=E3=81=82=E3=82=8A=E3=81=8C=E3=81=A8=E3=81=86?=
 =?UTF-8?Q?=E3=81=94=E3=81=96=E3=81=84=E3=81=BE=E3=81=99=E3=80=82=E6=97=A9?=
 =?UTF-8?Q?=E9=80=9F=E8=B3=BC=E5=85=A5=E3=81=97=E3=81=BE=E3=81=97=E3=81=9F?=
 =?UTF-8?Q?=E3=80=82=E3=80=8C=E6=96=B0=E6=9B=B8=E3=81=8C=E3=83=99=E3=82=B9?=
 =?UTF-8?Q?=E3=83=88=E3=80=8D=E3=82=82=E5=A5=BD=E3=81=8D=E3=81=A7=E3=82=88?=
 =?UTF-8?Q?=E3=81=8F=E8=AA=AD=E3=82=93=E3=81=A7=E3=81=84=E3=81=BE=E3=81=99?=
 <\@dankogai: http://blog.livedoor.jp/dankogai/archives/51529999.html
Date: Tue, 13 Sep 2011 17:27:16 +0100
Message-Id: <113649960246980608\@twitter>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary=\"1317546824.2C8b2BC51.4794\"; charset=\"utf-8\"


--1317546824.2C8b2BC51.4794
Date: Tue, 13 Sep 2011 17:27:16 +0100
MIME-Version: 1.0
Content-Type: text/plain; charset=\"utf-8\"
Content-Disposition: inline

\x{6539}\x{3081}\x{3066}\x{5fa1}\x{793c}\x{306a}\x{3046}m(__)m&lt; \@lunashingo:
reply\x{3042}\x{308a}\x{304c}\x{3068}\x{3046}\x{3054}\x{3056}\x{3044}\x{307e}\x{3059}\x{3002}\x{65e9}\x{901f}\x{8cfc}\x{5165}\x{3057}\x{307e}\x{3057}\x{305f}\x{3002}\x{300c}\x{65b0}\x{66f8}\x{304c}\x{30d9}\x{30b9}\x{30c8}\x{300d}\x{3082}\x{597d}\x{304d}\x{3067}\x{3088}\x{304f}\x{8aad}\x{3093}\x{3067}\x{3044}\x{307e}\x{3059}&lt;\@dankogai:
http://blog.livedoor.jp/dankogai/archives/51529999.html

https://twitter.com/dankogai/status/113649960246980608
--1317546824.2C8b2BC51.4794
Date: Tue, 13 Sep 2011 17:27:16 +0100
MIME-Version: 1.0
Content-Type: text/html; charset=\"utf-8\"
Content-Disposition: inline

\x{6539}\x{3081}\x{3066}\x{5fa1}\x{793c}\x{306a}\x{3046}m(__)m&lt; \@lunashingo: reply\x{3042}\x{308a}\x{304c}\x{3068}\x{3046}\x{3054}\x{3056}\x{3044}\x{307e}\x{3059}\x{3002}\x{65e9}\x{901f}\x{8cfc}\x{5165}\x{3057}\x{307e}\x{3057}\x{305f}\x{3002}\x{300c}\x{65b0}\x{66f8}\x{304c}\x{30d9}\x{30b9}\x{30c8}\x{300d}\x{3082}\x{597d}\x{304d}\x{3067}\x{3088}\x{304f}\x{8aad}\x{3093}\x{3067}\x{3044}\x{307e}\x{3059}&lt;\@dankogai: <a href=\"http://blog.livedoor.jp/dankogai/archives/51529999.html\">http://blog.livedoor.jp/dankogai/archives/51529999.html</a>
<br/><br/>
<br/><br/>

<a href=\"https://twitter.com/dankogai/status/113649960246980608\">https://twitter.com/dankogai/status/113649960246980608</a>
--1317546824.2C8b2BC51.4794--
"
);

done_testing();

