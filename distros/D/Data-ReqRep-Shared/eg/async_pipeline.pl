#!/usr/bin/env perl
# Async pipeline: fire N requests, collect all replies out of order
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 64, 4096);

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Server: simulate variable-latency processing
    while (my ($req, $id) = $srv->recv_wait(5.0)) {
        select(undef, undef, undef, 0.001 * rand());
        $srv->reply($id, "done:$req");
    }
    exit 0;
}

my $cli = Data::ReqRep::Shared::Client->new($path);

# Fire all requests without waiting
my @ids;
for my $i (1..20) {
    my $id = $cli->send_wait("task$i");
    push @ids, [$i, $id];
    print "sent task$i (id=$id)\n";
}

print "pending: ", $cli->pending, "\n";

# Collect replies (in submission order, but could be any order)
for my $item (@ids) {
    my ($i, $id) = @$item;
    my $resp = $cli->get_wait($id, 5.0);
    printf "task%-2d -> %s\n", $i, $resp // "timeout";
}

print "pending: ", $cli->pending, "\n";
waitpid $pid, 0;
$srv->unlink;
