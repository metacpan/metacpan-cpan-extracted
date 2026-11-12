#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use POSIX ();
use Data::Shared;

$| = 1;
my $dir = tempdir(CLEANUP => 1);
my $root = Data::Shared->new($dir);
$root->mount('totals', 'hashmap:ii', undef, 100);
$root->set('/totals/42', 0);
print "coordinator: topology published\n";

my %running;
my @workers;
# A worker must not outlive the coordinator, whose temporary directory goes with it.
END { kill 'TERM', keys %running }

for my $number (1 .. 2) {
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $ok = eval {
            undef $root;
            my $worker = Data::Shared->open($dir);
            $worker->incr('/totals/42') for 1 .. 100;
            print "worker $number: reopened and added 100\n";
            1;
        };
        print STDERR $@ unless $ok;
        # Keep the coordinator's temporary-directory cleanup in its own process.
        POSIX::_exit($ok ? 0 : 1);
    }
    push @workers, $pid;
    $running{$pid} = 1;
}
my $failed = 0;
for my $pid (@workers) {
    waitpid($pid, 0) == $pid or die "waitpid: $!";
    delete $running{$pid};
    $failed++ if $?;
}
die "worker failed\n" if $failed;
my $total = $root->get('/totals/42');
print "coordinator: total=$total\n";
die "lost increments\n" unless $total == 200;
