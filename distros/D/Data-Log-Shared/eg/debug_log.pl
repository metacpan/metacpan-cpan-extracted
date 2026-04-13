#!/usr/bin/env perl
# Cross-process debug log: workers append, monitor reads in real-time
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Log::Shared;
$| = 1;

my $nworkers = shift || 3;
my $log = Data::Log::Shared->new(undef, 500_000);

# workers: do "work" and log debug messages
my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        for my $step (qw(init connect query process done)) {
            $log->append(sprintf "[%d] w%d %s %.3f", $$, $w, $step, time);
            sleep(0.02 + rand(0.05));
        }
        _exit(0);
    }
    push @pids, $pid;
}

# monitor: tail the log as entries arrive
my $seen = 0;
my $pos = 0;
my $expected = $nworkers * 5;
while ($seen < $expected) {
    $log->wait_for($seen, 0.5);
    while (my ($data, $next) = $log->read_entry($pos)) {
        printf "  %s\n", $data;
        $pos = $next;
        $seen++;
    }
}
waitpid($_, 0) for @pids;
printf "\n%d log entries from %d workers\n", $seen, $nworkers;
