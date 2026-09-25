use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

plan skip_all => 'Linux only' unless $^O eq 'linux';

my $duration = $ENV{SOAK_DURATION} || ($ENV{AUTHOR_TESTING} ? 15 : 5);
my $dir = tempdir(CLEANUP => 1);

my %mode = (
    str => { server => sub { Data::ReqRep::Shared->new($_[0], 2048, 8, 2048) },
             client => sub { Data::ReqRep::Shared::Client->new($_[0]) },
             reply  => sub { "echo:$_[0]" },
             req    => sub { "c$_[0]:$_[1]" } },
    int => { server => sub { Data::ReqRep::Shared::Int->new($_[0], 2048, 8) },
             client => sub { Data::ReqRep::Shared::Int::Client->new($_[0]) },
             reply  => sub { $_[0] * 2 },
             req    => sub { $_[0] * 100_000 + $_[1] } },
);

for my $name (qw(str int)) {
    my $m    = $mode{$name};
    my $path = "$dir/soak_$name.shm";
    my $srv  = $m->{server}->($path);

    my (%workers, %clients);
    my $spawn_worker = sub {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $w = $m->{server}->($path);
            while (my ($req, $id) = $w->recv_wait(1)) { $w->reply($id, $m->{reply}->($req)) }
            _exit(0);
        }
        $workers{$pid} = 1;
    };
    # A new id per client, so a late reply to a killed one cannot pass as valid.
    my $next_id = 1;
    my $spawn_client = sub {
        my $c = $next_id++;
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            my $cli = $m->{client}->($path);
            for (my $seq = 1; ; $seq++) {
                my $req = $m->{req}->($c, $seq);
                if ($seq % 20 == 0) {
                    my $id = $cli->send_wait($req, 5);
                    $cli->cancel($id) if defined $id;
                } else {
                    my $resp = eval { $cli->req_wait($req, 5) };
                    if (defined $resp && $resp ne $m->{reply}->($req)) {
                        warn "$name client $c: got '$resp' for '$req'\n";
                        _exit(1);
                    }
                }
                usleep(200);
            }
        }
        $clients{$pid} = $c;
    };
    $spawn_worker->() for 1 .. 4;
    $spawn_client->() for 1 .. 4;

    my @bad;
    my $reap = sub {
        my $pid = shift;
        waitpid $pid, 0;
        push @bad, $clients{$pid} if exists $clients{$pid} && POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?);
    };
    my $end = time + $duration / 2;
    for (my $kill = 0; time < $end; $kill++) {
        usleep(1_000_000);
        my $pool = $kill % 2 ? \%clients : \%workers;
        my $victim = (keys %$pool)[rand keys %$pool];
        kill KILL => $victim;
        $reap->($victim);
        delete $pool->{$victim};
        $kill % 2 ? $spawn_client->() : $spawn_worker->();
    }
    kill TERM => keys %clients, keys %workers;
    $reap->($_) for keys %clients, keys %workers;

    is "@bad", '', "$name: no client got a reply meant for another request";
    my $st = $srv->stats;
    diag "$name: $st->{requests} requests, $st->{replies} replies, $st->{recoveries} recoveries";
    ok $st->{replies} > 0, "$name: requests were served";

    my $cli  = $m->{client}->($path);
    my $held = grep { defined $cli->send($m->{req}->(0, $_)) } 1 .. $srv->resp_slots;
    is $held, $srv->resp_slots, "$name: every slot is recoverable once everyone is gone";
}

done_testing;
