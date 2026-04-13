#!/usr/bin/env perl
# Once: one-time shared initialization
#
# Multiple processes race to initialize a shared resource.
# Exactly one wins; the rest wait for completion.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use File::Temp qw(tmpnam);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $nworkers = 6;

my $once = Data::Sync::Shared::Once->new(undef);

# Shared file represents the "expensive resource" to initialize
my $resource = tmpnam();

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        if ($once->enter) {
            # I'm the initializer
            printf "  worker %d: initializing resource...\n", $w;
            usleep(100_000);  # simulate expensive init
            open my $fh, '>', $resource or die;
            print $fh "initialized by worker $w at " . time() . "\n";
            close $fh;
            $once->done;
            printf "  worker %d: initialization complete\n", $w;
        } else {
            printf "  worker %d: waited for init, proceeding\n", $w;
        }

        # All workers can now use the resource
        open my $fh, '<', $resource or die "resource not ready: $!";
        my $line = <$fh>;
        close $fh;
        printf "  worker %d reads: %s", $w, $line;
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
unlink $resource;

printf "elapsed: %.3fs, is_done=%d\n", time - $t0, $once->is_done;
