use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tmpnam();
my $ncli = 4;
my $per_cli = 500;
my $cancel_every = 10;

my $srv = Data::ReqRep::Shared->new($path, 256, 64, 4096);

# Server in child — processes all requests until timeout
my $srv_pid = fork // die "fork: $!";
if ($srv_pid == 0) {
    while (1) {
        my ($req, $id) = $srv->recv_wait(5.0);
        last unless defined $req;
        $srv->reply($id, "re:$req");
    }
    exit 0;
}

# Spawn client children
my @pids;
for my $c (1..$ncli) {
    my $cpid = fork // die "fork: $!";
    if ($cpid == 0) {
        my $cli = Data::ReqRep::Shared::Client->new($path);
        my $ok = 0;
        for my $i (1..$per_cli) {
            if ($i % $cancel_every == 0) {
                my $id = $cli->send_wait("c${c}m${i}", 5.0);
                $cli->cancel($id) if defined $id;
                $ok++;
            } else {
                my $resp = $cli->req_wait("c${c}m${i}", 5.0);
                $ok++ if defined $resp && $resp eq "re:c${c}m${i}";
            }
        }
        exit($ok == $per_cli ? 0 : 1);
    }
    push @pids, $cpid;
}

for my $p (@pids) {
    waitpid $p, 0;
    is $? >> 8, 0, "client $p exited ok";
}
waitpid $srv_pid, 0;
is $? >> 8, 0, 'server exited ok';

# Verify stats
{
    my $s = $srv->stats;
    ok $s->{requests} > 0, "processed $s->{requests} requests";
    ok $s->{replies} > 0, "sent $s->{replies} replies";
    diag sprintf "requests=%d replies=%d recoveries=%d",
        $s->{requests}, $s->{replies}, $s->{recoveries};
}

$srv->unlink;
done_testing;
