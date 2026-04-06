#!/usr/bin/env perl
# Multi-process throughput benchmark
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $n = shift || 500_000;
my $nprocs = shift || 2;

sub bench_mp {
    my ($label, $q_maker, $push_sub, $pop_sub) = @_;

    my $q = $q_maker->();
    my $t0 = time;

    # Fork producers
    my @pids;
    my $per_proc = int($n / $nprocs);
    for my $p (1..$nprocs) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $pq = $q_maker->();
            $push_sub->($pq, $per_proc);
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }

    # Parent is consumer
    $pop_sub->($q, $per_proc * $nprocs);

    waitpid($_, 0) for @pids;
    my $elapsed = time - $t0;
    my $total = $per_proc * $nprocs;
    printf "  %-40s %8.0f/s  (%.3fs, %d procs)\n", $label, $total / $elapsed, $elapsed, $nprocs;
}

print "Multi-process benchmark, $n items, $nprocs producers:\n\n";

# ---- Int: producers push, parent pops ----
{
    my $path = "/tmp/bench_int_mp_$$.shm";
    END { unlink "/tmp/bench_int_mp_$$.shm" }

    print "Int (lock-free):\n";

    bench_mp "push(producers) + pop(consumer)" =>
        sub { Data::Queue::Shared::Int->new($path, $n * 2) },
        sub { my ($q, $cnt) = @_; $q->push($_) for 1..$cnt },
        sub {
            my ($q, $cnt) = @_;
            my $got = 0;
            while ($got < $cnt) {
                my $v = $q->pop;
                $got++ if defined $v;
            }
        };

    bench_mp "push_wait(producers) + pop_wait(consumer)" =>
        sub { Data::Queue::Shared::Int->new($path, 4096) },
        sub { my ($q, $cnt) = @_; $q->push_wait($_, 5) for 1..$cnt },
        sub {
            my ($q, $cnt) = @_;
            for (1..$cnt) { $q->pop_wait(5) }
        };
}

print "\n";

# ---- Str: producers push, parent pops ----
{
    my $path = "/tmp/bench_str_mp_$$.shm";
    END { unlink "/tmp/bench_str_mp_$$.shm" }
    my $msg = "message_payload_" . ("x" x 50);

    print "Str (mutex, ~66B strings):\n";

    bench_mp "push(producers) + pop(consumer)" =>
        sub { Data::Queue::Shared::Str->new($path, $n * 2, $n * 128) },
        sub { my ($q, $cnt) = @_; $q->push($msg) for 1..$cnt },
        sub {
            my ($q, $cnt) = @_;
            my $got = 0;
            while ($got < $cnt) {
                my $v = $q->pop;
                $got++ if defined $v;
            }
        };

    bench_mp "push_wait(producers) + pop_wait(consumer)" =>
        sub { Data::Queue::Shared::Str->new($path, 4096, 1048576) },
        sub { my ($q, $cnt) = @_; $q->push_wait($msg, 5) for 1..$cnt },
        sub {
            my ($q, $cnt) = @_;
            for (1..$cnt) { $q->pop_wait(5) }
        };
}

print "\n";

# ---- Str: batch under single mutex ----
{
    my $path = "/tmp/bench_batch_mp_$$.shm";
    END { unlink "/tmp/bench_batch_mp_$$.shm" }
    my $msg = "batch_item";
    my $batch = 100;

    print "Str batch ($batch/batch, mutex):\n";

    bench_mp "push_multi(producers) + drain(consumer)" =>
        sub { Data::Queue::Shared::Str->new($path, $n * 2, $n * 64) },
        sub {
            my ($q, $cnt) = @_;
            my @vals = ($msg) x $batch;
            for (1..int($cnt/$batch)) { $q->push_multi(@vals) }
        },
        sub {
            my ($q, $cnt) = @_;
            my $got = 0;
            while ($got < $cnt) {
                my @r = $q->drain($batch);
                $got += scalar @r;
                select(undef, undef, undef, 0.0001) unless @r;
            }
        };
}
