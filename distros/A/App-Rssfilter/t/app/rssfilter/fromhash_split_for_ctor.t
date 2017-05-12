use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

run_tests(
    'splits lists of scalars, hashrefs, objects into params suitable for ctors',
    [
        'App::Rssfilter::FromHash::Tester',
        'App::Rssfilter::FromHash::Test::SplitForCtor',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithTwoScalars',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithHashRef',
        'App::Rssfilter::FromHash::Test::SplitForCtorWithObject',
    ],
);

done_testing;
