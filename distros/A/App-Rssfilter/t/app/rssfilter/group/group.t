use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'group',
    [
        'App::Rssfilter::Group::Tester',
        'App::Rssfilter::Group::Test::AddedRule',
        'App::Rssfilter::Group::Test::AddedFeed',
        'App::Rssfilter::Group::Test::AddedGroup',
        'App::Rssfilter::Group::Test::FetchedSubgroupByName',
        'App::Rssfilter::Group::Test::FetchedFeedByName',
    ],
);

done_testing;
