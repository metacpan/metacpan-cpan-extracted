use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(sleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $N_WORKERS = 3;
my $N_REQ     = 60;
my $rr = Data::ReqRep::Shared->new_memfd('shutdown', 64, $N_REQ, 128);

my @pids;
{
    # Installed before the forks, so a TERM reaching a worker that has not started yet is kept.
    my $stop = 0;
    local $SIG{TERM} = sub { $stop = 1 };
    for (1 .. $N_WORKERS) {
        my $pid = fork // die $!;
        if (!$pid) {
            while (!$stop) {
                my ($q, $id) = $rr->recv_wait(0.5);
                next unless defined $id;
                sleep 0.02;
                $rr->reply($id, "ok:$q");
            }
            while (my ($q, $id) = $rr->recv) {
                $rr->reply($id, "drained:$q");
            }
            _exit(0);
        }
        push @pids, $pid;
    }
}

my $c = Data::ReqRep::Shared::Client->new_from_fd($rr->memfd);
my @ids = map { $c->send("q$_") } 1 .. $N_REQ;
is scalar(grep defined, @ids), $N_REQ, 'all requests queued';
sleep 0.05;
kill TERM => @pids;

my %by;
for my $id (@ids) {
    my $reply = $c->get_wait($id, 5);
    $by{ !defined $reply ? 'lost' : $reply =~ /^drained:/ ? 'drained' : 'ok' }++;
}
is $by{lost} // 0, 0, 'every queued request is answered';
cmp_ok $by{drained} // 0, '>', 0, 'the requests still queued at TERM are drained';

for my $pid (@pids) {
    waitpid $pid, 0;
    is $?, 0, "worker $pid exits cleanly";
}
is $c->pending, 0, 'no slots left held';

done_testing;
