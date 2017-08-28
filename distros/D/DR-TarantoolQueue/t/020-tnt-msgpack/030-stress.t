#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use constant PLAN   => 37;
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
    use_ok 'DR::TarantoolQueue::Worker';
    use_ok 'Coro';
    use_ok 'Coro::Channel';
    use_ok 'Coro::AnyEvent';
    tarantool_version_check(1.6);
}


my $t = start_tarantool
    -port   => free_port,
    -lua    => 't/020-tnt-msgpack/lua/queue.lua',
;

diag $t->log unless ok $t->is_started, 'Queue was started';


my @workers;
my %res;
my $ch = Coro::Channel->new;
my $cht = Coro::Channel->new;

for my $i (0 .. 99) {
    my $q = DR::TarantoolQueue->new(
        host        => '127.0.0.1',
        port        => $t->port,
        user        => 'test',
        password    => 'test',
        msgpack     => 1,
        coro        => 1,

        tube        => 'test_tube',

        ttl         => 60,

        defaults    => {
            test_tube   => {
                ttl         => 80
            }
        },

        fake_in_test    => 0,
    );

    $q->tnt->ping;


    
    push @workers => DR::TarantoolQueue::Worker->new(
        queue   => $q,
        timeout => rand 15,
    );


    async {
        $workers[$i]->run(sub {
            my ($task) = @_;
            my $no = $task->data->[0];
            $res{ $no }++;
            return $task->release(delay => rand 0.02) if 20 > rand 100;
            $task->ack;
            $cht->put($no);
        });
    };
}

use constant BLOCK => 1000;
for (1 .. 10){
    my $started = AnyEvent::now();
    for (1 .. BLOCK) {
        async {
            my ($no) = @_;
            my $q = $workers[ int rand @workers ];
            $q->queue->[0]->put(data => [ $no ]);
        } $_;
    }

    my $done = 0;
    while ($cht->get) {
        next unless ++$done >= BLOCK;
        last;
    }

    my $time = AnyEvent::now() - $started;

    is scalar(keys %res), BLOCK, 'count of tasks';
    
    my $rs = 0;
    $rs += $_ for values %res;

    cmp_ok $rs, '>', BLOCK, 'some tasks was processed more than one times';

    cmp_ok $rs / $time, '>=', 200, sprintf 'RPS more than 200 (%3.2f)',
        $rs / $time;

    %res = ();
};
