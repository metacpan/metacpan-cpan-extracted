#!/usr/bin/env perl
# Minimal fork-based echo server/client
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 1024, 64, 4096);

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    while (my ($req, $id) = $srv->recv_wait) {
        $srv->reply($id, $req eq 'quit' ? 'bye' : "echo: $req");
        last if $req eq 'quit';
    }
    exit 0;
}

my $cli = Data::ReqRep::Shared::Client->new($path);
for my $msg ("hello", "world", "foo bar", "quit") {
    my $resp = $cli->req($msg);
    print "$msg -> $resp\n";
}
waitpid $pid, 0;
$srv->unlink;
