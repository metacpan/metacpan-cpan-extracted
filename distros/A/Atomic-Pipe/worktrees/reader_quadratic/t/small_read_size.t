use Test2::V0;
use Test2::Util qw/CAN_REALLY_FORK/;
use Atomic::Pipe;
use POSIX ();

# A read_size smaller than a message part must not make a blocking
# read_message() return undef (which looks like EOF) in the middle of the
# stream; it has to keep reading until the part is complete.
#
# The writer runs in a child: the stream is bigger than some platforms' pipe
# buffers, so writing it all before reading would deadlock.
skip_all "This test needs a real fork()" unless CAN_REALLY_FORK;

my @MSGS = (('x' x 100) x 3, 'y' x 9000);

for my $rs (1, 5, 17, 100, 4096) {
    my ($r, $w) = Atomic::Pipe->pair;
    $r->read_size($rs);

    my $pid = fork // die "fork: $!";
    unless ($pid) {
        $r->close;
        $w->write_message($_) for @MSGS;
        $w->close;
        POSIX::_exit(0);
    }
    $w->close;

    my @got;
    while (defined(my $m = $r->read_message)) { push @got => $m }
    waitpid($pid, 0);

    is(\@got, \@MSGS, "read_size $rs: every message, nothing cut short");
    ok($r->eof, "read_size $rs: undef only at real EOF");
}

done_testing;
