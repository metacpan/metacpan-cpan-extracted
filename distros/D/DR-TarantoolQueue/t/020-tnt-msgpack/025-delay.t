#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use constant PLAN   => 19;
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
    use_ok 'Time::HiRes', 'time';
    tarantool_version_check(1.6);
}


my $t = start_tarantool
    -port   => free_port,
    -lua    => 't/020-tnt-msgpack/lua/queue.lua',
;

diag $t->log unless ok $t->is_started, 'Queue was started';

my $q = DR::TarantoolQueue->new(
    host        => '127.0.0.1',
    port        => $t->port,
    user        => 'test',
    password    => 'test',
    msgpack     => 1,
    coro        => 0,

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

for (+ note 'delay') {
    my $started = time;

    my $delay = $q->put(data => [123], delay => 0.25);
    ok $delay => 'delayed task was put';


    my $taken = $q->take(timeout => 2);
    ok $taken => 'delayed task was taken';
    is $taken->id, $delay->id, 'task.id';

    ok $taken->ack, 'ack task';

    my $time = time - $started;
    cmp_ok $time, '>=', 0.25, 'delay time';
    cmp_ok $time, '<', 0.35, 'delay time';
}

for (+ note 'release delay') {
    my $started = time;
    
    my $delay = $q->put(data => [123]);
    ok $delay => 'task was put';


    my $taken = $q->take(timeout => 2);
    ok $taken => 'delayed task was taken';
    is $taken->id, $delay->id, 'task.id';

    ok $taken->release(delay => 0.25), 'released';
    
    $taken = $q->take(timeout => 2);
    ok $taken => 'delayed task was taken';
    is $taken->id, $delay->id, 'task.id';
    
    my $time = time - $started;
    cmp_ok $time, '>=', 0.25, 'delay time';
    cmp_ok $time, '<', 0.35, 'delay time';
}
