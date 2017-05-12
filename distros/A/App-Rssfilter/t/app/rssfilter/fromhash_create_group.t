use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'create a group from a hash',
    [
        'App::Rssfilter::FromHash::Tester',
        'App::Rssfilter::FromHash::Test::CreateGroup',
    ],
);

done_testing;
