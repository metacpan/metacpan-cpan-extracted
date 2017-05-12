use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'new feed available and old feed present',
    [
        'App::Rssfilter::Feed::Tester',
        'App::Rssfilter::Feed::Test::AttemptsToFetchNewFeed',
        'App::Rssfilter::Feed::Test::ChecksOldFeed',
        'App::Rssfilter::Feed::Test::SavesNewFeed',
        'App::Rssfilter::Feed::Test::RulesRanOverNewFeed',
        'App::Rssfilter::Feed::Test::RulesRanOverOldFeed',
    ],
    {
        new_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hi</description></item></channel></rss>
EOM
        old_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hello</description></item></channel></rss>
EOM
    }
);

done_testing;
