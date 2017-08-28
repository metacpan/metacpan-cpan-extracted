#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use constant PLAN   => 129;
use Test::More;
use Encode qw(decode encode);
use feature 'state';

sub tube_name() {
    state $no = 1;
    sprintf 'test_tube_%02X', $no++;
}


BEGIN {
    unless (eval 'require DR::Tnt') {
        plan skip_all => 'DR::Tnt is not installed';
    }
    plan tests    => PLAN;
    use_ok 'DR::TarantoolQueue';
    use_ok 'DR::Tnt::Test';
    tarantool_version_check(1.6);
}


my $t = start_tarantool
    -port   => free_port,
    -lua    => 't/020-tnt-msgpack/lua/queue.lua',
;

diag $t->log unless ok $t->is_started, 'Queue was started';

for my $coro (0, 1) {
    my $q = DR::TarantoolQueue->new(
        host        => '127.0.0.1',
        port        => $t->port,
        user        => 'test',
        password    => 'test',
        msgpack     => 1,
        coro        => $coro,

        tube        => 'test_tube',

        ttl         => 60,

        defaults    => {
            test_tube   => {
                ttl         => 80
            }
        },
        fake_in_test    => 0,
    );

    ok $q->tnt->ping, 'ping';

    for my $tube (tube_name) {
        note 'normal task';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';
    }

    for my $tube (tube_name) {
        note 'delayed task';
        my $task = $q->put(tube => $tube, data => 'world', delay => 15);
        ok $task => 'Task was put';
        is $task->status, 'delayed', 'status';
    }

    for my $tube (tube_name) {
        note 'domain';
        my $task = $q->put(tube => $tube, domain => 'Vasya');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';
        is $task->domain, 'Vasya', 'domain';

        my $wait = $q->put(tube => $tube, domain => 'Vasya');
        ok $wait => 'Task 2 was put';
        is $wait->status, 'wait', 'status is wait';
        is $wait->domain, 'Vasya', 'domain';
    }

    for my $tube (tube_name) {
        note 'take no timeout';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';

        my $taken = $q->take(tube => $tube);
        ok $taken => 'Task was taken';
        is $taken->id, $task->id, 'id';
        is $taken->status, 'work', 'status';
    }

    for my $tube (tube_name) {
        note 'take timeout and peek';
        
        my $task = $q->put(tube => $tube, data => 'Hello', delay => 5);
        ok $task => 'Task was put';
        is $task->status, 'delayed', 'status';

        my $taken = $q->take(tube => $tube, timeout => .1);
        is $taken => undef, 'Task was taken';

        my $peek = $q->peek(id => $task->id);
        ok $peek, 'Task was peeked';
        is_deeply $peek, $task, 'peeked and put tasks are the same'; 
    }

    for my $tube (tube_name) {
        note 'Ack';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';

        my $taken = $q->take(tube => $tube);
        ok $taken => 'Task was taken';
        is $taken->id, $task->id, 'id';
        is $taken->status, 'work', 'status';
        isnt $q->peek(id => $taken->id), undef, 'task in database';

        ok $taken->ack, 'task was acked';
        is $q->peek(id => $taken->id), undef, 'task was removed';
    }

    for my $tube (tube_name) {
        note 'Release NOW';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';

        my $taken = $q->take(tube => $tube);
        ok $taken => 'Task was taken';
        is $taken->id, $task->id, 'id';
        is $taken->status, 'work', 'status';
        isnt $q->peek(id => $taken->id), undef, 'task in database';

        ok $taken->release, 'task was released';
        is $taken->status, 'ready', 'status';
        isnt $q->peek(id => $taken->id), undef, 'task was NOT removed';
        is $q->peek(id => $taken->id)->status, 'ready', 'status';
    }

    for my $tube (tube_name) {
        note 'Release and delay';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';

        my $taken = $q->take(tube => $tube);
        ok $taken => 'Task was taken';
        is $taken->id, $task->id, 'id';
        is $taken->status, 'work', 'status';
        isnt $q->peek(id => $taken->id), undef, 'task in database';

        ok $taken->release(delay => 123), 'task was released';
        isnt $q->peek(id => $taken->id), undef, 'task was NOT removed';
        is $q->peek(id => $taken->id)->status, 'delayed', 'status';
    }

    for my $tube (tube_name) {
        note 'Bury/dig/delete';
        my $task = $q->put(tube => $tube, data => 'Hello');
        ok $task => 'Task was put';
        is $task->status, 'ready', 'status';

        my $taken = $q->take(tube => $tube);
        ok $taken => 'Task was taken';
        is $taken->id, $task->id, 'id';
        is $taken->status, 'work', 'status';
        isnt $q->peek(id => $taken->id), undef, 'task in database';

        ok $taken->bury(comment => 'Hello'), 'task was buried';
        isnt $q->peek(id => $taken->id), undef, 'task was NOT removed';
        is $q->peek(id => $taken->id)->status, 'buried', 'status';

        my $dig = $q->dig(id => $taken->id);
        ok $dig, 'task was unburied';
        is $dig->status, 'ready', 'status';

        ok $dig->delete, 'task was removed';
        is $q->peek(id => $dig->id), undef, 'was removed really';
    }

    note 'stats';
    is_deeply $q->statistics(tube => 'unknown'), {}, 'unknown tube statistics';
    is_deeply $q->statistics(tube => 'test_tube_01'),
        { test_tube_01 => { ready => 1 } },
        'first test tube';


}

