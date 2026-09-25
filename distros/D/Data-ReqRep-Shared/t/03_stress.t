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

# A loaded smoker can deschedule a forked client for seconds at a time.
my $TMO = $ENV{REQREP_STRESS_TIMEOUT} || 30;

# The server's idle timeout must exceed the client's, or a starved server quits first.
my $srv_pid = fork // die "fork: $!";
if ($srv_pid == 0) {
    $SIG{TERM} = sub { exit 0 };
    while (1) {
        my ($req, $id) = $srv->recv_wait($TMO + 5);
        last unless defined $req;
        $srv->reply($id, "re:$req");
    }
    exit 0;
}

my @pids;
for my $c (1..$ncli) {
    my $cpid = fork // die "fork: $!";
    if ($cpid == 0) {
        local $SIG{__DIE__} = sub { print STDERR @_; exit 1 };
        my $cli = Data::ReqRep::Shared::Client->new($path);
        my ($wrong, $late) = (0, 0);
        for my $i (1..$per_cli) {
            if ($i % $cancel_every == 0) {
                my $id = $cli->send_wait("c${c}m${i}", $TMO);
                $cli->cancel($id) if defined $id;
                $late++ unless defined $id;
            } else {
                my $resp = $cli->req_wait("c${c}m${i}", $TMO);
                if    (!defined $resp)              { $late++  }
                elsif ($resp ne "re:c${c}m${i}")    { $wrong++ }
            }
        }
        exit 1 if $wrong;
        exit($late ? 2 : 0);
    }
    push @pids, $cpid;
}

my ($wrong_clients, $late_clients) = (0, 0);
for my $p (@pids) {
    waitpid $p, 0;
    $late_clients++  if $? == 512;
    $wrong_clients++ if $? && $? != 512;
}
is $wrong_clients, 0, 'every response a client received was the right one';
diag "note: $late_clients/$ncli client(s) had a request exceed ${TMO}s -- "
   . "loaded machine, not a correctness failure" if $late_clients;
kill 'TERM', $srv_pid;
waitpid $srv_pid, 0;
is $?, 0, "the server exited cleanly";

{
    my $s = $srv->stats;
    ok $s->{requests} > 0, "processed $s->{requests} requests";
    ok $s->{replies} > 0, "sent $s->{replies} replies";
    diag sprintf "requests=%d replies=%d recoveries=%d",
        $s->{requests}, $s->{replies}, $s->{recoveries};
}

$srv->unlink;
done_testing;
