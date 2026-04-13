use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use IO::Pipe;
use Time::HiRes qw(time);
use Data::Pool::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# child allocates slots, signals parent, then gets killed
my $pool = Data::Pool::Shared::I64->new($path, 20);

# parent allocates some slots first
my @parent_slots;
for (1..3) {
    my $s = $pool->alloc;
    $pool->set($s, 100 + $_);
    push @parent_slots, $s;
}
is $pool->used, 3, 'parent allocated 3 slots';

# child allocates 5 slots and signals readiness via pipe
my $pipe = IO::Pipe->new;
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    $pipe->writer;
    my $c = Data::Pool::Shared::I64->new($path, 20);
    for (1..5) {
        my $s = $c->alloc;
        $c->set($s, 200 + $_);
    }
    print $pipe "ready\n";
    $pipe->close;
    sleep 3600;  # hang until killed
    _exit(0);
}

$pipe->reader;
my $line = <$pipe>;
chomp $line;
is $line, 'ready', 'child signaled readiness';
is $pool->used, 8, '8 slots allocated (3 parent + 5 child)';

# kill child with SIGKILL
kill 9, $pid;
waitpid($pid, 0);
diag "child killed";

is $pool->used, 8, 'used count unchanged after kill';

# recover stale slots
my $t0 = time;
my $recovered = $pool->recover_stale;
my $dt = time - $t0;

is $recovered, 5, 'recovered 5 stale slots';
is $pool->used, 3, '3 parent slots remain';
diag sprintf "recovery took %.4fs", $dt;
ok $dt < 2.0, 'recovery completed within 2 seconds';

# parent slots are intact
for my $i (0..$#parent_slots) {
    is $pool->get($parent_slots[$i]), 100 + $i + 1,
        "parent slot $parent_slots[$i] intact";
}

# stats
my $s = $pool->stats;
ok $s->{recoveries} >= 5, "stats show >= 5 recoveries";
diag sprintf "stats: allocs=%d frees=%d recoveries=%d",
    $s->{allocs}, $s->{frees}, $s->{recoveries};

# new allocations work after recovery
my $new_slot = $pool->alloc;
ok defined $new_slot, 'alloc succeeds after recovery';
$pool->set($new_slot, 999);
is $pool->get($new_slot), 999, 'new slot works';

$pool->free($new_slot);
$pool->free($_) for @parent_slots;
is $pool->used, 0, 'all cleaned up';

done_testing;
