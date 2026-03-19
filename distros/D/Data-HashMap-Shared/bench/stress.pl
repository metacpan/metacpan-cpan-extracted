#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Time::HiRes qw(time);
use File::Temp ();
use Getopt::Long;

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

my $NCPU = eval { chomp(my $n = `nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null`); $n } || 4;

my $workers   = $NCPU;
my $duration  = 5;
my $entries   = 100_000;
my $key_range = 50_000;   # hot key space (smaller = more contention)
my $val_len   = 32;

GetOptions(
    'workers=i'  => \$workers,
    'duration=i' => \$duration,
    'entries=i'  => \$entries,
    'keys=i'     => \$key_range,
    'vallen=i'   => \$val_len,
) or die "Usage: $0 [--workers N] [--duration S] [--entries N] [--keys N] [--vallen N]\n";

sub commify { my $n = reverse $_[0]; $n =~ s/(\d{3})(?=\d)/$1,/g; scalar reverse $n }

my $TMPDIR = File::Temp::tempdir(CLEANUP => 1);
my $seq = 0;
sub tmppath { "$TMPDIR/stress" . $seq++ }

sub run_workers {
    my ($label, $nworkers, $setup, $work) = @_;

    $setup->() if $setup;

    my @pipes;
    my @pids;
    for my $w (0 .. $nworkers - 1) {
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $rd;
            my $ops = $work->($w);
            print $wr "$ops\n";
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        push @pipes, $rd;
        push @pids, $pid;
    }

    my $total_ops = 0;
    for my $i (0 .. $#pids) {
        waitpid($pids[$i], 0);
        my $rd = $pipes[$i];
        my $ops = <$rd>;
        close $rd;
        chomp $ops;
        $total_ops += $ops;
    }
    return $total_ops;
}

sub print_result {
    my ($label, $total_ops, $elapsed, $nworkers) = @_;
    my $ops_sec = $total_ops / $elapsed;
    printf "  %-40s %s ops in %.1fs  (%s ops/sec, %d workers)\n",
        $label, commify($total_ops), $elapsed, commify(int($ops_sec)), $nworkers;
}

print "=" x 78, "\n";
print "Data::HashMap::Shared — Multi-Process Stress Test\n";
print "  CPUs: $NCPU  Workers: $workers  Duration: ${duration}s\n";
print "  Entries: $entries  Key range: $key_range  Val length: $val_len\n";
print "=" x 78, "\n";

# =====================================================================
# Test 1: II — Pure write contention (all writers)
# =====================================================================
print "\n", "-" x 78, "\n";
print "II: Pure write contention ($workers writers)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::II->new($path, $entries);
    my $t0 = time();
    my $total = run_workers("ii_write", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::II->new($path, $entries);
        my $ops = 0;
        my $deadline = time() + $duration;
        while (time() < $deadline) {
            for my $batch (1 .. 1000) {
                my $k = int(rand($key_range));
                shm_ii_put $m, $k, $k + $wid;
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("put (all writers)", $total, $elapsed, $workers);

    # verify integrity
    my $sz = shm_ii_size $map;
    printf "  -> map size: %s (expected <= %s)\n", commify($sz), commify($key_range);
    undef $map; unlink $path;
}

# =====================================================================
# Test 2: II — Mixed read/write (readers >> writers)
# =====================================================================
print "\n", "-" x 78, "\n";
printf "II: Mixed read/write (1 writer, %d readers)\n", $workers - 1;
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::II->new($path, $entries);
    # pre-populate
    shm_ii_put $map, $_, $_ for 1 .. $key_range;

    my $t0 = time();
    my $total = run_workers("ii_mixed", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::II->new($path, $entries);
        my $ops = 0;
        my $deadline = time() + $duration;
        if ($wid == 0) {
            # writer
            while (time() < $deadline) {
                for (1 .. 1000) {
                    my $k = 1 + int(rand($key_range));
                    shm_ii_put $m, $k, $k * 2;
                    $ops++;
                }
            }
        } else {
            # reader
            while (time() < $deadline) {
                for (1 .. 1000) {
                    my $k = 1 + int(rand($key_range));
                    my $v = shm_ii_get $m, $k;
                    $ops++;
                }
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("1 writer + " . ($workers-1) . " readers", $total, $elapsed, $workers);
    undef $map; unlink $path;
}

# =====================================================================
# Test 3: II — Atomic counter contention
# =====================================================================
print "\n", "-" x 78, "\n";
print "II: Atomic counter contention ($workers incrementers)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::II->new($path, $entries);

    my $t0 = time();
    my $total = run_workers("ii_incr", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::II->new($path, $entries);
        my $ops = 0;
        my $deadline = time() + $duration;
        while (time() < $deadline) {
            for (1 .. 1000) {
                my $k = int(rand($key_range));
                shm_ii_incr $m, $k;
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("incr (all writers)", $total, $elapsed, $workers);

    # verify: sum of all values should equal total ops
    my $sum = 0;
    while (my ($k, $v) = shm_ii_each $map) { $sum += $v; }
    printf "  -> total increments: %s  sum of values: %s  %s\n",
        commify($total), commify($sum), ($sum == $total ? "OK" : "MISMATCH!");
    undef $map; unlink $path;
}

# =====================================================================
# Test 4: SS — String read/write contention
# =====================================================================
print "\n", "-" x 78, "\n";
print "SS: String read/write contention ($workers mixed)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::SS->new($path, $entries);
    my $val_template = "x" x $val_len;
    # pre-populate
    for my $i (1 .. $key_range) {
        shm_ss_put $map, "k$i", $val_template . $i;
    }

    my $t0 = time();
    my $total = run_workers("ss_mixed", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::SS->new($path, $entries);
        my $vt = "x" x $val_len;
        my $ops = 0;
        my $deadline = time() + $duration;
        while (time() < $deadline) {
            for (1 .. 1000) {
                my $k = "k" . (1 + int(rand($key_range)));
                if (rand() < 0.3) {
                    shm_ss_put $m, $k, $vt . int(rand(999999));
                } else {
                    my $v = shm_ss_get $m, $k;
                }
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("70% read / 30% write", $total, $elapsed, $workers);
    undef $map; unlink $path;
}

# =====================================================================
# Test 5: SI — Atomic counters with string keys
# =====================================================================
print "\n", "-" x 78, "\n";
print "SI: String-key atomic counters ($workers incrementers)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::SI->new($path, $entries);

    my $t0 = time();
    my $total = run_workers("si_incr", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::SI->new($path, $entries);
        my $ops = 0;
        my $deadline = time() + $duration;
        while (time() < $deadline) {
            for (1 .. 1000) {
                my $k = "counter_" . int(rand($key_range));
                shm_si_incr $m, $k;
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("incr (all writers)", $total, $elapsed, $workers);

    my $sum = 0;
    while (my ($k, $v) = shm_si_each $map) { $sum += $v; }
    printf "  -> total increments: %s  sum of values: %s  %s\n",
        commify($total), commify($sum), ($sum == $total ? "OK" : "MISMATCH!");
    undef $map; unlink $path;
}

# =====================================================================
# Test 6: II — Insert + delete churn (high tombstone pressure)
# =====================================================================
print "\n", "-" x 78, "\n";
print "II: Insert/delete churn ($workers workers, high tombstone pressure)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::II->new($path, $entries);
    shm_ii_put $map, $_, $_ for 1 .. $key_range;

    my $t0 = time();
    my $total = run_workers("ii_churn", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::II->new($path, $entries);
        my $ops = 0;
        my $deadline = time() + $duration;
        while (time() < $deadline) {
            for (1 .. 500) {
                my $k = int(rand($key_range));
                shm_ii_remove $m, $k;
                $ops++;
                shm_ii_put $m, $k, $k + $wid;
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("remove + put pairs", $total, $elapsed, $workers);

    my $sz = shm_ii_size $map;
    my $tb = shm_ii_tombstones $map;
    printf "  -> size: %s  tombstones: %s\n", commify($sz), commify($tb);
    undef $map; unlink $path;
}

# =====================================================================
# Test 7: II — LRU eviction under contention
# =====================================================================
print "\n", "-" x 78, "\n";
print "II: LRU eviction under contention ($workers writers, max_size=$key_range)\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $lru_cap = $key_range;
    my $map = Data::HashMap::Shared::II->new($path, $entries, $lru_cap);

    my $t0 = time();
    my $total = run_workers("ii_lru", $workers, undef, sub {
        my ($wid) = @_;
        my $m = Data::HashMap::Shared::II->new($path, $entries, $lru_cap);
        my $ops = 0;
        my $deadline = time() + $duration;
        my $offset = $wid * $entries;
        my $i = 0;
        while (time() < $deadline) {
            for (1 .. 1000) {
                shm_ii_put $m, $offset + ($i++ % ($key_range * 2)), $wid;
                $ops++;
            }
        }
        return $ops;
    });
    my $elapsed = time() - $t0;
    print_result("put with LRU eviction", $total, $elapsed, $workers);

    my $sz = shm_ii_size $map;
    my $ev = shm_ii_stat_evictions $map;
    printf "  -> size: %s  evictions: %s\n", commify($sz), commify($ev);
    undef $map; unlink $path;
}

# =====================================================================
# Test 8: Scaling — throughput vs worker count
# =====================================================================
print "\n", "-" x 78, "\n";
print "Scaling: II read throughput vs worker count\n";
print "-" x 78, "\n";
{
    my $path = tmppath();
    my $map = Data::HashMap::Shared::II->new($path, $entries);
    shm_ii_put $map, $_, $_ for 1 .. $key_range;

    my $scale_dur = 3;
    for my $nw (1, 2, 4, ($workers > 4 ? $workers : ())) {
        last if $nw > $workers;
        my $t0 = time();
        my $total = run_workers("ii_scale_$nw", $nw, undef, sub {
            my ($wid) = @_;
            my $m = Data::HashMap::Shared::II->new($path, $entries);
            my $ops = 0;
            my $deadline = time() + $scale_dur;
            while (time() < $deadline) {
                for (1 .. 1000) {
                    my $k = 1 + int(rand($key_range));
                    my $v = shm_ii_get $m, $k;
                    $ops++;
                }
            }
            return $ops;
        });
        my $elapsed = time() - $t0;
        my $ops_sec = int($total / $elapsed);
        printf "  %2d workers:  %s ops/sec\n", $nw, commify($ops_sec);
    }
    undef $map; unlink $path;
}

print "\n", "=" x 78, "\n";
print "All stress tests completed.\n";
print "=" x 78, "\n";
