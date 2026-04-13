#!/usr/bin/env perl
# Truncation: discard old entries while writers keep appending
#
# Pattern: writer appends continuously, reader periodically truncates
# entries it has already processed. Demonstrates that truncation is
# concurrency-safe (lock-free CAS) but does NOT reclaim space.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new(undef, 100_000);

# writer: append entries continuously
my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..200) {
        $log->append(sprintf "event %d at %.3f", $i, time);
        sleep 0.005;
    }
    _exit(0);
}

# reader: process entries, truncate what we've consumed
my $pos = 0;
my $processed = 0;
my $truncated_count = 0;

for (1..10) {
    sleep 0.1;

    # read new entries
    while (my ($data, $next) = $log->read_entry($pos)) {
        $processed++;
        $pos = $next;
    }

    # truncate everything we've processed
    if ($pos > $log->truncation) {
        $log->truncate($pos);
        $truncated_count++;
    }

    printf "  processed=%3d truncation=%5d tail=%5d available=%5d\n",
        $processed, $log->truncation, $log->tail_offset, $log->available;
}

waitpid($pid, 0);

# drain remaining
while (my ($data, $next) = $log->read_entry($pos)) {
    $processed++;
    $pos = $next;
}
$log->truncate($pos);

printf "\nfinal:\n";
printf "  processed:  %d entries\n", $processed;
printf "  truncation: %d (readers see nothing before this)\n", $log->truncation;
printf "  tail:       %d (append cursor)\n", $log->tail_offset;
printf "  available:  %d bytes (NOT reclaimed by truncate)\n", $log->available;
printf "  entry_count:%d (includes truncated)\n", $log->entry_count;

# verify: each_entry from 0 returns nothing (all truncated)
my @remaining;
$log->each_entry(sub { push @remaining, $_[0] }, 0);
printf "  readable:   %d entries (after full truncation)\n", scalar @remaining;
