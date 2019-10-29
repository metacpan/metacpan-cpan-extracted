use strict;
use warnings;
use Test::More;
use Test::DBIC::ExpectedQueries;
use DBIx::Class::ResultSet::RecursiveUpdate;

use lib 't/lib';
use DBSchema;

my $schema = DBSchema->get_test_schema();
my $queries = Test::DBIC::ExpectedQueries->new({ schema => $schema });

my $rs_users = $schema->resultset('User');

my $user = $rs_users->create({
  name       => 'cache name',
  username   => 'cache username',
  password   => 'cache username',
});

my $dvd = $schema->resultset('Dvd')->create({
    name => 'existing DVD',
    owner => $user->id,
    dvdtags => [{
        tag => 1,
    },
    {
        tag => {
            name => 'crime'
        },
    }],
});

my $rs_users_without_cache = $rs_users->search_rs({
    'me.id' => $user->id
});
$queries->run(sub {
    $rs_users_without_cache->recursive_update({
        id => $user->id,
        name => 'updated name',
    });
});
$queries->test({
    usr => {
        select => 1,
        update => 1,
    },
}, 'expected queries without cache');


my $rs_users_with_cache = $rs_users->search_rs({
    'me.id' => $user->id
}, {
    cache => 1,
});

diag("populate cache");
$rs_users_with_cache->all;

$queries->run(sub {
    $rs_users_with_cache->recursive_update({
        id => $user->id,
        name => 'updated name 2',
    });
});
$queries->test({
    usr => {
        update => 1,
    },
}, 'expected queries with cache');

# test related rows cache not used after update
$rs_users_with_cache = $rs_users->search_rs({
    'me.id' => $user->id
}, {
    prefetch => 'owned_dvds',
    cache => 1,
});
diag("populate cache");
$rs_users_with_cache->all;

$queries->run(sub {
    $rs_users_with_cache->recursive_update({
        id         => $user->id,
        name       => 'cache name updated',
        owned_dvds => [
            {
                dvd_id => 5,
            }
        ],
    });
});
$queries->test({
    usr => {
        update => 1,
    },
}, 'expected queries with unchanged has_many relationship and cache');

$rs_users_with_cache = $rs_users->search_rs({
    'me.id' => $user->id
}, {
    prefetch => {
        owned_dvds => {
            'dvdtags' => 'tag'
        }
    },
    cache => 1,
});

diag("populate cache");
$rs_users_with_cache->all;

$queries->run(sub {
    $rs_users_with_cache->recursive_update({
        id => $user->id,
        owned_dvds => [
            {
                dvd_id => $dvd->id,
                name => 'existing DVD',
            },
            {
                name => 'new DVD',
            }
        ]
    });
});
$queries->test({
    dvd => {
        insert => 1,
        # one by the discard_changes call for created rows
        select => 1,
    },
}, 'expected queries with has_many relationship and cache');

$rs_users_with_cache = $rs_users->search_rs({
    'me.id' => $user->id
}, {
    prefetch => {
        owned_dvds => {
            'dvdtags' => 'tag'
        }
    },
    cache => 1,
});

diag("populate cache");
$rs_users_with_cache->all;

ok (my $new_dvd = $user->owned_dvds->find({ name => 'new DVD'}), 'new DVD found');

$queries->run(sub {
    $rs_users_with_cache->recursive_update({
        id => $user->id,
        owned_dvds => [
            {
                dvd_id => $dvd->id,
                tags => [ 1, 3 ],
            },
            {
                dvd_id => $new_dvd->id,
                tags => [ 2, 3 ],
            }
        ]
    });
});
$queries->test({
    dvdtag => {
        # one for tag 3 of 'existing DVD'
        # two for tags 2 and 3 of 'new DVD'
        insert => 3,
        # one for the find of existing tag 3 of 'existing DVD'
        # one from the discard_changes call for created tag 3 of 'existing DVD'
        # two for the find of the two existing tags of 'new DVD'
        # two from the discard_changes call for created tags of 'new DVD'
        select => 6,
        # this is the cleanup query which deletes all tags of a dvd not
        # passed to tags, in this case the 'crime' tag created above
        delete => 1,
    },
}, 'expected queries with many_to_many relationship helper and cache');

done_testing;
