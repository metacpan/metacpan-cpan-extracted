use strict;
use warnings;
use Config;

BEGIN {
    unless ($Config{useithreads}) {
        require Test::More;
        Test::More::plan(skip_all => 'needs a threaded perl');
    }
}

use threads;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;

# Threads of one process share a pid, so the write lock's own-pid recovery must
# never take one thread's live hold for a dead writer's, and CLONE_SKIP must keep
# a handle from being cloned into a new thread (each thread opens its own).  Real
# contention on one map exercises the whole stack -- ithreads, CLONE_SKIP, a
# handle per thread, the write lock: every concurrent write lands and no recovery
# fires.  Holding the lock across a long section to widen the theft window (which
# a tied argument's FETCH used to do, before 0.21 moved argument evaluation out of
# the locked section) is reproduced deterministically in C by xt/wrlock_threads.t.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/thr.shm";

# CLONE_SKIP neuters a handle held when a thread starts: inside the thread it is
# an unblessed scalar ref, not the live handle, so the raw pointer is never
# double-freed on thread exit.
my $parent = Data::HashMap::Shared::II->new($path, 200_000);
my $neutered = threads->create(sub {
    ref($parent) eq 'Data::HashMap::Shared::II' ? 0 : 1
})->join;
is $neutered, 1, 'CLONE_SKIP: a parent handle is not a live handle inside a thread';

my $NT  = 4;
my $PER = 25_000;
my @thr = map {
    my $base = $_ * $PER;
    threads->create(sub {
        my $m = Data::HashMap::Shared::II->new($path, 200_000);
        $m->put($base + $_, $base + $_) for 1 .. $PER;
        1;
    });
} 0 .. $NT - 1;
$_->join for @thr;

my $m = Data::HashMap::Shared::II->new($path, 200_000);
is $m->size, $NT * $PER, 'every concurrent write from all threads landed';

my $missing = 0;
for my $t (0 .. $NT - 1) {
    my $base = $t * $PER;
    for (1 .. $PER) { $missing++ unless ($m->get($base + $_) // -1) == $base + $_ }
}
is $missing, 0, '  ... and every key reads back its own value';
is $m->stats->{recoveries}, 0, "no thread took another's live lock for a dead writer";

done_testing;
