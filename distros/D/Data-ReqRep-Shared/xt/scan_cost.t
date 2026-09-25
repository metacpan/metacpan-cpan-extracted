use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes qw(time sleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

plan skip_all => 'Linux only' unless $^O eq 'linux';

sub failed_send_cost {
    my ($slots, $n) = @_;
    my $s = Data::ReqRep::Shared->new_memfd('scan', 2 * $slots, $slots, 64);
    pipe my $r, my $w or die $!;
    my $holder = fork // die $!;
    if (!$holder) {
        my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $c->send('x') for 1 .. $slots;
        syswrite $w, 'x';
        sleep 60;
        POSIX::_exit(0);
    }
    close $w;
    sysread $r, my $go, 1;
    my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    my $t0 = time;
    for (1 .. $n) { defined $c->send('y') and die "a send succeeded with every slot held" }
    my $each = (time - $t0) / $n;
    kill KILL => $holder;
    waitpid $holder, 0;
    return $each;
}

my $few  = failed_send_cost(4, 20000);
my $many = failed_send_cost(64, 20000);
diag sprintf 'failed send: %.1f us with 4 slots held, %.1f us with 64', $few * 1e6, $many * 1e6;
cmp_ok $many * 1e6, '<', 20, 'a failed send with 64 held slots stays cheap';

my $lots = failed_send_cost(8192, 400);
diag sprintf 'failed send: %.1f us with 8192 slots held', $lots * 1e6;
cmp_ok $lots * 1e6, '<', 1000, 'the throttle still holds when one scan outlasts its interval';

{
    my ($holders, $n) = (64, 4096);
    my $s = Data::ReqRep::Shared->new_memfd('spread', 2 * $n, $n, 64);
    my (@kids, @go, @done);
    for (1 .. $holders) {
        pipe my $cr, my $pw or die $!;
        pipe my $pr, my $cw or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $pw; close $pr;
            my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
            while (sysread $cr, my $b, 1) { defined $c->send('x') or die 'send failed'; syswrite $cw, 'x' }
            POSIX::_exit(0);
        }
        close $cr; close $cw;
        push @kids, $pid; push @go, $pw; push @done, $pr;
    }
    for my $i (0 .. $n - 1) { syswrite $go[$i % $holders], 'x'; sysread $done[$i % $holders], my $b, 1 }
    my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    my @took;
    for (1 .. 5) {
        sleep 0.02;
        my $t0 = time;
        defined $c->send('y') and die 'a send succeeded with every slot held';
        push @took, time - $t0;
    }
    my $median = (sort { $a <=> $b } @took)[2];
    diag sprintf 'failed send scanning %d slots of %d holders: %.2f ms', $n, $holders, $median * 1e3;
    cmp_ok $median * 1e3, '<', 5, 'a scan past slots of many holders stays cheap';
    close $_ for @go;
    waitpid $_, 0 for @kids;
}

{
    my $n = 2048;
    my $s = Data::ReqRep::Shared->new_memfd('dead', 2 * $n, $n, 64);
    my $holder = fork // die $!;
    if (!$holder) {
        my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        $c->send('x') for 1 .. $n;
        POSIX::_exit(0);
    }
    waitpid $holder, 0;
    my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    my $t0 = time;
    my $sent = grep { defined $c->send('y') } 1 .. $n;
    my $took = time - $t0;
    is $sent, $n, "all $n slots of a killed client are recovered";
    cmp_ok $took, '<', 1, sprintf '  in well under a second (took %.2f s)', $took;
}

# One client leaves its notifications unread, so every reply to it is refused.
# Three others watch, lest one share its counter.
{
    my $n = 65536;
    my $s = Data::ReqRep::Shared->new_memfd('lost', 16, $n, 8);
    my $lax = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    $lax->ready_fd;
    my $round = sub { my $id = $lax->send('x'); my (undef, $rid) = $s->recv; $s->reply($rid, 'y'); $lax->get($id) };
    my $qlen = do { open my $q, '<', '/proc/sys/net/unix/max_dgram_qlen'; defined $q ? <$q> + 0 : 512 };
    $round->() for 0 .. $qlen + 8;
    my @watch = map { my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd); $c->ready_fd; $c } 1 .. 3;
    my @took = (0) x @watch;
    for (1 .. 200) {
        $round->();
        for my $i (0 .. $#watch) { my $t0 = time; $watch[$i]->ready; $took[$i] += time - $t0 }
    }
    my ($best) = sort { $a <=> $b } @took;
    diag sprintf 'ready beside a client losing notifications, %d slots: %.1f us', $n, $best / 200 * 1e6;
    cmp_ok $best / 200 * 1e6, '<', 50, 'another client\'s lost notifications cost a ready no scan';
}

for my $case ('two receivers with the same low pid bits', 'ten receivers in turn') {
    my $s = Data::ReqRep::Shared->new_memfd('probe', 64, 64, 16);
    my $worker = sub {
        my $pid = fork // die $!;
        return $pid if $pid;
        my $w = Data::ReqRep::Shared->new_from_fd($s->memfd);
        while (1) {
            my ($r, $id) = $w->recv_wait(1);
            next unless defined $id;
            last if $r eq 'quit';
            my $until = time + 100e-6;
            1 while time < $until;              # busy long enough that the client waits on DISPATCHED
            $w->reply($id, $r);
        }
        POSIX::_exit(0);
    };
    my @workers;
    if ($case =~ /^ten/) {
        @workers = map { $worker->() } 1 .. 10;
    } else {
        @workers = ($worker->());
        for (1 .. 64) {
            my $pid = $worker->();
            if (($pid & 7) == ($workers[0] & 7)) { push @workers, $pid; last }
            kill 'KILL', $pid;
            waitpid $pid, 0;
        }
    }
    SKIP: {
        skip 'no two receiver pids with the same low bits', 1 if @workers < 2;
        my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
        my $reads = sub { open my $f, '<', '/proc/self/io' or return; my ($n) = map { /^syscr:\s+(\d+)/ ? $1 : () } <$f>; $n };
        sleep 2.2;                               # past the handle's first tick, when probing starts
        $c->req_wait('warm', 5) for 1 .. 50;
        my $r0 = $reads->();
        my $n = 2000;
        for (1 .. $n) {
            my $id = $c->send('x');
            my $until = time + 30e-6;
            1 while time < $until;               # a receiver has taken it by the time the wait starts
            $c->get_wait($id, 5);
        }
        my $per = ($reads->() - $r0 - 1) / $n;
        diag sprintf 'reads per request, %s: %.3f', $case, $per;
        cmp_ok $per, '<', 0.1, "a client reads /proc for its receivers a few times a tick, $case";
    }
    my $q = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    $q->send_wait('quit', 5) for @workers;
    waitpid $_, 0 for @workers;
}

done_testing;
