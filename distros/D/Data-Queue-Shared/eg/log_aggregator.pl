#!/usr/bin/env perl
# Multiple worker processes push log lines, collector drains to file
use strict;
use warnings;
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Queue::Shared;

my $num_workers = 3;
my $lines_per_worker = 100;
my $logfile = '/tmp/aggregated.log';

my $q = Data::Queue::Shared::Str->new(undef, 4096);

# Fork workers that produce log lines
my @pids;
for my $w (1..$num_workers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $i (1..$lines_per_worker) {
            my $ts = time;
            $q->push_wait("[$ts] worker=$w seq=$i doing work\n");
        }
        $q->push_wait("__EOF__");
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

# Collector: drain batches and write to file
open my $fh, '>', $logfile or die "open: $!";
my $total = 0;
my $eofs = 0;
while ($eofs < $num_workers) {
    my @lines = $q->pop_wait_multi(100, 2);
    for my $line (@lines) {
        if ($line eq "__EOF__") {
            $eofs++;
        } else {
            print $fh $line;
            $total++;
        }
    }
}
close $fh;

waitpid($_, 0) for @pids;
print "wrote $total log lines to $logfile\n";
unlink $logfile;
