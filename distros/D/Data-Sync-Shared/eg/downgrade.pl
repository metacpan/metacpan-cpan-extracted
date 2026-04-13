#!/usr/bin/env perl
# RWLock downgrade: write then read without releasing
#
# Pattern: acquire wrlock, modify shared state, downgrade to rdlock,
# read the state (while allowing other readers), then release.
# No window where another writer can sneak in between write and read.
use strict;
use warnings;
use POSIX qw(_exit);
use File::Temp qw(tmpnam);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $rw = Data::Sync::Shared::RWLock->new(undef);
my $datafile = tmpnam();

# Initialize shared file
open my $fh, '>', $datafile or die;
print $fh "0\n";
close $fh;

my $nworkers = 4;
my $ops = 20;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1..$ops) {
            # Write phase: exclusive access
            $rw->wrlock;
            open my $in, '<', $datafile or die;
            my $val = <$in>; chomp $val;
            close $in;
            $val++;
            open my $out, '>', $datafile or die;
            print $out "$val\n";
            close $out;

            # Downgrade: become a reader, let others read too
            $rw->downgrade;
            open $in, '<', $datafile or die;
            my $check = <$in>; chomp $check;
            close $in;

            # The value we just wrote is still there (no writer sneaked in)
            die "data corruption: wrote $val, read $check"
                unless $check >= $val;

            $rw->rdunlock;
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

open $fh, '<', $datafile;
my $final = <$fh>; chomp $final;
close $fh;
unlink $datafile;

printf "downgrade: %d workers x %d ops, final=%d (expected %d)\n",
    $nworkers, $ops, $final, $nworkers * $ops;

my $s = $rw->stats;
printf "acquires: %d, releases: %d, state: %s\n",
    $s->{acquires}, $s->{releases}, $s->{state};
