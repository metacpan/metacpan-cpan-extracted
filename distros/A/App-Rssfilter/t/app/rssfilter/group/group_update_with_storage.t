use strict;
use warnings;

use Test::Routine::Util;
use Test::Most;
use lib qw< t/lib >;

use App::Rssfilter::Group;
use Test::MockObject;

my $mock_storage = Test::MockObject->new;
$mock_storage->set_isa( 'App::Rssfilter::Feed::Storage' );
$mock_storage->set_true( 'path_push' );

my $group = App::Rssfilter::Group->new(
    name => 'making paper',
    storage => $mock_storage,
);

run_tests(
    'group',
    [
        'App::Rssfilter::Group::Tester',
        'App::Rssfilter::Group::Test::UpdateWithStorage',
        'App::Rssfilter::Group::Test::UpdatedFeed',
        'App::Rssfilter::Group::Test::UpdatedGroup',
    ],
    {
        group => $group,
        group_name => 'making paper',
    }
);

done_testing;
