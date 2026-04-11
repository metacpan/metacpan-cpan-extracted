#!/usr/bin/env perl
# Graceful shutdown: server drains in-flight requests on SIGTERM
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
use POSIX ();

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 32, 4096);

my $srv_pid = fork // die "fork: $!";
if ($srv_pid == 0) {
    my $shutdown = 0;
    $SIG{TERM} = sub { $shutdown = 1 };

    while (!$shutdown) {
        my ($req, $id) = $srv->recv_wait(0.5);
        next unless defined $req;
        $srv->reply($id, "ok:$req");
    }

    # Drain remaining requests before exit
    my $drained = 0;
    while (my ($req, $id) = $srv->recv) {
        $srv->reply($id, "draining:$req");
        $drained++;
    }
    print "server: drained $drained in-flight requests\n";
    exit 0;
}

my $cli = Data::ReqRep::Shared::Client->new($path);

# Send some requests
for my $i (1..10) {
    my $resp = $cli->req("job$i");
    print "job$i -> $resp\n";
}

# Signal shutdown, then send a few more that should be drained
kill 'TERM', $srv_pid;
select(undef, undef, undef, 0.05);  # let signal deliver

for my $i (11..13) {
    my $resp = $cli->req_wait("job$i", 2.0);
    printf "job$i -> %s\n", $resp // "no response (server shutting down)";
}

waitpid $srv_pid, 0;
$srv->unlink;
