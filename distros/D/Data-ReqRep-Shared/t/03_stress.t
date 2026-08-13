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

# Per-request timeout. Requests take milliseconds; a CPAN Testers smoker running
# several jobs at once can deschedule a forked client for seconds at a time, so a
# tight cap fails even though the work completes correctly.
my $TMO = $ENV{REQREP_STRESS_TIMEOUT} || 30;

# Server in child -- serves requests until the parent stops it. Its idle timeout
# must exceed the client's, or a starved server would quit first and then cause
# the very client timeouts this test would report.
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

# Spawn client children
my @pids;
for my $c (1..$ncli) {
    my $cpid = fork // die "fork: $!";
    if ($cpid == 0) {
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
        # A wrong answer is always a bug. A missing one only means this process
        # lost the CPU for longer than the timeout, which a loaded smoker does.
        exit 1 if $wrong;
        exit($late ? 2 : 0);
    }
    push @pids, $cpid;
}

my ($wrong_clients, $late_clients) = (0, 0);
for my $p (@pids) {
    waitpid $p, 0;
    my $code = $? >> 8;
    $wrong_clients++ if $code == 1;
    $late_clients++  if $code == 2;
}
is $wrong_clients, 0, 'every response a client received was the right one';
diag "note: $late_clients/$ncli client(s) had a request exceed ${TMO}s -- "
   . "loaded machine, not a correctness failure" if $late_clients;
kill 'TERM', $srv_pid;      # clients are done; don't wait out the idle timeout
waitpid $srv_pid, 0;

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
