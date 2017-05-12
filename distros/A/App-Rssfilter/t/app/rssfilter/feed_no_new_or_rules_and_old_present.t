use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'no new feed available and no rules and old feed present',
    [
        'App::Rssfilter::Feed::Tester',
        'App::Rssfilter::Feed::Test::AttemptsToFetchNewFeed',
        'App::Rssfilter::Feed::Test::ChecksOldFeed',
        'App::Rssfilter::Feed::Test::ExistingFeedNotReplaced',
        'App::Rssfilter::Feed::Test::RulesNotRun',
    ],
    {
        fetched_headers => <<'EOM',
HTTP/1.0 304 Not Modified
Date: Thu, 01 Jan 1970 00:00:00 GMT
EOM
        rules => [],
        old_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hello</description></item></channel></rss>
EOM
    }
);

done_testing;
