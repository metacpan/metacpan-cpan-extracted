#!/usr/bin/env perl
# Pre-fork worker pool: N workers competing for requests from a shared channel
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
use POSIX ();

my $NWORKERS = 4;
my $NREQS    = 20;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 64, 8192);

# Fork workers
my @workers;
for my $w (1..$NWORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        while (my ($req, $id) = $srv->recv_wait(5.0)) {
            # simulate work
            select(undef, undef, undef, 0.01 * rand());
            $srv->reply($id, "worker$w:$req");
        }
        exit 0;
    }
    push @workers, $pid;
}

# Client sends requests
my $cli = Data::ReqRep::Shared::Client->new($path);
for my $i (1..$NREQS) {
    my $resp = $cli->req("job$i");
    print "job$i -> $resp\n";
}

# Wait for workers to drain
waitpid($_, 0) for @workers;
$srv->unlink;
