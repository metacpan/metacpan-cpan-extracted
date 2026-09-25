use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp qw(tempdir);
use IO::Select;
use POSIX ();
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $dir = tempdir(CLEANUP => 1);
my %kind = (
    Str => [sub { Data::ReqRep::Shared->new($_[0], 16, 8, 64) }, sub { Data::ReqRep::Shared::Client->new($_[0]) }, 'x'],
    Int => [sub { Data::ReqRep::Shared::Int->new($_[0], 16, 8) }, sub { Data::ReqRep::Shared::Int::Client->new($_[0]) }, 7],
);

sub readable { IO::Select->new($_[0])->can_read($_[1]) ? 1 : 0 }

for my $name (qw(Str Int)) {
    my ($server, $client, $msg) = @{ $kind{$name} };
    my $p = "$dir/ready_$name.shm";
    my $srv = $server->($p);

    subtest "$name: a client's ready_fd reports its own replies" => sub {
        my $cli = $client->($p);
        my $fd = $cli->ready_fd;
        ok $fd >= 0, 'ready_fd gives a descriptor';
        is $cli->ready_fd, $fd, '  the same one each time';
        my @ids = map { $cli->send($msg) } 1 .. 3;
        ok !readable($fd, 0.2), 'nothing is ready before a reply';
        pipe my $r, my $w or die $!;
        my $replier = fork // die $!;
        if (!$replier) {
            close $r;
            my $s = $server->($p);
            for (1 .. 3) { my (undef, $id) = $s->recv_wait(2); $s->reply($id, $msg) if $_ < 3; }
            syswrite $w, 'x';
            sleep 3;
            POSIX::_exit(0);
        }
        close $w;
        ok readable($fd, 10), 'the descriptor becomes readable when replies land';
        sysread $r, my $replied, 1;
        is_deeply [sort { $a <=> $b } $cli->ready], [sort { $a <=> $b } @ids[0, 1]], 'ready lists the two replied ids';
        is_deeply [$cli->ready], [], '  once';
        is $cli->get($_), $msg, "  and get takes each" for @ids[0, 1];
        kill KILL => $replier;
        waitpid $replier, 0;
        $cli->cancel($ids[2]);
    };

    subtest "$name: another client is not woken" => sub {
        my $a = $client->($p);
        my $fd_a = $a->ready_fd;
        pipe my $r, my $w or die $!;
        my $b = fork // die $!;
        if (!$b) {
            close $r;
            my $c = $client->($p);
            my $fd = $c->ready_fd;
            my $id = $c->send($msg);
            syswrite $w, pack 'Q', $id;
            my $ok = readable($fd, 3) && grep({ $_ == $id } $c->ready) && defined $c->get($id);
            POSIX::_exit($ok ? 0 : 1);
        }
        close $w;
        sysread $r, my $packed, 8;
        my (undef, $id) = $srv->recv_wait(2);
        is $id, unpack('Q', $packed), 'the other client sent a request';
        ok $srv->reply($id, $msg), '  it is replied to';
        waitpid $b, 0;
        is $?, 0, '  and the other client is woken for it';
        ok !readable($fd_a, 0.3), 'this client is not';
    };

    subtest "$name: ready skips replies already read, and recovers dropped notifications" => sub {
        my $cli = $client->($p);
        my $fd = $cli->ready_fd;
        my $id = $cli->send($msg);
        my (undef, $rid) = $srv->recv;
        $srv->reply($rid, $msg);
        is $cli->get($id), $msg, 'the reply is read before ready is called';
        is_deeply [$cli->ready], [], '  so ready does not list it';

        my $id2 = $cli->send($msg);
        (undef, $rid) = $srv->recv;
        $srv->reply($rid, $msg);
        readable($fd, 2);
        1 while defined POSIX::read($fd, my $buf, 8);
        is_deeply [$cli->ready], [], 'a notification lost without a trace is not invented';
        my $other = $client->($p);
        $other->ready_fd;
        my $oid = $other->send($msg);
        (undef, $rid) = $srv->recv;
        $srv->reply($rid, $msg);
        # Count a loss against every client: the loss counters follow the process records.
        open my $fh, '+<', $p or die $!;
        binmode $fh;
        my ($proc_off, $proc_slots, $lost_slots) = map { seek $fh, $_, 0; read $fh, my $b, 4; unpack 'L', $b } 172, 176, 180;
        for my $at (map { $proc_off + 8 * $proc_slots + 4 * $_ } 0 .. $lost_slots - 1) {
            seek $fh, $at, 0; read $fh, my $lost, 4;
            seek $fh, $at, 0; print {$fh} pack 'L', unpack('L', $lost) + 1;
        }
        close $fh;
        is_deeply [$cli->ready], [$id2], 'one counted as dropped is found';
        is $cli->get($id2), $msg, '  and read';
    };

    subtest "$name: a forked child needs its own ready_fd" => sub {
        my $cli = $client->($p);
        my $fd = $cli->ready_fd;
        my $child = fork // die $!;
        if (!$child) {
            my $id = $cli->send($msg);
            my $s = $server->($p);
            my (undef, $rid) = $s->recv_wait(2);
            $s->reply($rid, $msg);
            my $parent_woken = readable($fd, 0.3);
            my $own = $cli->ready_fd;
            my $id2 = $cli->send($msg);
            (undef, $rid) = $s->recv_wait(2);
            $s->reply($rid, $msg);
            my $ok = !$parent_woken && readable($own, 2) && grep({ $_ == $id2 } $cli->ready);
            $cli->get($_) for $id, $id2;
            POSIX::_exit($ok ? 0 : 1);
        }
        waitpid $child, 0;
        is $?, 0, 'the child is notified only on the descriptor it asked for';
        ok !readable($fd, 0.2), '  and the parent is not woken for its replies';
    };

    subtest "$name: ready recovers all replies when count exceeds 4096 on dropped notifications" => sub {
        my $p_large = "$dir/ready_large_$name.shm";
        my $s_large = $name eq 'Str'
            ? Data::ReqRep::Shared->new($p_large, 5000, 5000, 64)
            : Data::ReqRep::Shared::Int->new($p_large, 5000, 5000);
        my $c_large = $name eq 'Str'
            ? Data::ReqRep::Shared::Client->new($p_large)
            : Data::ReqRep::Shared::Int::Client->new($p_large);
        my $fd = $c_large->ready_fd;
        my $cnt = 4500;
        my @sent = map { $c_large->send($msg) } 1 .. $cnt;
        for (1 .. $cnt) {
            my (undef, $rid) = $s_large->recv;
            $s_large->reply($rid, $msg);
        }
        my @r1 = $c_large->ready;
        ok readable($fd, 1), 'the descriptor stays readable while ids are left over';
        my @r2 = $c_large->ready;
        is scalar(@r1) + scalar(@r2), $cnt, "all $cnt replies retrieved without loss";
        ok !readable($fd, 0.2), '  and goes quiet once they are all taken';
        is_deeply [sort { $a <=> $b } (@r1, @r2)], [sort { $a <=> $b } @sent], "  matching all sent ids";
        $c_large->get($_) for @sent;
        unlink $p_large;
    };
}

my $qlen = do { open my $q, '<', '/proc/sys/net/unix/max_dgram_qlen'; defined $q ? <$q> + 0 : 0 };

# A server sends every client's notifications from one socket, whose buffer holds the unread ones.
for my $name (qw(Str Int)) {
    my ($server, $client, $msg) = @{ $kind{$name} };
    subtest "$name: clients leaving their notifications unread do not silence another's" => sub {
        my $p = "$dir/ready_unread_$name.shm";
        my $srv = $server->($p);
        my $q = $qlen || 512;
        for my $lax (map { my $c = $client->($p); $c->ready_fd; $c } 1 .. int(600 / ($q + 1)) + 1) {
            for (0 .. $q + 8) {
                my $id = $lax->send($msg);
                my (undef, $rid) = $srv->recv;
                $srv->reply($rid, $msg);
                $lax->get($id);
            }
        }
        my $cli = $client->($p);
        my $fd = $cli->ready_fd;
        my $id = $cli->send($msg);
        my (undef, $rid) = $srv->recv;
        $srv->reply($rid, $msg);
        ok readable($fd, 1), 'the other client is still woken for its reply';
        is_deeply [$cli->ready], [$id], '  and ready lists it once';
        unlink $p;
    };
}

my $nofile = do { open my $l, '<', '/proc/self/limits'; my ($n) = map { /^Max open files\s+(\d+)/ ? $1 : () } <$l>; $n // 0 };
for my $name (qw(Str Int)) {
    my $k = $kind{$name};
    my $msg = $k->[2];
    my $open = sub {
        my ($p, $slots) = @_;
        my $srv = $name eq 'Str' ? Data::ReqRep::Shared->new($p, 8192, $slots, 64) : Data::ReqRep::Shared::Int->new($p, 8192, $slots);
        return ($srv, $k->[1]->($p));
    };

    subtest "$name: an id listed and not yet read is not listed again" => sub {
        plan skip_all => "max_dgram_qlen $qlen is unknown or too large to overflow here" if !$qlen || $qlen > 4000;
        my ($srv, $cli) = $open->("$dir/told_$name.shm", $qlen + 64);
        $cli->ready_fd;
        my $x = $cli->send($msg);
        my (undef, $rid) = $srv->recv;
        $srv->reply($rid, $msg);
        is_deeply [$cli->ready], [$x], 'ready lists the reply';
        # Overflow this client's own queue, so that the next ready also looks through its slots.
        my @more = map { $cli->send($msg) } 0 .. $qlen + 8;
        for (@more) { (undef, $rid) = $srv->recv; $srv->reply($rid, $msg) }
        my @again;
        while (my @r = $cli->ready) { push @again, @r }
        is scalar(grep { $_ == $x } @again), 0, '  and not again while it waits to be read';
        is scalar(@again), scalar(@more), '  while every later one is listed';
        $cli->get($_) for $x, @more;
    };

    subtest "$name: a search cut short starts over when a notification is refused meanwhile" => sub {
        plan skip_all => "max_dgram_qlen $qlen leaves no search to cut short" if !$qlen || $qlen >= 2048;
        my ($first, $spare) = (4500, $qlen + 100);
        my ($srv, $cli) = $open->("$dir/resume_$name.shm", $first + $spare);
        my $fd = $cli->ready_fd;
        my @ids = map { $cli->send($msg) } 1 .. $first;
        for (@ids) { my (undef, $rid) = $srv->recv; $srv->reply($rid, $msg) }
        my @r1 = $cli->ready;
        cmp_ok scalar @r1, '<', $first, 'the first ready stops short of every reply';
        $cli->get($_) for @r1;
        # The spare slots fill first; the last request lands in a slot that search already passed.
        my @fill = map { $cli->send($msg) } 1 .. $spare;
        my $y = $cli->send($msg);
        my @rid = map { (undef, my $r) = $srv->recv; $r } 0 .. $spare;
        $srv->reply($_, $msg) for @rid[0 .. $qlen + 8];   # the queue is full well before these end
        $srv->reply($rid[-1], $msg);
        my @r2;
        for (1 .. 100) { last unless readable($fd, 0.2); push @r2, $cli->ready }
        ok scalar(grep { $_ == $y } @r2), '  the reply whose notification was refused is listed';
        $cli->get($_) for @ids, @fill, $y;
    };

    subtest "$name: a server whose descriptors run out after it takes a request still notifies" => sub {
        plan skip_all => "an open-files limit of $nofile is too many to use up here" if !$nofile || $nofile > 1_100_000;
        my ($srv, $cli) = $open->("$dir/nofd_$name.shm", 4);
        my $fd = $cli->ready_fd;
        my $id = $cli->send($msg);
        my $pid = fork // die $!;
        if (!$pid) {
            my (undef, $rid) = $srv->recv;
            my @fill;
            while (defined(my $f = POSIX::dup(0))) { push @fill, $f }
            my $ok = $srv->reply($rid, $msg);
            POSIX::close($_) for @fill;
            POSIX::_exit($ok ? 0 : 1);
        }
        waitpid $pid, 0;
        is $?, 0, 'the reply goes through';
        ok readable($fd, 1), '  and wakes the client';
        is_deeply [$cli->ready], [$id], '  whose ready lists it';
    };
}

done_testing;
