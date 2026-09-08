use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();
use Time::HiRes qw(time);

use Data::HashMap::Shared::SS;

# set_multi runs its whole batch under one write lock and one seqlock section.
# The lock excludes other writers, but get() is lock-free and protected only by
# the seqlock: a reader that passes the check at the wrong moment can see the
# interim inline-empty state, a length from one generation with an offset from
# another, or a retired block whose head is now a free-list link.  Both halves
# read those values back and accept nothing but the two a writer stored.
#
# Two guard defects, two geometries:
#   1. the begin/end pair dropped -- seq never moves, so any concurrent get()
#      is unprotected.  Two writers over many keys.
#   2. the cleanup unlocking before closing the seqlock -- the next writer wins
#      the lock and makes seq even in its own section while the previous writer
#      is still inside wrunlock's FUTEX_WAKE.  That window is one syscall wide
#      and opens only with a waiter parked, so it needs enough writers to keep
#      hdr->rwait above zero: few keys, many writers.  Four writers over eight
#      keys measured zero.

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
plan skip_all => 'needs 2+ CPUs to observe a torn read' if ncpu() == 1;

my $dir = tempdir(CLEANUP => 1);

# Race $writers processes rewriting @$keys through set_multi against lock-free
# get() in this process.  Returns (reads, absent, torn, \%sample, map, cap0,
# crashed writers, writers that exited non-zero, keys seen in both generations).
sub race {
    my (%o) = @_;
    my ($path, $keys, $vals, $writers, $batch, $secs) =
        @o{qw(path keys vals writers batch secs)};

    my $map = Data::HashMap::Shared::SS->new($path, 4096);
    $map->put($_, $vals->($_)->[0]) for @$keys;   # every key present before the race
    my $cap0 = $map->capacity;

    pipe(my $rd, my $wr) or die "pipe: $!";
    my @pids;
    for my $w (1 .. $writers) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            close $wr;
            $SIG{ALRM} = 'DEFAULT';               # XS never returns to run a Perl handler
            alarm 30;
            my $m = Data::HashMap::Shared::SS->new($path, 4096);
            my $go;
            sysread($rd, $go, 1);                 # barrier
            my $end  = time + $secs;
            my $flip = $w;
            while (time < $end) {
                for (my $i = 0; $i < @$keys; $i += $batch) {
                    my $last = $i + $batch - 1;
                    $last = $#$keys if $last > $#$keys;
                    my $v = $flip & 1;
                    $m->set_multi(map { ($_ => $vals->($_)->[$v]) } @{$keys}[$i .. $last]);
                }
                $flip++;
            }
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    close $rd;

    local $SIG{ALRM} = sub { kill 'KILL', @pids; die "torn-read probe exceeded its time budget\n" };
    alarm 120;
    syswrite($wr, 'g' x @pids) == @pids or die "barrier release: $!";
    close $wr;

    my ($reads, $absent, $torn) = (0, 0, 0);
    my (%sample, %gen);
    my $end = time + $secs - 0.3;
    OUTER: while (time < $end) {
        for my $k (@$keys) {
            my $v = $map->get($k);
            $reads++;
            if (!defined $v) { $absent++; next }
            my $pair = $vals->($k);
            if    ($v eq $pair->[0]) { $gen{$k}{0} = 1; next }
            elsif ($v eq $pair->[1]) { $gen{$k}{1} = 1; next }
            $torn++;
            $sample{$k} //= sprintf 'len %d: %s', length($v), unpack 'H*', substr $v, 0, 12;
            last OUTER if $torn >= 20;            # fail fast; the count is not the point
        }
    }
    alarm 0;
    my ($crashed, $failed) = (0, 0);
    for my $pid (@pids) {
        waitpid $pid, 0;
        if    ($? & 127) { $crashed++ }
        elsif ($? >> 8)  { $failed++ }
    }

    my $both = grep { $gen{$_}{0} && $gen{$_}{1} } @$keys;
    return ($reads, $absent, $torn, \%sample, $map, $cap0, $crashed, $failed, $both);
}

# ---- 1. the seqlock pair dropped from the guard ----
{
    my @keys = map { "k$_" } 0 .. 63;
    # 200 and 250 bytes both round up to the 256 class, so the two values
    # recycle one arena block; the differing lengths also expose a val_len
    # paired with the other generation's val_off.
    my $vals = sub {
        my $k = shift;
        ["A:$k:" . ('a' x (200 - length "A:$k:")),
         "B:$k:" . ('b' x (250 - length "B:$k:"))];
    };
    my ($reads, $absent, $torn, $sample, $map, $cap0, $crashed, $failed, $both) = race(
        path => "$dir/pair.shm", keys => \@keys, vals => $vals,
        writers => 2, batch => 8, secs => 1.8);

    is $crashed, 0, "two writers: no writer died on a signal";
    is $failed,  0, "two writers: no writer exited with an error";
    # the reader overlapped the writers: not a rate, which valgrind divides by
    # a hundred, but both generations of every key seen among the $reads reads
    is $both, scalar @keys, "two writers: the reader saw both values of every key ($reads get() calls)";
    is $absent, 0, "two writers: no key ever read back as absent";
    is $torn,   0, "two writers: every value get() returned was one set_multi stored";
    is $map->capacity, $cap0, "two writers: the table never rehashed, so the guard was the only seqlock section";
    is $map->size, scalar @keys, "two writers: all " . @keys . " keys still present";
    diag "torn $_ => $sample->{$_}" for sort keys %$sample;
}

# ---- 2. the guard's cleanup unlocking before closing the seqlock ----
{
    my @keys = ('k0', 'k1');
    # 12 and 16 bytes are both the 16-byte class.  Two keys and eight writers:
    # the reader must land on the one record the incoming writer is rewriting
    # inside a one-syscall window, so the odds come from key count, and the
    # window itself from keeping a writer parked on hdr->wlock.
    my $vals = sub {
        my $k = shift;
        ["A$k" . ('a' x (12 - length "A$k")),
         "B$k" . ('b' x (16 - length "B$k"))];
    };
    my ($reads, $absent, $torn, $sample, $map, $cap0, $crashed, $failed, $both) = race(
        path => "$dir/order.shm", keys => \@keys, vals => $vals,
        writers => 8, batch => 2, secs => 1.5);

    is $crashed, 0, "eight writers: no writer died on a signal";
    is $failed,  0, "eight writers: no writer exited with an error";
    is $both, scalar @keys, "eight writers: the reader saw both values of every key ($reads get() calls)";
    is $absent, 0, "eight writers: no key ever read back as absent";
    is $torn,   0, "eight writers: every value get() returned was one set_multi stored";
    is $map->size, scalar @keys, "eight writers: both keys still present";
    diag "torn $_ => $sample->{$_}" for sort keys %$sample;
}

done_testing;
