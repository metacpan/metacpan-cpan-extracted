#!/usr/bin/env perl
# Auto-scaling worker pool driven by EV event loop
#
# EV::io on request eventfd → scale up when backlog grows
# EV::child per worker → reap + maintain minimum on exit
# Workers self-exit after idle timeout (natural shrink)
use strict;
use warnings;
use EV;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
$| = 1;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 1024, 128, 4096);
my $req_fd = $srv->eventfd;

my $MIN_WORKERS  = 1;
my $MAX_WORKERS  = 8;
my $SCALE_UP_AT  = 5;
my $WORKER_IDLE  = 2.0;

my %workers;   # pid => EV::child watcher

sub spawn_worker {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($req, $id) = $srv->recv_wait($WORKER_IDLE)) {
            select(undef, undef, undef, 0.005);
            $srv->reply($id, "w$$:$req");
        }
        exit 0;
    }
    # EV::child fires when this worker exits
    $workers{$pid} = EV::child $pid, 0, sub {
        delete $workers{$pid};
        printf "[pool] -%d (workers=%d)\n", $pid, scalar keys %workers;
        spawn_worker() while scalar keys %workers < $MIN_WORKERS;
    };
    printf "[pool] +%d (workers=%d)\n", $pid, scalar keys %workers;
}

spawn_worker() for 1..$MIN_WORKERS;

# Scale up when request backlog grows
my $req_w = EV::io $req_fd, EV::READ, sub {
    $srv->eventfd_consume;
    my $depth = $srv->size;
    my $nw = scalar keys %workers;
    if ($depth > $SCALE_UP_AT && $nw < $MAX_WORKERS) {
        my $add = ($depth > 20) ? 3 : 1;
        $add = $MAX_WORKERS - $nw if $add > $MAX_WORKERS - $nw;
        spawn_worker() for 1..$add;
    }
};

# Client in child
my $cli_pid = fork // die "fork: $!";
if ($cli_pid == 0) {
    my $cli = Data::ReqRep::Shared::Client->new($path);
    $cli->req_eventfd_set($req_fd);

    print "--- phase 1: light (10 sequential) ---\n";
    for (1..10) {
        my $id = $cli->send_wait_notify("light-$_", 5.0);
        $cli->get_wait($id, 5.0) if defined $id;
    }

    print "--- phase 2: burst (50 pipelined) ---\n";
    my @ids;
    push @ids, $cli->send_wait_notify("burst-$_", 5.0) for 1..50;
    for my $id (@ids) { $cli->get_wait($id, 5.0) if defined $id }

    print "--- phase 3: quiet 3s (workers shrink) ---\n";
    select(undef, undef, undef, 3.0);

    print "--- phase 4: resume (10 sequential) ---\n";
    for (1..10) {
        my $id = $cli->send_wait_notify("resume-$_", 5.0);
        $cli->get_wait($id, 5.0) if defined $id;
    }

    print "--- done ---\n";
    exit 0;
}

# Stop when client exits
my $cli_w = EV::child $cli_pid, 0, sub {
    my $s = $srv->stats;
    printf "[pool] client done: %d requests, %d replies\n",
        $s->{requests}, $s->{replies};
    EV::break;
};

EV::run;
$srv->unlink;
