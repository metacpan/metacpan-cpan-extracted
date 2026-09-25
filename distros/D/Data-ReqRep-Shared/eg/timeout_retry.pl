#!/usr/bin/env perl
# Timeout and retry with worker pool.
# The slow worker still runs the attempt that timed out (only its reply is
# refused), so retry this way only work that is safe to run twice.
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
$| = 1;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 64, 4096);

# 2 fast workers + 1 slow worker
my @workers;
for my $w (1..3) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($req, $id) = $srv->recv_wait(5.0)) {
            if ($w == 3) {
                select(undef, undef, undef, 0.2);
            }
            $srv->reply($id, "w$w:$req");
        }
        exit 0;
    }
    push @workers, $pid;
}

my $cli = Data::ReqRep::Shared::Client->new($path);

for my $i (1..12) {
    my $resp;
    for my $attempt (1..3) {
        $resp = $cli->req_wait("job$i", 0.05);
        if (defined $resp) {
            printf "job%-2d attempt %d -> %s\n", $i, $attempt, $resp;
            last;
        }
        printf "job%-2d attempt %d -> timeout\n", $i, $attempt;
    }
    printf "job%-2d gave up\n", $i unless defined $resp;
}

waitpid($_, 0) for @workers;
$srv->unlink;
