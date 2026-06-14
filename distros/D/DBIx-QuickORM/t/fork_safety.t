use Test2::V0 '!meta', '!pass';
use POSIX ();
use Atomic::Pipe;
use Cpanel::JSON::XS ();

# Exercises the forked statement handle's pipe protocol and process-ownership
# guard directly, without standing up a database. A real child process writes
# controlled envelope frames (or dies mid-stream) so we can assert how the
# parent handle distinguishes a clean end, a child-reported error, and a
# truncated stream, and that an inherited copy in another process is inert.

use DBIx::QuickORM::STH::Fork;

# Minimal stand-in for the owning connection. STH::Fork only calls clear_fork
# on us (via its clear()); record the calls so the ownership guard is testable.
package My::Mock::Connection {
    sub new { bless {cleared => []}, shift }
    sub clear_fork { push @{$_[0]->{cleared}} => $_[1]; return }
    sub cleared { $_[0]->{cleared} }
}

my $JSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);

# Fork a child that writes the given pre-encoded frames and then behaves per
# %opts: 'terminate' (default) closes the pipe cleanly, 'truncate' exits
# without closing politely (here just _exit, leaving no terminal frame).
sub fork_handle {
    my %params = @_;
    my $frames = $params{frames} // [];

    my ($rh, $wh) = Atomic::Pipe->pair(compression => 'zstd');
    my $pid = fork // die "fork failed: $!";

    unless ($pid) {    # child
        undef $rh;
        $wh->write_message($JSON->encode($_)) for @$frames;
        undef $wh;
        POSIX::_exit(0);
    }

    undef $wh;
    my $con = My::Mock::Connection->new;
    my $sth = DBIx::QuickORM::STH::Fork->new(
        connection => $con,
        source     => 'fake-source',
        pid        => $pid,
        pipe       => $rh,
    );

    return ($sth, $con);
}

subtest clean_stream => sub {
    my ($sth) = fork_handle(frames => [
        {result => 1},
        {row => {id => 1, name => 'a'}},
        {row => {id => 2, name => 'b'}},
        {done => 1},
    ]);

    is($sth->result, 1, "result frame decoded");
    is($sth->next, {id => 1, name => 'a'}, "first row");
    is($sth->next, {id => 2, name => 'b'}, "second row");
    is($sth->next, undef, "done frame ends the stream cleanly");
    ok($sth->done, "handle is finalized after a clean end");
};

subtest child_error_frame => sub {
    my ($sth) = fork_handle(frames => [
        {result => 1},
        {row => {id => 1}},
        {error => 'boom in the child'},
    ]);

    is($sth->result, 1, "result frame decoded");
    is($sth->next, {id => 1}, "row before the error");

    my $err = dies { $sth->next };
    like($err, qr/Forked query failed in the child process: boom in the child/, "child error surfaces with its message");
    ok($sth->done, "handle is finalized after a child error");
};

subtest error_before_result => sub {
    my ($sth) = fork_handle(frames => [
        {error => 'execute failed'},
    ]);

    my $err = dies { $sth->result };
    like($err, qr/Forked query failed in the child process: execute failed/, "error frame in place of the result surfaces");
    ok($sth->done, "handle is finalized");
};

subtest truncated_stream => sub {
    # Child sends a result and one row, then exits without a terminal frame.
    my ($sth) = fork_handle(frames => [
        {result => 1},
        {row => {id => 1}},
    ]);

    is($sth->result, 1, "result frame decoded");
    is($sth->next, {id => 1}, "the row that did arrive");

    my $err = dies { $sth->next };
    like($err, qr/truncated|before the child signalled completion/i, "EOF with no terminal frame is reported as truncation");
    ok($sth->done, "handle is finalized after truncation");
};

subtest ownership_guard => sub {
    # A handle owned by a different process (as if inherited across a fork)
    # must not reap the child or release the owner's fork slot.
    my ($rh, $wh) = Atomic::Pipe->pair(compression => 'zstd');
    my $pid = fork // die "fork failed: $!";
    unless ($pid) { undef $rh; undef $wh; POSIX::_exit(0) }
    undef $wh;

    my $con = My::Mock::Connection->new;
    my $sth = DBIx::QuickORM::STH::Fork->new(
        connection => $con,
        source     => 'fake-source',
        pid        => $pid,
        pipe       => $rh,
        owner_pid  => $pid + 1,    # pretend we are not the owner
    );

    ok(!$sth->in_owner_process, "not in the owning process");
    $sth->set_done;
    ok($sth->done, "set_done marks the inherited copy spent");
    is($con->cleared, [], "the owner's fork slot was not released by the inherited copy");

    # The real owner still has to reap the child; do it so the test is tidy.
    waitpid($pid, 0);
};

done_testing;
