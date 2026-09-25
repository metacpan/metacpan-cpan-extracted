#!/usr/bin/env perl
# Graceful shutdown: on SIGTERM the server stops taking new work and answers
# the requests already queued
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
use Time::HiRes 'sleep';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 32, 4096);

# Installed before the fork, so a TERM that comes before the server starts is kept
my $shutdown = 0;
$SIG{TERM} = sub { $shutdown = 1 };
my $srv_pid = fork // die "fork: $!";
if ($srv_pid == 0) {

    while (!$shutdown) {
        my ($req, $id) = $srv->recv_wait(0.5);
        next unless defined $id;
        sleep 0.05;    # the work
        $srv->reply($id, "ok:$req");
    }

    # One drain takes what is queued now; a recv loop runs on while
    # new requests arrive before the queue empties
    my $drained = 0;
    my @queued = $srv->drain;
    while (my ($req, $id) = splice @queued, 0, 2) {
        $srv->reply($id, "drained:$req");
        $drained++;
    }
    print "server: drained $drained queued requests\n";
    exit 0;
}
$SIG{TERM} = 'DEFAULT';

my $cli = Data::ReqRep::Shared::Client->new($path);

my @jobs = map { [$_, $cli->send("job$_")] } 1 .. 10;
sleep 0.12;
kill 'TERM', $srv_pid;

for my $job (@jobs) {
    my ($n, $id) = @$job;
    my $resp = $cli->get_wait($id, 2.0);
    $cli->cancel($id) unless defined $resp;
    printf "job%d -> %s\n", $n, $resp // 'no response';
}

waitpid $srv_pid, 0;
$srv->unlink;
