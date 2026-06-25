#!/usr/bin/env perl
use strict;
use warnings;
use POSIX ();
use Data::HashMap::Shared::IS;   # pid -> status string, with a TTL

# Liveness registry via per-key TTL. Each worker refreshes its heartbeat every
# second; a worker that dies stops refreshing and its entry simply expires, so
# the supervisor sees only live workers with no explicit death notification.

my $path = "/tmp/dhms_heartbeat_$$.shm";
my $TTL  = 2;                                   # a heartbeat is "live" for 2s
my $reg  = Data::HashMap::Shared::IS->new($path, 1000, 0, $TTL);

my @pids;
for my $w (1 .. 3) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $r = Data::HashMap::Shared::IS->new($path, 1000, 0, $TTL);
        my $beats = ($w == 3) ? 2 : 6;          # worker 3 "dies" early
        for (1 .. $beats) {
            shm_is_put $r, $$, "worker$w";      # refresh heartbeat (resets TTL)
            sleep 1;
        }
        POSIX::_exit(0);
    }
    push @pids, $pid;
}

for my $t (1 .. 5) {
    sleep 1;
    $reg->flush_expired;                        # drop heartbeats past their TTL
    my @live = sort { $a <=> $b } $reg->keys;
    printf "t=%ds: %d live worker(s): %s\n", $t, scalar @live,
        join(', ', map { $reg->get($_) // '?' } @live);
}

waitpid $_, 0 for @pids;
$reg->unlink;
