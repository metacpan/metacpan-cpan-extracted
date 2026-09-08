#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use File::Temp;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;
use Time::HiRes qw(sleep);

use lib 't/lib';

my $loop = IO::Async::Loop->new;

sub create_test_db {
    my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);
    return $db_file;
}

subtest 'Cache can be enabled globally' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create a user
    $schema->await($schema->resultset('User')->create({
        name   => 'Cache User',
        email  => 'cache@example.com',
        age    => 25,
        active => 1,
    }));

    # First query (will be cached)
    my $result1 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result1->[0]->age, 25, 'First query returned age=25');

    # Second IDENTICAL query - should use cache (no update between them!)
    my $result2 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result2->[0]->age, 25, 'Second query sees cached data (age still 25)');

    # Verify it's actually from cache
    ok($schema->{_async_db}{_stats}{_cache_hits} > 0, 'Cache was hit');

    $schema->disconnect;
};


subtest 'Cache is OFF by default' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            # No cache_ttl specified - should default to 0
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create a user
    $schema->await($schema->resultset('User')->create({
        name   => 'Test User',
        email  => 'test@example.com',
        age    => 25,
        active => 1,
    }));

    # First query
    my $result1 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is(scalar @$result1, 1, 'First query returned 1 result');
    is($result1->[0]->age, 25, 'First query shows age=25');

    # Update the user
    $schema->await($schema->resultset('User')->search({ id => 1 })->update({ age => 30 }));

    # Second query - should see the update because cache is OFF
    my $result2 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result2->[0]->age, 30, 'Second query sees updated data (cache is OFF by default)');

    # Verify cache is actually disabled
    ok(!$schema->{_async_db}{cache_ttl} || $schema->{_async_db}{cache_ttl} == 0,
       'cache_ttl is 0 by default');

    $schema->disconnect;
};

subtest 'Per-query cache control: disable cache' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,  # Cache enabled globally
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create a user
    $schema->await($schema->resultset('User')->create({
        name   => 'No Cache User',
        email  => 'nocache@example.com',
        age    => 25,
        active => 1,
    }));

    # First query with cache disabled
    my $result1 = $schema->await(
        $schema->resultset('User')->search({ id => 1 }, { cache => 0 })->all
    );
    is($result1->[0]->age, 25, 'First query returned age=25');

    # Update the user
    $schema->await($schema->resultset('User')->search({ id => 1 })->update({ age => 30 }));

    # Second query with cache disabled - should see NEW data
    my $result2 = $schema->await(
        $schema->resultset('User')->search({ id => 1 }, { cache => 0 })->all
    );
    is($result2->[0]->age, 30, 'Second query sees fresh data (cache disabled per-query)');

    $schema->disconnect;
};

subtest 'Dynamic SQL simulation with SQLite' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create a user
    $schema->await($schema->resultset('User')->create({
        name   => 'Time User',
        email  => 'time@example.com',
        active => 1,
    }));

    # SQLite equivalent: datetime('now') or strftime('%s','now')
    # First query with dynamic SQL
    my $result1 = $schema->await(
        $schema->resultset('User')->search(
            { id => 1 },
            {
                '+select'    => [ { '' => \"strftime('%Y-%m-%d %H:%M:%f', 'now')", -as => 'current_time' } ],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            }
        )->all
    );
    my $time1 = $result1->[0]->{current_time};
    ok($time1, 'Got timestamp from first query');

    sleep 1.5;  # Wait 1.5 seconds

    # Second query with same dynamic SQL
    my $result2 = $schema->await(
        $schema->resultset('User')->search(
            { id => 1 },
            {
                '+select'    => [ { '' => \"strftime('%Y-%m-%d %H:%M:%f', 'now')", -as => 'current_time' } ],
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                cache_ttl    => 0, # Disable caching for this specific search
            }
        )->all
    );
    my $time2 = $result2->[0]->{current_time};
    ok($time2, 'Got timestamp from second query');

    # Times should be different (if cache is properly bypassed)
    # If they're the same, cache is incorrectly being used
    isnt($time1, $time2, 'Dynamic SQL not cached - times are different')
        or diag("Time1: $time1, Time2: $time2 - These should be different!");

    $schema->disconnect;
};

subtest 'Clear cache method' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));


    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }
    $schema->await($schema->resultset('User')->create({
        name   => 'Clear Cache User',
        email  => 'clear@example.com',
        age    => 25,
        active => 1,
    }));

    # First query (cached)
    my $result1 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result1->[0]->age, 25, 'First query returned age=25');

    # Second query (cache hit)
    my $result2 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result2->[0]->age, 25, 'Cached query shows age=25');

    # Clear the cache
    if ($schema->resultset('User')->can('clear_cache')) {
        $schema->resultset('User')->clear_cache;
    }

    # Third query (cache miss after clear)
    my $result3 = $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($result3->[0]->age, 25, 'After clear_cache, data is re-fetched');

    # Verify cache was actually cleared and re-populated
    is($schema->{_async_db}{_stats}{_cache_misses}, 2, '2 cache misses (query 1 and after clear)');

    $schema->disconnect;
};

subtest 'Cache statistics' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create users
    for (1..3) {
        $schema->await($schema->resultset('User')->create({
            name   => "User $_",
            email  => "user$_\@example.com",
            active => 1,
        }));
    }

    # Reset stats
    $schema->{_async_db}{_stats}{_cache_hits}   = 0;
    $schema->{_async_db}{_stats}{_cache_misses} = 0;

    # First query - cache miss
    $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($schema->{_async_db}{_stats}{_cache_misses}, 1, 'First query is cache miss');
    is($schema->{_async_db}{_stats}{_cache_hits}, 0, 'No cache hits yet');

    # Second identical query - cache hit
    $schema->await($schema->resultset('User')->search({ id => 1 })->all);
    is($schema->{_async_db}{_stats}{_cache_hits}, 1, 'Second query is cache hit');
    is($schema->{_async_db}{_stats}{_cache_misses}, 1, 'Still only 1 cache miss');

    # Different query - cache miss
    $schema->await($schema->resultset('User')->search({ id => 2 })->all);
    is($schema->{_async_db}{_stats}{_cache_misses}, 2, 'Different query is cache miss');
    is($schema->{_async_db}{_stats}{_cache_hits}, 1, 'Still only 1 cache hit');

    # Repeat second query - another cache hit
    $schema->await($schema->resultset('User')->search({ id => 2 })->all);
    is($schema->{_async_db}{_stats}{_cache_hits}, 2, 'Third query is second cache hit');

    $schema->disconnect;
};

subtest 'update() invalidates the query cache (CPANSec regression)' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # Create a user
    $schema->await($schema->resultset('User')->create({
        name   => 'Update Cache User',
        email  => 'updatecache@example.com',
        age    => 25,
        active => 1,
    }));

    # First query, populates the cache with age=25
    my $result1 = $schema->await(
        $schema->resultset('User')
               ->search({ id => 1 })
               ->all
    );
    is($result1->[0]->age, 25, 'First query returned age=25 and is now cached');

    # Update via a ResultSet with a plain (non-PK) condition, followed
    # immediately by a query using a different (PK) condition, this
    # combination is what the discarded single-row cache key would have
    # missed even if it had been passed to clear_cache.
    $schema->await(
        $schema->resultset('User')
               ->search({ email => 'updatecache@example.com' })
               ->update({ age   => 99 })
    );

    # Same identical query as before the update, must NOT return stale
    # cached data. Prior to the fix, update() computed a cache key and
    # discarded it, so this would incorrectly return age=25 for the rest
    # of the TTL.
    my $result2 = $schema->await(
        $schema->resultset('User')
               ->search({ id => 1 })
               ->all
    );
    is($result2->[0]->age, 99, 'Query after update() sees fresh data, not the stale cached row');

    $schema->disconnect;
};

subtest 'cache key does not collapse to primary key alone (CPANSec CWE-639)' => sub {
    my $db_file = create_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );

    $schema->await($schema->deploy({ add_drop_table => 1 }));

    if ($schema && $schema->{_async_db}{_cache}) {
        $schema->{_async_db}{_cache}->clear;
    }

    # A single row, id => 1, "owned" by alice (using 'name' to stand in
    # for an owner/tenant predicate, as the test schema has no dedicated
    # owner column).
    $schema->await(
        $schema->resultset('User')
               ->create({
                    name   => 'alice',
                    email  => 'alice@example.com',
                    age    => 30,
                    active => 1,
                })
    );

    # alice queries for her own row scoped by id AND name, this populates
    # the cache.
    my $alice_result = $schema->await(
        $schema->resultset('User')
               ->search({ id => 1, name => 'alice' })
               ->all
    );
    is(scalar @$alice_result, 1, "alice's own scoped query returns her row");

    # bob queries for the SAME id but a DIFFERENT name/owner predicate.
    # The real database correctly returns nothing (no row matches
    # id => 1 AND name => 'bob'). Before the fix, the cache key was
    # collapsed to just { id => 1 } as soon as a primary key appeared in
    # the condition, so this would incorrectly be served alice's cached
    # row.
    my $bob_result = $schema->await(
        $schema->resultset('User')
               ->search({ id => 1, name => 'bob' })
               ->all
    );
    is(scalar @$bob_result, 0,
        "a different owner's identically-id-scoped query does not receive alice's cached row");

    $schema->disconnect;
};

subtest 'query cache is isolated per connection (CPANSec CWE-639)' => sub {
    my $db_file_1 = create_test_db();
    my $db_file_2 = create_test_db();

    my $schema1 = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file_1", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );
    $schema1->await($schema1->deploy({ add_drop_table => 1 }));
    $schema1->{_async_db}{_cache}->clear if $schema1->{_async_db}{_cache};

    my $schema2 = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file_2", undef, undef, {},
        {
            workers      => 2,
            schema_class => 'TestSchema',
            async_loop   => $loop,
            cache_ttl    => 60,
        }
    );
    $schema2->await($schema2->deploy({ add_drop_table => 1 }));
    $schema2->{_async_db}{_cache}->clear if $schema2->{_async_db}{_cache};

    # Same primary key (id => 1) in both databases, but different data,
    # e.g. two tenants, each with their own database, whose row 1 belongs
    # to a different person.
    $schema1->await($schema1->resultset('User')->create({
        name   => 'db1-user',
        email  => 'db1@example.com',
        age    => 41,
        active => 1,
    }));
    $schema2->await($schema2->resultset('User')->create({
        name   => 'db2-user',
        email  => 'db2@example.com',
        age    => 42,
        active => 1,
    }));

    # Populate schema1's cache for id => 1.
    my $r1 = $schema1->await(
        $schema1->resultset('User')
                ->search({ id => 1 })
                ->all
    );
    is($r1->[0]->name, 'db1-user', "schema1's own row is returned");

    # schema2 queries the identical condition against a completely
    # different database connection. Before the fix, both connections'
    # caches were backed by one process-global CHI::Driver::Memory
    # datastore, so this could incorrectly return schema1's cached row.
    my $r2 = $schema2->await(
        $schema2->resultset('User')
                ->search({ id => 1 })
                ->all
    );
    is($r2->[0]->name, 'db2-user',
        "schema2 sees its own database's row, not schema1's cached row");

    $schema1->disconnect;
    $schema2->disconnect;
};

done_testing;
