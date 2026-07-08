use Test2::V0;
use POSIX qw/_exit/;

# Regression: DBIx::QuickORM::STH::Fork::ready() must detect a child that died
# before writing its result frame. Atomic::Pipe's read_message returns undef
# both for "no frame yet" and for EOF, so ready() used to return 0 forever once
# the child was gone, making Role::Async::wait() (and DESTROY, which polls it)
# spin/hang the parent forever.

BEGIN {
    skip_all "Atomic::Pipe is required for these tests"
        unless eval { require Atomic::Pipe; 1 };
}

require DBIx::QuickORM::STH::Fork;

# A connection stub: cancel()/set_done() only need clear_fork() to release the
# (non-existent) fork slot; ready() never touches the connection at all.
{
    package t::FakeCon;
    sub clear_fork { }
}

my ($rh, $wh) = Atomic::Pipe->pair;

my $pid = fork;
defined($pid) or skip_all "fork() is not available";
if (!$pid) {
    # Child: die immediately without ever writing a result frame. Exiting
    # closes its inherited pipe ends, so the parent's read end reaches EOF.
    undef $rh;
    undef $wh;
    _exit(9);
}

undef $wh;    # parent drops its own write end so the pipe can reach EOF

my $sth = DBIx::QuickORM::STH::Fork->new(
    pid        => $pid,
    pipe       => $rh,
    connection => bless({}, 't::FakeCon'),
    source     => bless({}, 't::FakeSource'),
);

my $ok = eval {
    local $SIG{ALRM} = sub { die "ready() never became true — spun on a dead child\n" };
    alarm 5;
    $sth->wait;    # sleep 0.1 until ready; hangs forever against the pre-fix code
    alarm 0;
    1;
};

ok($ok, "wait() returns once the dead child is detected") or diag($@);
ok($sth->ready, "ready() reports true for a child that died before writing a frame");

done_testing;
