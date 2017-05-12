use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'set_name called when storage has no name',
    [
        'App::Rssfilter::Feed::Storage::Tester',
        'App::Rssfilter::Feed::Storage::Test::SetName',
    ],
    {
        feed_name => undef,
    }
);

done_testing;
