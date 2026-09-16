use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(:flock O_RDONLY);
use POSIX ();
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $dir = tempdir(CLEANUP => 1);
my $n   = 0;
sub fresh { my $p = "$dir/h" . ++$n . '.shm'; return ($p, Data::ReqRep::Shared->new($p, 16, 4, 256, 4096)) }

sub poke {
    my ($path, $off, $u32) = @_;
    open my $f, '+<', $path or die "$path: $!";
    binmode $f;
    seek $f, $off, 0 or die $!;
    print {$f} pack('L<', $u32) or die $!;
    close $f or die $!;
}

# Header is 256 bytes, then 24-byte request slots; resp_slot is at offset 12.
use constant { MUTEX => 192, ARENA_WPOS => 200, SLOT0_RESP_SLOT => 256 + 12 };

subtest 'a request with an out-of-range reply id does not kill the server' => sub {
    my ($p, $s) = fresh();
    my $c = Data::ReqRep::Shared::Client->new($p);
    $c->send('poisoned');
    my $good = $c->send('innocent');
    poke($p, SLOT0_RESP_SLOT, 0xFFFF_FFFF);

    my (@replied, $err);
    eval { while (my ($req, $id) = $s->recv_wait(0.1)) { push @replied, [$req, $s->reply($id, "ok:$req")] } 1 }
        or $err = $@;
    is $err, undef, 'the server loop survives';
    is_deeply [map { $_->[1] ? 1 : 0 } @replied], [0, 1], 'reply is false for the bad id, true for the next';
    is $c->get($good), 'ok:innocent', 'the innocent request is still served';
};

subtest 'a stray shared-lock holder does not block attaching' => sub {
    my ($p) = fresh();
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) {
        open my $f, '<', $p or exit 1;
        flock $f, LOCK_SH or exit 1;
        close $r; syswrite $w, 'x'; sleep 30; exit 0;
    }
    close $w; sysread $r, my $go, 1;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "hung\n" };
        alarm 5;
        Data::ReqRep::Shared::Client->new($p);
        alarm 0;
        1;
    };
    alarm 0;
    ok $ok, 'a client attaches while another process holds a shared lock' or diag $@;
    kill TERM => $pid; waitpid $pid, 0;
};

subtest 'eventfd_set keeps its own descriptor' => sub {
    my ($p, $s) = fresh();
    my $fd = POSIX::open('/dev/null', O_RDONLY);
    $s->eventfd_set($fd);
    POSIX::close($fd);
    open my $mine, '<', $0 or die $!;
    is fileno($mine), $fd, 'an unrelated file now holds the same number';
    undef $s;
    ok defined(scalar <$mine>), 'destroying the handle leaves the caller\'s file alone';

    my (undef, $s2) = fresh();
    ok !eval { $s2->eventfd_set(9999); 1 }, 'a descriptor that is not open is refused';
    like $@, qr/eventfd_set/, '  and says so';
};

subtest 'a corrupt arena position fails closed instead of overwriting' => sub {
    my ($p, $s) = fresh();
    my $c = Data::ReqRep::Shared::Client->new($p);
    $c->send('QUEUED-REQUEST');
    poke($p, ARENA_WPOS, 0xFFFF_0000);
    ok !defined eval { $c->send('x' x 16) }, 'refused while a request is queued';
    my ($got) = $s->recv;
    is $got, 'QUEUED-REQUEST', 'the queued request is intact';
    poke($p, ARENA_WPOS, 0xFFFF_0000);
    ok defined $c->send('after'), 'recovers once the queue is empty';
};

subtest 'recv_wait_multi(0) takes nothing' => sub {
    my ($p, $s) = fresh();
    my $c = Data::ReqRep::Shared::Client->new($p);
    $c->send("m$_") for 1 .. 3;
    is scalar(my @a = $s->recv_multi(0)),           0, 'recv_multi(0) returns nothing';
    is scalar(my @b = $s->recv_wait_multi(0, 0.1)), 0, 'recv_wait_multi(0) returns nothing';
    is $s->size, 3, 'and neither dequeues';
};

subtest 'a lock word naming no process is recovered' => sub {
    my ($p) = fresh();
    poke($p, MUTEX, 0x8000_0000);
    # In a child: a send stuck in the lock loop never returns to Perl for alarm.
    my $pid = fork // die $!;
    if (!$pid) { POSIX::_exit(defined Data::ReqRep::Shared::Client->new($p)->send('after') ? 0 : 1) }
    my $done;
    for (1 .. 100) { last if $done = waitpid($pid, POSIX::WNOHANG()) > 0; select undef, undef, undef, 0.1 }
    unless ($done) { kill KILL => $pid; waitpid $pid, 0 }
    ok $done && $? == 0, 'a send gets through once the lock is recovered';
};

done_testing;
