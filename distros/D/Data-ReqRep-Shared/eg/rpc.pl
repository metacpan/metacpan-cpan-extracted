#!/usr/bin/env perl
# Simple RPC dispatch: client sends "op:args", server routes to handlers
use strict;
use warnings;
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use File::Temp 'tmpnam';

my $path = tmpnam();
my $srv = Data::ReqRep::Shared->new($path, 256, 32, 4096);

# RPC handlers
my %handlers = (
    add  => sub { my ($a, $b) = split /,/, $_[0]; $a + $b },
    mul  => sub { my ($a, $b) = split /,/, $_[0]; $a * $b },
    echo => sub { $_[0] },
    rev  => sub { scalar reverse $_[0] },
    time => sub { time() },
);

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    # Server: dispatch on "op:args" format
    while (my ($req, $id) = $srv->recv_wait(5.0)) {
        my ($op, $args) = split /:/, $req, 2;
        $args //= '';
        if (my $handler = $handlers{$op}) {
            my $result = eval { $handler->($args) };
            $srv->reply($id, defined $result ? $result : "ERR:$@");
        } else {
            $srv->reply($id, "ERR:unknown op '$op'");
        }
    }
    exit 0;
}

my $cli = Data::ReqRep::Shared::Client->new($path);
for my $call ("add:17,25", "mul:6,7", "echo:hello", "rev:abcdef", "time:", "bogus:x") {
    my $resp = $cli->req($call);
    printf "%-16s -> %s\n", $call, $resp;
}
waitpid $pid, 0;
$srv->unlink;
