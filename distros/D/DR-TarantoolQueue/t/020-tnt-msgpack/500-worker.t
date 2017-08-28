#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use constant PLAN   => 27;
use Test::More;
use Encode qw(decode encode);
use feature 'state';

sub tube_name() {
    state $no = 1;
    $no++;
    sprintf 'test_tube_%02x', $no;
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

use Encode qw(decode encode);
use Cwd 'cwd';
use File::Spec::Functions 'catfile';
#use feature 'state';



BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'DR::TarantoolQueue';
    use_ok 'Coro';
    use_ok 'Time::HiRes', 'time';
    use_ok 'Coro::AnyEvent';
    use_ok 'DR::TarantoolQueue::Worker';
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
    tube        => 'test_queue',
    coro        => 1,
    fake_in_test    => 0,
);

isa_ok $q => 'DR::TarantoolQueue';



my $wrk = DR::TarantoolQueue::Worker->new(
    queue   => $q,
    timeout => .5,
    count   => 10
);

note 'autoack tests';
async {
    $wrk->run(sub {});
};

my @tasks;
for (1 .. 31) {
    push @tasks => $q->put(data => $_);
}

Coro::AnyEvent::sleep 0.2;

for (@tasks) {
    $_ = eval { $q->peek(id => $_->id) };
}
is scalar grep({ !defined($_) } @tasks), scalar @tasks, 'All tasks were ack';

is $wrk->stop, 0, 'workers were stopped';

note 'release tests';
@tasks = ();

async {
    $wrk->run(sub {
        my ($task) = @_;
        ok $task->release(delay => 200), 'task was released ' . $task->id;
    });
};
@tasks = ();

for (1 .. 5) {
    push @tasks => $q->put(data => {task => $_});
}

Coro::AnyEvent::sleep .2;
for (@tasks) {
    is $_->peek->status, 'delayed', 'task was released ' . $_->id;
};

is $wrk->stop, 0, 'workers were stopped';


note 'autobury';
async {
    $wrk->run(sub { die 123 });
};


@tasks = ();
for (1 .. 5) {
    push @tasks => $q->put(data => {task => $_});
}
Coro::AnyEvent::sleep .2;

$wrk->stop;

for (@tasks) {
    is $_->peek->status, 'buried', 'task was buried ' . $_->id;
};


END {
    note $t->log if $ENV{DEBUG};
}
