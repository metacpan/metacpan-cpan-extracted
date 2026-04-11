#!/usr/bin/env perl
# Load balancer: multiple server workers competing for requests from one channel
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';
use Time::HiRes qw(time);

my $NWORKERS = 4;
my $NCLIENTS = 3;
my $PER_CLIENT = 100;

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 1024, 128, 4096);

# Fork workers — all compete on the same channel
my @workers;
for my $w (1..$NWORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $count = 0;
        while (my ($req, $id) = $srv->recv_wait(3.0)) {
            $srv->reply($id, "w$w:$req");
            $count++;
        }
        print "worker$w processed $count requests\n";
        exit 0;
    }
    push @workers, $pid;
}

# Fork clients — all send to the same channel
my @clients;
for my $c (1..$NCLIENTS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $cli = Data::ReqRep::Shared::Client->new($path);
        my $t0 = time();
        my %by_worker;
        for my $i (1..$PER_CLIENT) {
            my $resp = $cli->req("c${c}r$i");
            if ($resp && $resp =~ /^(w\d+):/) {
                $by_worker{$1}++;
            }
        }
        my $el = time() - $t0;
        printf "client%d: %d reqs in %.0f ms, distribution: %s\n",
            $c, $PER_CLIENT, $el * 1000,
            join(" ", map { "$_=$by_worker{$_}" } sort keys %by_worker);
        exit 0;
    }
    push @clients, $pid;
}

waitpid($_, 0) for @clients;
waitpid($_, 0) for @workers;
$srv->unlink;
