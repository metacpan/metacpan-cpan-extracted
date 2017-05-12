use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'error when fetching new feed and old feed present',
    [
        'App::Rssfilter::Feed::Tester',
        'App::Rssfilter::Feed::Test::AttemptsToFetchNewFeed',
        'App::Rssfilter::Feed::Test::ChecksOldFeed',
        'App::Rssfilter::Feed::Test::ExistingFeedNotReplaced',
        'App::Rssfilter::Feed::Test::RulesRanOverOldFeed',
    ],
    {
        fetched_headers => <<'EOM',
HTTP/1.0 404 Not Found
Date: Sun, 05 Aug 2012 10:34:56 GMT
EOM
        old_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hello</description></item></channel></rss>
EOM
    }
);

done_testing;
