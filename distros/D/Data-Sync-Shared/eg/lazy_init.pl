#!/usr/bin/env perl
# Lazy shared initialization with Once + file-backed cache
#
# First process computes an expensive result and writes it to a
# shared file. All other processes wait for the init, then read
# the cached result. The Once gate ensures exactly one computation.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use File::Temp qw(tmpnam);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 6;
my $cache_file = tmpnam();

my $once = Data::Sync::Shared::Once->new(undef);

sub expensive_computation {
    usleep(200_000);  # simulate 200ms of work
    return "result=" . int(rand(10000));
}

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        if ($once->enter) {
            printf "  worker %d: computing...\n", $w;
            my $result = expensive_computation();
            open my $fh, '>', $cache_file or die;
            print $fh $result;
            close $fh;
            $once->done;
            printf "  worker %d: initialized cache (%s)\n", $w, $result;
        } else {
            printf "  worker %d: waited for init\n", $w;
        }

        open my $fh, '<', $cache_file or die;
        my $data = <$fh>;
        close $fh;
        printf "  worker %d: read '%s'\n", $w, $data;
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
unlink $cache_file;

printf "\nlazy init: %d workers, %.3fs total\n", $nworkers, time - $t0;
printf "  (only 1 computed, rest waited ~0ms after init)\n";
