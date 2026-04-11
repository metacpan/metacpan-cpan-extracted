use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $path = tmpnam();
my $N = 100;

# Server in child, multiple requests from parent
{
    my $srv = Data::ReqRep::Shared->new($path, 64, 16, 4096);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # child = server
        for (1..$N) {
            my ($req, $id) = $srv->recv_wait(5.0);
            last unless defined $req;
            $srv->reply($id, "echo:$req");
        }
        exit 0;
    }

    # parent = client
    my $cli = Data::ReqRep::Shared::Client->new($path);

    for my $i (1..$N) {
        my $resp = $cli->req("msg$i");
        is $resp, "echo:msg$i", "cross-process round-trip $i";
    }

    waitpid $pid, 0;
    is $? >> 8, 0, 'server child exited cleanly';

    $srv->unlink;
}

# Multiple clients, one server
{
    my $path2 = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path2, 64, 32, 256);
    my $ncli = 4;
    my $per_cli = 10;

    my $srv_pid = fork();
    die "fork: $!" unless defined $srv_pid;

    if ($srv_pid == 0) {
        # server child
        for (1..($ncli * $per_cli)) {
            my ($req, $id) = $srv->recv_wait(5.0);
            last unless defined $req;
            $srv->reply($id, "re:$req");
        }
        exit 0;
    }

    # spawn client children
    my @pids;
    for my $c (1..$ncli) {
        my $cpid = fork();
        die "fork: $!" unless defined $cpid;
        if ($cpid == 0) {
            my $cli = Data::ReqRep::Shared::Client->new($path2);
            for my $i (1..$per_cli) {
                my $resp = $cli->req("c${c}m${i}");
                exit 1 unless $resp eq "re:c${c}m${i}";
            }
            exit 0;
        }
        push @pids, $cpid;
    }

    for my $p (@pids) {
        waitpid $p, 0;
        is $? >> 8, 0, "client $p exited ok";
    }
    waitpid $srv_pid, 0;
    is $? >> 8, 0, 'multi-client server exited ok';

    $srv->unlink;
}

# memfd + fork
{
    my $srv = Data::ReqRep::Shared->new_memfd("fork_test", 16, 8, 256);
    my $mfd = $srv->memfd;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # child = server
        my ($req, $id) = $srv->recv_wait(2.0);
        $srv->reply($id, "memfd:$req") if defined $req;
        exit 0;
    }

    # parent = client via new_from_fd
    my $cli = Data::ReqRep::Shared::Client->new_from_fd($mfd);
    my $resp = $cli->req("test");
    is $resp, "memfd:test", 'memfd fork round-trip';

    waitpid $pid, 0;
    is $? >> 8, 0, 'memfd server exited ok';
}

done_testing;
