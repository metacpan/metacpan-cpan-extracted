#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use lib 'lib';

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use TestSchema;
use DBIx::Class::Async::Schema;

my $dbfile = 't/test_clone.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

for my $i (1..5) {
    $schema->resultset('User')->create({
        name   => "User$i",
        email  => "user$i\@example.com",
        active => 1,
    });
}

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

subtest 'clone() - returns new object' => sub {

    my $clone = $async_schema->clone;

    ok($clone, 'clone() returns a defined value');
    isa_ok($clone, 'DBIx::Class::Async::Schema',
        'Clone is a Schema object');
    isnt($clone, $async_schema,
        'Clone is a different object reference');
};

subtest 'clone() - correct class' => sub {

    my $clone = $async_schema->clone;

    is(ref($clone), ref($async_schema),
        'Clone has same class as original');
    isa_ok($clone, ref($async_schema),
        'Clone isa same type as original');
};

subtest 'clone() - has independent async_db' => sub {

    my $clone = $async_schema->clone;

    ok($clone->{async_db}, 'Clone has async_db');
    isnt($clone->{async_db}, $async_schema->{async_db},
        'Clone has different async_db instance');
};

subtest 'clone() - has fresh sources cache' => sub {

    # Access a source to populate cache
    my $original_source = $async_schema->source('User');
    ok(keys %{$async_schema->{sources_cache}},
        'Original has cached sources');

    my $clone = $async_schema->clone;

    is_deeply($clone->{sources_cache}, {},
        'Clone has empty sources cache');
    isnt($clone->{sources_cache}, $async_schema->{sources_cache},
        'Clone has different cache reference');
};

subtest 'clone() - can access same data' => sub {

    my $clone = $async_schema->clone;

    # Both should access same database
    my $users_original = $async_schema->resultset('User')->all->get;
    my $users_clone = $clone->resultset('User')->all->get;

    is(scalar @$users_original, 5, 'Original sees 5 users');
    is(scalar @$users_clone, 5, 'Clone sees 5 users');

    is($users_original->[0]->name, 'User1',
        'Original reads correct data');
    is($users_clone->[0]->name, 'User1',
        'Clone reads correct data');
};

subtest 'clone() - independent operations' => sub {

    my $clone = $async_schema->clone;

    # Create via clone
    my $new_user = $clone->resultset('User')
        ->create({
            name => 'CloneUser',
            email => 'clone@example.com',
            active => 1
        })->get;

    ok($new_user, 'Clone can create records');
    is($new_user->name, 'CloneUser', 'Clone created correct user');

    # Verify original can see it too (same database)
    my $results = $async_schema->resultset('User')
        ->search({ name => 'CloneUser' })
        ->all->get;

    my $found = $results->[0];

    ok($found, 'Original can see record created by clone');
    is($found->name, 'CloneUser',
        'Original sees correct data');
};

subtest 'clone() - has same schema_class' => sub {

    my $clone = $async_schema->clone;

    is($clone->{schema_class}, $async_schema->{schema_class},
        'Clone has same schema_class');
};

subtest 'clone() - has same connect_info' => sub {

    my $clone = $async_schema->clone;

    ok($clone->{connect_info}, 'Clone has connect_info');

    # Should have same DSN (first element)
    is($clone->{connect_info}[0], $async_schema->{connect_info}[0],
        'Clone has same DSN');
};

subtest 'clone() - resultset operations work' => sub {

    my $clone = $async_schema->clone;

    my $users = $clone->resultset('User')
        ->search({ active => 1 })
        ->all->get;
    ok(@$users > 0, 'Clone can search');

    my $count = $clone->resultset('User')->count->get;
    cmp_ok($count, '>=', 5, 'Clone can count');

    my $user = $clone->resultset('User')->find(1)->get;
    ok($user, 'Clone can find');
};

subtest 'clone() - can create multiple clones' => sub {

    my $clone1 = $async_schema->clone;
    my $clone2 = $async_schema->clone;
    my $clone3 = $async_schema->clone;

    isnt($clone1, $clone2, 'Clone 1 and 2 are different');
    isnt($clone2, $clone3, 'Clone 2 and 3 are different');
    isnt($clone1, $clone3, 'Clone 1 and 3 are different');

    isnt($clone1->{async_db}, $clone2->{async_db},
        'Clones have different async_db instances');
};

subtest 'clone() - all clones work independently' => sub {

    my $clone1 = $async_schema->clone;
    my $clone2 = $async_schema->clone;

    # Use unique names to avoid conflicts with other subtests
    # Create via clone1
    $clone1->resultset('User')
        ->create({
            name => 'MultiClone1User',
            email => 'multiclone1@example.com',
            active => 1
        })->get;

    # Create via clone2
    $clone2->resultset('User')
        ->create({
            name => 'MultiClone2User',
            email => 'multiclone2@example.com',
            active => 1
        })->get;

    # All three should see both records
    my $orig_count = $async_schema->resultset('User')
        ->search({ name => { -like => 'MultiClone%User' } })
        ->count->get;
    is($orig_count, 2, 'Original sees both records');

    my $clone1_count = $clone1->resultset('User')
        ->search({ name => { -like => 'MultiClone%User' } })
        ->count->get;
    is($clone1_count, 2, 'Clone1 sees both records');

    my $clone2_count = $clone2->resultset('User')
        ->search({ name => { -like => 'MultiClone%User' } })
        ->count->get;
    is($clone2_count, 2, 'Clone2 sees both records');

    # Verify each can find their own created record
    my $results1 = $clone1->resultset('User')
        ->search({ name => 'MultiClone1User' })->all->get;
    ok($results1->[0], 'Clone1 can find its record');

    my $results2 = $clone2->resultset('User')
        ->search({ name => 'MultiClone2User' })->all->get;
    ok($results2->[0], 'Clone2 can find its record');

    my $orig_results = $async_schema->resultset('User')
        ->search({ name => 'MultiClone2User' })->all->get;
    ok($orig_results->[0], 'Original can find clone records');
};

subtest 'clone() - cache is truly independent' => sub {

    # Populate original's cache
    $async_schema->source('User');
    $async_schema->source('Order');

    my $orig_cache_size = scalar keys %{$async_schema->{sources_cache}};
    ok($orig_cache_size > 0, 'Original has cached sources');

    # Clone should start fresh
    my $clone = $async_schema->clone;
    is(scalar keys %{$clone->{sources_cache}}, 0,
        'Clone starts with empty cache');

    # Populate clone's cache
    $clone->source('User');

    is(scalar keys %{$clone->{sources_cache}}, 1,
        'Clone has 1 cached source');
    is(scalar keys %{$async_schema->{sources_cache}}, $orig_cache_size,
        'Original cache unchanged');
};

subtest 'clone() - relationships work' => sub {

    # Create user with orders
    my $user = $schema->resultset('User')->create({
        name   => 'RelUser',
        email  => 'reluser@example.com',
        active => 1,
    });

    $schema->resultset('Order')->create({
        user_id => $user->id,
        amount  => 100.00,
        status  => 'completed',
    });

    my $clone = $async_schema->clone;

    # Access relationships via clone
    my $users = $clone->resultset('User')
        ->search({ name => 'RelUser' })->all->get;

    my $found_user = $users->[0];
    ok($found_user, 'Clone can find user');

    my $orders = $found_user->orders->all->get;
    is(scalar @$orders, 1, 'Clone can access relationships');
    is($orders->[0]->amount, 100.00, 'Clone reads relationship data correctly');
};

subtest 'clone() - transactions (if supported)' => sub {

    my $clone = $async_schema->clone;

    # Both should be able to operate
    my $orig_user = $async_schema->resultset('User')
        ->create({
            name => 'OrigTx',
            email => 'origtx@example.com',
            active => 1
        })->get;

    my $clone_user = $clone->resultset('User')
        ->create({
            name => 'CloneTx',
            email => 'clonetx@example.com',
            active => 1
        })->get;

    ok($orig_user, 'Original can create in transaction');
    ok($clone_user, 'Clone can create in transaction');
};

subtest 'clone() - method availability' => sub {

    my $clone = $async_schema->clone;

    can_ok($clone, 'resultset');
    can_ok($clone, 'source');
    can_ok($clone, 'sources');
    can_ok($clone, 'class');
    can_ok($clone, 'populate');
    can_ok($clone, 'clone');  # Can clone a clone!
};

subtest 'clone() - clone of clone' => sub {

    my $clone1 = $async_schema->clone;
    my $clone2 = $clone1->clone;  # Clone of clone

    ok($clone2, 'Can clone a clone');
    isa_ok($clone2, 'DBIx::Class::Async::Schema',
        'Clone of clone is correct type');

    isnt($clone2, $clone1, 'Clone of clone is different from first clone');
    isnt($clone2, $async_schema, 'Clone of clone is different from original');
};

subtest 'clone() - stress test with concurrent operations' => sub {

    my @clones = map { $async_schema->clone } 1..5;

    is(scalar @clones, 5, 'Created 5 clones');

    # All clones create a user simultaneously
    my @futures;
    for my $i (0..$#clones) {
        push @futures, $clones[$i]->resultset('User')->create({
            name   => "Concurrent$i",
            email  => "concurrent$i\@example.com",
            active => 1,
        });
    }

    # Wait for all
    my @results = map { $_->get } @futures;

    is(scalar @results, 5, 'All clones completed operations');

    # Verify all records exist
    my $count = $async_schema->resultset('User')
        ->search({ name => { -like => 'Concurrent%' } })
        ->count->get;
    is($count, 5, 'All concurrent operations succeeded');
};

subtest 'clone() - error handling consistency' => sub {

    my $clone = $async_schema->clone;

    # Both should handle errors the same way
    eval {
        $async_schema->resultset('NonExistent')->all->get;
    };
    my $orig_error = $@;

    eval {
        $clone->resultset('NonExistent')->all->get;
    };
    my $clone_error = $@;

    ok($orig_error, 'Original throws error for invalid source');
    ok($clone_error, 'Clone throws error for invalid source');
};

subtest 'clone() - preserves schema_class setting' => sub {

    my $clone = $async_schema->clone;

    is($clone->{schema_class}, 'TestSchema',
        'Clone has correct schema_class');

    # Both should return same Result classes
    is($clone->class('User'), $async_schema->class('User'),
        'Clone returns same Result classes');
};

END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
