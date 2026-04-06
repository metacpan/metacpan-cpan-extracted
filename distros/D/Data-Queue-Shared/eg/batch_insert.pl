#!/usr/bin/env perl
# Batch accumulator: pop_wait_multi to collect rows, flush periodically
# (simulates batched database inserts)
use strict;
use warnings;
use POSIX ();
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $q = Data::Queue::Shared::Str->new(undef, 4096);
my $batch_size = 50;
my $flush_timeout = 0.5;  # seconds

# Producer: drip-feed rows at varying rates
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    for my $i (1..200) {
        $q->push("INSERT INTO t VALUES ($i, 'row_$i')");
        # Simulate bursty traffic
        select(undef, undef, undef, 0.001) if $i % 10 == 0;
    }
    $q->push("__FLUSH__");
    POSIX::_exit(0);
}

# Consumer: accumulate batches, flush when full or on timeout
my $total_flushed = 0;
my $batch_count = 0;
while (1) {
    my @rows = $q->pop_wait_multi($batch_size, $flush_timeout);
    last unless @rows;

    # Check for sentinel
    my $done = 0;
    @rows = grep { $_ eq '__FLUSH__' ? ($done = 1, 0) : 1 } @rows;

    if (@rows) {
        $batch_count++;
        $total_flushed += scalar @rows;
        printf "batch %d: %d rows (total: %d)\n", $batch_count, scalar @rows, $total_flushed;
        # Here you'd do: $dbh->do("INSERT INTO t VALUES " . join(',', @rows));
    }

    last if $done;
}

waitpid($pid, 0);
print "done: $total_flushed rows in $batch_count batches\n";
