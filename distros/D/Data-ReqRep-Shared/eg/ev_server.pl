#!/usr/bin/env perl
# EV event-loop integration example
use strict;
use warnings;
use EV;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);
my $req_fd = $srv->eventfd;
my $rep_fd = $srv->reply_eventfd;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Child: EV-driven server
    my $done = 0;
    my $w = EV::io $req_fd, EV::READ, sub {
        $srv->eventfd_consume;
        while (my ($req, $id) = $srv->recv) {
            if ($req eq 'quit') {
                $srv->reply($id, 'bye');
                $srv->reply_notify;
                $done = 1;
                EV::break;
                return;
            }
            $srv->reply($id, uc $req);
        }
        $srv->reply_notify;
    };
    EV::run;
    exit 0;
}

# Parent: client with eventfd notifications
my $cli = Data::ReqRep::Shared::Client->new($path);
$cli->req_eventfd_set($req_fd);
$cli->eventfd_set($rep_fd);

for my $msg ("hello", "world", "quit") {
    my $id = $cli->send_wait_notify($msg);

    my $rin = '';
    vec($rin, $rep_fd, 1) = 1;
    select($rin, undef, undef, 5.0);
    $cli->eventfd_consume;

    my $resp = $cli->get($id);
    print "$msg -> $resp\n";
}
waitpid $pid, 0;
$srv->unlink;
