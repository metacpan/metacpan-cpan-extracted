#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Log::Shared;

my $WORKERS = shift || 8;
my $OPS     = shift || 200_000;

printf "Log multi-process: %d workers x %d appends\n\n", $WORKERS, $OPS;

my $log = Data::Log::Shared->new(undef, $WORKERS * $OPS * 30);

my $t0 = time;
my @pids;
for my $w (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            $log->append(sprintf "w=%d i=%d", $w, $_);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $dt = time - $t0;

my $total = $WORKERS * $OPS;
printf "  %-35s %10.0f/s  (%.3fs)\n", "concurrent append", $total / $dt, $dt;
printf "  entries: %d (expected %d)\n", $log->entry_count, $total;

# verify all readable
my $count = 0;
$log->each_entry(sub { $count++ });
printf "  readable: %d\n", $count;
