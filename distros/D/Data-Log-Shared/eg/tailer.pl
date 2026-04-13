#!/usr/bin/env perl
# Log tailer: writer appends, reader tails in real-time via wait_for
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Log::Shared;
$| = 1;

my $log = Data::Log::Shared->new(undef, 100_000);

# writer: append entries periodically
my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..20) {
        $log->append(sprintf "[%d] event %d at %.3f", $$, $i, time);
        sleep(0.1);
    }
    _exit(0);
}

# tailer: follow new entries in real-time
printf "tailing log (20 events expected)...\n";
my $seen = 0;
my $pos = 0;
my $target = 20;
while ($seen < $target) {
    $log->wait_for($seen, 1.0);
    while (my ($data, $next) = $log->read_entry($pos)) {
        printf "  %s\n", $data;
        $pos = $next;
        $seen++;
    }
}
waitpid($pid, 0);
printf "done: %d entries tailed\n", $seen;
