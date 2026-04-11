#!/usr/bin/env perl
# Batch server: recv_multi for throughput, pipelined client
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
use Time::HiRes qw(time);

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 1024, 128, 4096);

my $TOTAL = 10_000;
my $BATCH = 100;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Server: batch recv + batch reply
    my $processed = 0;
    while ($processed < $TOTAL) {
        my @batch = $srv->recv_wait_multi(100, 5.0);
        last unless @batch;
        while (@batch) {
            my ($req, $id) = splice @batch, 0, 2;
            $srv->reply($id, uc $req);
            $processed++;
        }
    }
    exit 0;
}

# Client: pipeline requests in batches for actual concurrency
my $cli = Data::ReqRep::Shared::Client->new($path);
my $t0 = time();

for (my $sent = 0; $sent < $TOTAL; $sent += $BATCH) {
    my $n = ($sent + $BATCH <= $TOTAL) ? $BATCH : $TOTAL - $sent;
    # fire batch
    my @ids;
    for (1..$n) {
        my $id = $cli->send_wait("msg", 5.0);
        push @ids, $id if defined $id;
    }
    # collect batch
    for my $id (@ids) {
        $cli->get_wait($id, 5.0);
    }
}

my $elapsed = time() - $t0;
printf "%d pipelined round-trips (%d/batch) in %.1f ms (%.0f req/s)\n",
    $TOTAL, $BATCH, $elapsed * 1000, $TOTAL / $elapsed;

waitpid $pid, 0;
$srv->unlink;
