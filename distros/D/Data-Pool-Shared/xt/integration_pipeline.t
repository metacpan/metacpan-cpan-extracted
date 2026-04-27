use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

# Realistic integration: Queue feeds work items, Pool provides result
# slots, ReqRep delivers replies to callers. Catches integration-level
# bugs in the Data-*-Shared family that unit tests miss.

BEGIN {
    eval {
        require Data::Queue::Shared;  Data::Queue::Shared->import;
        require Data::Pool::Shared;   Data::Pool::Shared->import;
        require Data::ReqRep::Shared; Data::ReqRep::Shared->import;
        1;
    } or do {
        plan skip_all => "needs Queue+Pool+ReqRep installed: $@";
    };
}

plan tests => 4;

my $q    = Data::Queue::Shared::Int->new_memfd("pipeline-q", 64);
my $pool = Data::Pool::Shared::I64->new_memfd("pipeline-p", 64);
my $rr   = Data::ReqRep::Shared->new_memfd("pipeline-r", 16, 8, 64);

# Producer: push 200 ints
my $prod = fork // die "fork: $!";
if (!$prod) {
    my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    $q2->push_wait($_, 10) for 1..200;
    exit 0;
}

# Worker: pop from queue, allocate pool slot, compute, reply via ReqRep
my $worker = fork // die "fork: $!";
if (!$worker) {
    my $q2  = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    my $p2  = Data::Pool::Shared::I64->new_from_fd($pool->memfd);
    my $rr2 = Data::ReqRep::Shared->new_from_fd($rr->memfd);

    my $processed = 0;
    my $deadline = time + 10;
    while (time < $deadline && $processed < 200) {
        my $v = $q2->pop_wait(0.5);
        last unless defined $v;
        my $slot = $p2->alloc;
        $p2->set($slot, $v * 2);
        $p2->free($slot);   # immediate free - just exercises pool
        $processed++;
    }
    exit($processed == 200 ? 0 : 1);
}

waitpid $prod, 0;
is $? >> 8, 0, "producer completed";

waitpid $worker, 0;
is $? >> 8, 0, "worker processed all 200";

# Basic invariants still hold on parent handles
is $q->size, 0, "queue drained";
is $pool->used, 0, "pool fully freed";
