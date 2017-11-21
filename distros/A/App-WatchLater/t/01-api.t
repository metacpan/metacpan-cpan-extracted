use 5.016;
use strict;
use warnings;

use JSON;

use Test::More tests => 6;
use Test::MockObject::Extends;

use constant VIDEO_ID => 'Ks-_Mh1QhMc';
use constant BOGUS_API_KEY => 'bogus';

my $module = 'App::WatchLater::YouTube';
use_ok($module);

my @methods = qw(new get_video);
can_ok $module, $_ or BAIL_OUT for (@methods);

my $http = Test::MockObject::Extends->new('HTTP::Tiny');
$http->mock('request' => sub {
              my (undef, undef, $url) = @_;
              say $url;
              isnt index($url, VIDEO_ID), -1, 'request URL contains video id';
              return {
                content => do { local $/; <DATA> },
                success => 1,
              };
            });

my $api = new_ok($module => [ http => $http, api_key => BOGUS_API_KEY ]);
my $snippet = $api->get_video(VIDEO_ID);

like $snippet->{title}, qr/body language/i, 'title contains expected phrase';

__DATA__
{
 "kind": "youtube#videoListResponse",
 "etag": "\"ld9biNPKjAjgjV7EZ4EKeEGrhao/ifjnZt5kLUd4Y4fBD3-rS1_cKrs\"",
 "pageInfo": {
  "totalResults": 1,
  "resultsPerPage": 1
 },
 "items": [
  {
   "kind": "youtube#video",
   "etag": "\"ld9biNPKjAjgjV7EZ4EKeEGrhao/dNpQl9nRjC0mm4H-yofg_0bQ_1I\"",
   "id": "Ks-_Mh1QhMc",
   "snippet": {
    "publishedAt": "2012-10-01T15:27:35.000Z",
    "channelId": "UCAuUUnT6oDeKwE6v1NGQxug",
    "title": "Your body language may shape who you are | Amy Cuddy",
    "description": "Body language affects how others see us, but it may also change how we see ourselves. Social psychologist Amy Cuddy argues that \"power posing\" -- standing in a posture of confidence, even when we don't feel confident -- can boost feelings of confidence, and might have an impact on our chances for success. (Note: Some of the findings presented in this talk have been referenced in an ongoing debate among social scientists about robustness and reproducibility. Read Amy Cuddy's response here: http://ideas.ted.com/inside-the-debate-about-power-posing-a-q-a-with-amy-cuddy/)\n\nThe TED Talks channel features the best talks and performances from the TED Conference, where the world's leading thinkers and doers give the talk of their lives in 18 minutes (or less). Look for talks on Technology, Entertainment and Design -- plus science, business, global issues, the arts and more.\n\nFollow TED on Twitter: http://www.twitter.com/TEDTalks\nLike TED on Facebook: https://www.facebook.com/TED\n\nSubscribe to our channel: https://www.youtube.com/TED",
    "thumbnails": {
     "default": {
      "url": "https://i.ytimg.com/vi/Ks-_Mh1QhMc/default.jpg",
      "width": 120,
      "height": 90
     },
     "medium": {
      "url": "https://i.ytimg.com/vi/Ks-_Mh1QhMc/mqdefault.jpg",
      "width": 320,
      "height": 180
     },
     "high": {
      "url": "https://i.ytimg.com/vi/Ks-_Mh1QhMc/hqdefault.jpg",
      "width": 480,
      "height": 360
     },
     "standard": {
      "url": "https://i.ytimg.com/vi/Ks-_Mh1QhMc/sddefault.jpg",
      "width": 640,
      "height": 480
     },
     "maxres": {
      "url": "https://i.ytimg.com/vi/Ks-_Mh1QhMc/maxresdefault.jpg",
      "width": 1280,
      "height": 720
     }
    },
    "channelTitle": "TED",
    "tags": [
     "Amy Cuddy",
     "TED",
     "TEDTalk",
     "TEDTalks",
     "TED Talk",
     "TED Talks",
     "TEDGlobal",
     "brain",
     "business",
     "psychology",
     "self",
     "success"
    ],
    "categoryId": "22",
    "liveBroadcastContent": "none",
    "defaultLanguage": "en",
    "localized": {
     "title": "Your body language may shape who you are | Amy Cuddy",
     "description": "Body language affects how others see us, but it may also change how we see ourselves. Social psychologist Amy Cuddy argues that \"power posing\" -- standing in a posture of confidence, even when we don't feel confident -- can boost feelings of confidence, and might have an impact on our chances for success. (Note: Some of the findings presented in this talk have been referenced in an ongoing debate among social scientists about robustness and reproducibility. Read Amy Cuddy's response here: http://ideas.ted.com/inside-the-debate-about-power-posing-a-q-a-with-amy-cuddy/)\n\nThe TED Talks channel features the best talks and performances from the TED Conference, where the world's leading thinkers and doers give the talk of their lives in 18 minutes (or less). Look for talks on Technology, Entertainment and Design -- plus science, business, global issues, the arts and more.\n\nFollow TED on Twitter: http://www.twitter.com/TEDTalks\nLike TED on Facebook: https://www.facebook.com/TED\n\nSubscribe to our channel: https://www.youtube.com/TED"
    },
    "defaultAudioLanguage": "en"
   }
  }
 ]
}
