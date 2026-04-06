#!/usr/bin/env perl
# Cross-process contention benchmark: concurrent producers + consumers
# Measures throughput under lock pressure with bounded queue capacity
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

eval "use MCE::Queue";
my $has_mce = !$@;

my $n         = shift || 200_000;
my $producers = shift || 2;
my $consumers = shift || 2;
my $qcap      = shift || 1024;     # small capacity = high contention

sub rate_fmt {
    my ($label, $elapsed, $count) = @_;
    my $rate = $count / $elapsed;
    if ($rate >= 1_000_000) { return sprintf "%-42s %7.1fM/s  (%.3fs)", $label, $rate / 1_000_000, $elapsed }
    if ($rate >= 1_000)     { return sprintf "%-42s %7.0fK/s  (%.3fs)", $label, $rate / 1_000, $elapsed }
    return sprintf "%-42s %7.0f/s  (%.3fs)", $label, $rate, $elapsed;
}

my $per_producer = int($n / $producers);
my $total = $per_producer * $producers;

printf "Contention benchmark: %d items, %d producers, %d consumers, queue cap=%d\n",
    $total, $producers, $consumers, $qcap;
print "=" x 70, "\n\n";

# ----------------------------------------------------------------
# Data::Queue::Shared::Int (lock-free Vyukov)
# ----------------------------------------------------------------
{
    my $q = Data::Queue::Shared::Int->new(undef, $qcap);
    my $t0 = time;

    # Fork producers
    my @prod_pids;
    for (1..$producers) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for my $i (1..$per_producer) {
                until ($q->push($i)) {}  # spin on full
            }
            POSIX::_exit(0);
        }
        push @prod_pids, $pid;
    }

    # Fork consumers (except last one runs in parent)
    my @cons_pids;
    my $per_consumer = int($total / $consumers);
    for my $c (1..$consumers - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $got = 0;
            while ($got < $per_consumer) {
                $got++ if defined $q->pop;
            }
            POSIX::_exit(0);
        }
        push @cons_pids, $pid;
    }

    # Parent consumes the remainder
    my $parent_share = $total - $per_consumer * ($consumers - 1);
    my $got = 0;
    while ($got < $parent_share) {
        $got++ if defined $q->pop;
    }

    waitpid($_, 0) for @prod_pids, @cons_pids;
    print rate_fmt("Shared::Int (lock-free)", time - $t0, $total), "\n";
}

# ----------------------------------------------------------------
# Data::Queue::Shared::Int with push_wait/pop_wait (futex blocking)
# ----------------------------------------------------------------
{
    my $q = Data::Queue::Shared::Int->new(undef, $qcap);
    my $t0 = time;

    my @prod_pids;
    for (1..$producers) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->push_wait($_, 10) for 1..$per_producer;
            POSIX::_exit(0);
        }
        push @prod_pids, $pid;
    }

    my @cons_pids;
    my $per_consumer = int($total / $consumers);
    for my $c (1..$consumers - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->pop_wait(10) for 1..$per_consumer;
            POSIX::_exit(0);
        }
        push @cons_pids, $pid;
    }

    my $parent_share = $total - $per_consumer * ($consumers - 1);
    $q->pop_wait(10) for 1..$parent_share;

    waitpid($_, 0) for @prod_pids, @cons_pids;
    print rate_fmt("Shared::Int (futex blocking)", time - $t0, $total), "\n";
}

# ----------------------------------------------------------------
# Data::Queue::Shared::Str (mutex, ~50B strings)
# ----------------------------------------------------------------
{
    my $msg = "x" x 50;
    my $q = Data::Queue::Shared::Str->new(undef, $qcap);
    my $t0 = time;

    my @prod_pids;
    for (1..$producers) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            for (1..$per_producer) {
                until ($q->push($msg)) {}
            }
            POSIX::_exit(0);
        }
        push @prod_pids, $pid;
    }

    my @cons_pids;
    my $per_consumer = int($total / $consumers);
    for my $c (1..$consumers - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $got = 0;
            while ($got < $per_consumer) {
                $got++ if defined $q->pop;
            }
            POSIX::_exit(0);
        }
        push @cons_pids, $pid;
    }

    my $parent_share = $total - $per_consumer * ($consumers - 1);
    my $got = 0;
    while ($got < $parent_share) {
        $got++ if defined $q->pop;
    }

    waitpid($_, 0) for @prod_pids, @cons_pids;
    print rate_fmt("Shared::Str (mutex, 50B)", time - $t0, $total), "\n";
}

# ----------------------------------------------------------------
# Data::Queue::Shared::Str with push_wait/pop_wait
# ----------------------------------------------------------------
{
    my $msg = "x" x 50;
    my $q = Data::Queue::Shared::Str->new(undef, $qcap);
    my $t0 = time;

    my @prod_pids;
    for (1..$producers) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->push_wait($msg, 10) for 1..$per_producer;
            POSIX::_exit(0);
        }
        push @prod_pids, $pid;
    }

    my @cons_pids;
    my $per_consumer = int($total / $consumers);
    for my $c (1..$consumers - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->pop_wait(10) for 1..$per_consumer;
            POSIX::_exit(0);
        }
        push @cons_pids, $pid;
    }

    my $parent_share = $total - $per_consumer * ($consumers - 1);
    $q->pop_wait(10) for 1..$parent_share;

    waitpid($_, 0) for @prod_pids, @cons_pids;
    print rate_fmt("Shared::Str (futex blocking, 50B)", time - $t0, $total), "\n";
}

# ----------------------------------------------------------------
# MCE::Queue (concurrent produce+consume via MCE task groups)
# ----------------------------------------------------------------
if ($has_mce) {
    require MCE;

    # MCE::Step runs task groups concurrently with transparent queue plumbing.
    # task_end + $q->end() is the documented pattern for producer/consumer.
    # MCE::Queue uses socket IPC routed through the manager process.
    # True concurrent MPMC (N producers + N consumers) is not a supported
    # MCE pattern — it's designed for workers→manager or pipeline flows.
    # See bench/vs.pl for MCE single-process and produce→drain comparisons.
    print "  (MCE::Queue: no concurrent MPMC — see bench/vs.pl)\n";
}

# ----------------------------------------------------------------
# Scaling: vary producer/consumer counts
# ----------------------------------------------------------------
print "\n";
print "--- Scaling: Int lock-free, push_wait/pop_wait, cap=$qcap ---\n\n";

for my $config ([1,1], [2,1], [1,2], [2,2], [4,1], [1,4], [4,4]) {
    my ($np, $nc) = @$config;
    my $pp = int($n / $np);
    my $tot = $pp * $np;
    my $pc = int($tot / $nc);

    my $q = Data::Queue::Shared::Int->new(undef, $qcap);
    my $t0 = time;

    my @pids;
    for (1..$np) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->push_wait($_, 10) for 1..$pp;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }

    for my $c (1..$nc - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            $q->pop_wait(10) for 1..$pc;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }

    my $parent_share = $tot - $pc * ($nc - 1);
    $q->pop_wait(10) for 1..$parent_share;

    waitpid($_, 0) for @pids;
    print rate_fmt(sprintf("  %dP x %dC", $np, $nc), time - $t0, $tot), "\n";
}
