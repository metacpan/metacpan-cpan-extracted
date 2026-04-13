#!/usr/bin/env perl
# RWLock-protected shared cache file
#
# Readers check the cache frequently, writer updates it periodically.
# Demonstrates high read throughput with occasional exclusive writes.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use File::Temp qw(tmpnam);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $rw = Data::Sync::Shared::RWLock->new(undef);
my $cache = tmpnam();

# Initialize cache
open my $fh, '>', $cache or die;
print $fh "version=0\n";
close $fh;

my @pids;

# Writer: updates cache every 50ms
{
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $v (1..10) {
            usleep(50_000);
            $rw->wrlock;
            open my $fh, '>', $cache or die;
            print $fh "version=$v\n";
            close $fh;
            $rw->wrunlock;
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Readers: read cache as fast as possible
for my $r (1..4) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $reads = 0;
        my $max_ver = 0;
        my $deadline = time + 0.6;
        while (time < $deadline) {
            $rw->rdlock;
            open my $fh, '<', $cache or die;
            my $line = <$fh>;
            close $fh;
            $rw->rdunlock;
            if ($line =~ /version=(\d+)/) {
                $max_ver = $1 if $1 > $max_ver;
            }
            $reads++;
        }
        printf "  reader %d: %d reads, max version=%d\n", $r, $reads, $max_ver;
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
unlink $cache;

my $s = $rw->stats;
printf "acquires: %d, recoveries: %d\n", $s->{acquires}, $s->{recoveries};
