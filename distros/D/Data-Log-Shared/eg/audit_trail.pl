#!/usr/bin/env perl
# Audit trail: multiple workers append events, reader replays
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Log::Shared;
$| = 1;

my $nworkers = shift || 4;
my $events   = shift || 50;

my $log = Data::Log::Shared->new(undef, 1_000_000);

# workers append events concurrently
my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        for my $i (1..$events) {
            $log->append(sprintf "%d|%d|%s|user_%d did action_%d",
                time, $$, "INFO", $w, $i);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

printf "appended %d events from %d workers\n\n", $log->entry_count, $nworkers;

# replay last 5 entries
my @all;
$log->each_entry(sub { push @all, $_[0] });
printf "last 5 entries:\n";
for my $e (@all[-5..-1]) {
    printf "  %s\n", $e;
}

printf "\ntotal: %d entries, %d bytes used of %d\n",
    $log->entry_count, $log->tail_offset, $log->data_size;
