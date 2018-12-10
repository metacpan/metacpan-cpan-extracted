use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Database::Async;

subtest 'no constructor parameters' => sub {
    my $db = new_ok('Database::Async');
    done_testing;
};
subtest 'pool handling' => sub {
    note 'default pool';
    is(exception {
        my $db = new_ok('Database::Async');
        isa_ok($db->pool, 'Database::Async::Pool');
        is($db->pool->min, 0, 'pool min is 0');
        is($db->pool->max, 1, 'pool has 1 connection max by default');
        is($db->pool->count, 0, 'pool starts empty');
        isa_ok($db->pool->backoff, 'Database::Async::Backoff');
    }, undef, 'default pool throws no exceptions');
    note 'override max';
    is(exception {
        my $db = new_ok('Database::Async', [
            pool => { max => 2 }
        ]);
        isa_ok($db->pool, 'Database::Async::Pool');
        is($db->pool->min, 0, 'pool min is still 0');
        is($db->pool->max, 2, 'pool now has 2 connection max');
        is($db->pool->count, 0, 'pool still starts empty');
        isa_ok($db->pool->backoff, 'Database::Async::Backoff');
    }, undef, 'override pool max, throws no exceptions');
    note 'pass instance';
    is(exception {
        my $db = new_ok('Database::Async', [
            pool => Database::Async::Pool->new(max => 3),
        ]);
        isa_ok($db->pool, 'Database::Async::Pool');
        is($db->pool->min, 0, 'pool min is still 0');
        is($db->pool->max, 3, 'pool now has 3 connection max');
        is($db->pool->count, 0, 'pool still starts empty');
        isa_ok($db->pool->backoff, 'Database::Async::Backoff');
    }, undef, 'override pool instance, throws no exceptions');
    done_testing;
};

done_testing;


