use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

use Test::MockObject;

run_tests(
    'group',
    [
        'App::Rssfilter::Group::Tester',
        'App::Rssfilter::Group::Test::Update',
        'App::Rssfilter::Group::Test::UpdatedFeed',
        'App::Rssfilter::Group::Test::UpdatedGroup',
    ],
    {
        rules => [],
        rules_for_update => [ Test::MockObject->new() ],
    }
);

done_testing;
