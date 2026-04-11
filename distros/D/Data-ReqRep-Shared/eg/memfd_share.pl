#!/usr/bin/env perl
# memfd sharing: no filesystem path, share channel via fd inheritance across fork
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $srv = Data::ReqRep::Shared->new_memfd("rpc_channel", 64, 16, 1024);
my $fd = $srv->memfd;
print "memfd=$fd (no filesystem path)\n";

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: open channel from inherited fd
    my $cli = Data::ReqRep::Shared::Client->new_from_fd($fd);
    for my $i (1..5) {
        my $resp = $cli->req("hello from child ($i)");
        print "child: $resp\n";
    }
    exit 0;
}

# Parent: serve requests
for (1..5) {
    my ($req, $id) = $srv->recv_wait(5.0);
    last unless defined $req;
    $srv->reply($id, "parent got: $req");
}
waitpid $pid, 0;
