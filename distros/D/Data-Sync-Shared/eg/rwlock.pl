#!/usr/bin/env perl
# Shared RWLock protecting a file resource
#
# Multiple readers can read concurrently, but writes are exclusive.
# Demonstrates cross-process reader-writer coordination.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use File::Temp qw(tmpnam);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nreaders = 4;
my $nwriters = 2;
my $ops_per  = 50;

my $rw = Data::Sync::Shared::RWLock->new(undef);

# Shared file as the "protected resource"
my $datafile = tmpnam();
open my $fh, '>', $datafile or die "open: $!";
print $fh "0\n";
close $fh;

my @pids;
my $t0 = time;

# Writers: increment the counter
for my $w (1..$nwriters) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..$ops_per) {
            $rw->wrlock;
            open my $in, '<', $datafile or die;
            my $val = <$in>; chomp $val;
            close $in;
            open my $out, '>', $datafile or die;
            print $out $val + 1, "\n";
            close $out;
            $rw->wrunlock;
            usleep(50);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Readers: read the counter
for my $r (1..$nreaders) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $max_seen = 0;
        for (1..$ops_per) {
            $rw->rdlock;
            open my $in, '<', $datafile or die;
            my $val = <$in>; chomp $val;
            close $in;
            $max_seen = $val if $val > $max_seen;
            $rw->rdunlock;
            usleep(20);
        }
        printf "  reader %d: max seen = %d\n", $r, $max_seen;
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

open my $in, '<', $datafile;
my $final = <$in>; chomp $final;
close $in;
unlink $datafile;

printf "final counter: %d (expected %d)\n",
    $final, $nwriters * $ops_per;
printf "elapsed: %.3fs\n", time - $t0;

my $s = $rw->stats;
printf "acquires: %d, releases: %d, recoveries: %d\n",
    $s->{acquires}, $s->{releases}, $s->{recoveries};
