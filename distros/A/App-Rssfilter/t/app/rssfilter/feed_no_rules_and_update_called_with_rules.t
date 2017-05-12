use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'create with no rules then called update with a rule',
    [
        'App::Rssfilter::Feed::Tester',
        'App::Rssfilter::Feed::Test::UpdateWithRule',
        'App::Rssfilter::Feed::Test::RulesRanOverNewFeed',
        'App::Rssfilter::Feed::Test::RulesRanOverOldFeed',
    ],
    {
        new_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hi</description></item></channel></rss>
EOM
        rules => [],
        old_feed => <<'EOM',
<?xml version="1.0" encoding="UTF-8"?>
<rss><channel><item><description>hello</description></item></channel></rss>
EOM
        last_modified => 'Thu, 01 Jan 1970 00:00:00 GMT',
    }
);

done_testing;
