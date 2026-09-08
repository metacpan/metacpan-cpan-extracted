use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::SS;

# set_multi and remove_multi hold one write lock across the whole batch.  A
# guard that took the read lock instead would let two batches run at once, and
# its cleanup still calls wrunlock, so the caller's reader slot keeps the depth
# it took and the next write lock anyone takes drains that slot forever.
#
# Same shape as t/41: barrier-released workers batch-insert disjoint ranges into
# a pre-grown table, then arithmetic an unlocked batch cannot hold (hdr->size is
# a plain ++, the arena a plain bump pointer).  Workers only call set_multi,
# which a read-lock guard never blocks, so the losses stay countable.  The stall
# is probed in a child under a no-handler alarm, where it is a status and not a
# hang, and being deterministic it runs even where the race is skipped.

sub ncpu {
    return $ENV{TEST_NCPU} if $ENV{TEST_NCPU};
    if (open my $fh, '<', '/proc/self/status') {   # usable CPUs, not present ones
        while (<$fh>) {
            next unless /^Cpus_allowed_list:\s*(\S+)/;
            my $n = 0;
            for my $r (split /,/, $1) { $n += $r =~ /^(\d+)-(\d+)$/ ? $2 - $1 + 1 : 1 }
            return $n if $n;
        }
    }
    if (open my $fh, '<', '/proc/cpuinfo') {
        my $c = grep { /^processor\s*:/ } <$fh>;
        return $c if $c;
    }
    return 0;                       # unknown: run anyway
}

my $WORKERS = 8;
my $PER     = 2000;
my $BATCH   = 8;                    # keys per set_multi call
my $TOTAL   = $WORKERS * $PER;

sub val_for { "v:$_[0]:" . ('p' x 24) }   # >7 bytes: forces an arena allocation

my $dir = tempdir(CLEANUP => 1);

SKIP: {
    skip 'needs 2+ CPUs to observe a lost writer lock', 7 if ncpu() == 1;

    my $path = "$dir/setmulti.shm";
    my $map  = Data::HashMap::Shared::SS->new($path, $TOTAL * 4);
    $map->reserve($TOTAL * 2);                # settle table_cap before anyone writes
    my $cap0 = $map->capacity;

    pipe(my $rd, my $wr) or die "pipe: $!";

    my @pids;
    for my $w (0 .. $WORKERS - 1) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            close $wr;
            alarm 15;                        # a wedged worker fails the test, never hangs it
            my $child = Data::HashMap::Shared::SS->new($path, $TOTAL * 4);
            my $go;
            sysread($rd, $go, 1);            # barrier: every worker starts together
            my $stored = 0;
            for (my $i = 0; $i < $PER; $i += $BATCH) {
                $stored += $child->set_multi(
                    map { my $k = "w$w-k$_"; ($k => val_for($k)) } $i .. $i + $BATCH - 1);
            }
            POSIX::_exit($stored == $PER ? 0 : 1);
        }
        push @pids, $pid;
    }
    close $rd;

    local $SIG{ALRM} = sub {
        kill 'KILL', @pids;
        die "concurrent set_multi probe exceeded its time budget\n";
    };
    alarm 60;

    syswrite($wr, 'g' x $WORKERS) == $WORKERS or die "barrier release: $!";
    close $wr;

    my ($crashed, $refused) = (0, 0);
    for my $pid (@pids) {
        waitpid($pid, 0);
        if    ($? & 127) { $crashed++ }
        elsif ($? >> 8)  { $refused++ }
    }
    alarm 0;

    is($crashed, 0, "no worker died on a signal");
    is($refused, 0, "every worker had every pair of its batches stored");

    # Everything below reads the map, and get() is lock-free: a seqlock left
    # odd spins inside XS, where a Perl-level handler would never run.  Default
    # disposition, so a wedge here is a signal death and not a suite stall.
    $SIG{ALRM} = 'DEFAULT';
    alarm 30;

    is($map->capacity, $cap0, "the pre-grown table never rehashed under the race");

    my @live = $map->keys;
    is(scalar @live, $map->size,
       sprintf "the live slot count agrees with size() (%d vs %d)",
               scalar @live, $map->size);
    is($map->size, $TOTAL, "size() is exactly the $TOTAL distinct keys stored");

    my ($missing, $wrong) = (0, 0);
    for my $w (0 .. $WORKERS - 1) {
        for my $i (0 .. $PER - 1) {
            my $k = "w$w-k$i";
            my $v = $map->get($k);
            if    (!defined $v)       { $missing++ }
            elsif ($v ne val_for($k)) { $wrong++ }
        }
    }
    is($missing, 0, "every key stored by a batch is still readable");
    is($wrong,   0, "every value reads back exactly as its batch stored it");
    alarm 0;
}

# t/25's sequence: set_multi, then a write lock in the same process.  A guard
# that leaves the caller's read depth held makes freeze() (and put()) wait on
# that slot forever, and the holder is alive, so recovery cannot break it.
{
    my $path = "$dir/stall.shm";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        $SIG{ALRM} = 'DEFAULT';             # never a Perl-level handler: XS would not return to run it
        alarm 3;                             # milliseconds of work; a stall dies here
        my $m = Data::HashMap::Shared::SS->new($path, 64);
        $m->set_multi(a => val_for('a'), b => val_for('b'));
        $m->put(c => val_for('c'));
        $m->freeze;
        POSIX::_exit($m->frozen && $m->size == 3 && ($m->get('a') // '') eq val_for('a') ? 0 : 1);
    }
    waitpid($pid, 0);
    my $st = $?;
    is($st & 127, 0, "set_multi, then put() and freeze() in the same process, returned within the alarm");
    is($st,       0, "and the frozen map holds all three entries");
}

done_testing;
