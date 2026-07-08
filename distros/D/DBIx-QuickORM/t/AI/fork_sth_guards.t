use Test2::V0 '!meta', '!pass';
use POSIX ();
use Atomic::Pipe;
use Cpanel::JSON::XS ();

# Two forked-statement-handle safety behaviors, exercised directly against the
# pipe protocol (no database):
#
#   * A handle read from a process other than the one that created it must
#     croak rather than steal frames off the pipe the owner is draining.
#   * A forked write whose child errors must not throw out of its destructor;
#     the destructor drains to the terminal frame and warns instead.

use DBIx::QuickORM::STH::Fork;

package My::Mock::Connection {
    sub new { bless {cleared => []}, shift }
    sub clear_fork { push @{$_[0]->{cleared}} => $_[1]; return }
    sub cleared { $_[0]->{cleared} }
}

my $JSON = Cpanel::JSON::XS->new->utf8(1)->convert_blessed(1)->allow_nonref(1);

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
        %{$params{extra} // {}},
    );

    return ($sth, $con, $pid);
}

subtest read_from_non_owner_process_croaks => sub {
    # owner_pid is stamped to a different pid, as if an inherited copy in a
    # forked child were being read. Every read path funnels through
    # _read_message, so ready/result/next must all refuse.
    my ($sth, undef, $pid) = fork_handle(
        frames => [{result => 1}, {row => {id => 1}}, {done => 1}],
        extra  => {owner_pid => $$ + 1},
    );

    ok(!$sth->in_owner_process, "handle reports it is not in the owning process");

    like(dies { $sth->ready },  qr/different process than the one that created it/, "ready croaks in a non-owner process");
    like(dies { $sth->result }, qr/different process than the one that created it/, "result croaks in a non-owner process");
    like(dies { $sth->next },   qr/different process than the one that created it/, "next croaks in a non-owner process");

    # The guard blocked all reads, so nothing reaped the child. Do it here.
    waitpid($pid, 0);
};

subtest forked_write_child_error_does_not_throw_from_destructor => sub {
    # A forked write sets on_finish, which makes cancel_on_destroy false: the
    # destructor must run the child to completion rather than cancel it. When
    # the child errored, draining must warn, not croak out of DESTROY.
    my $on_finish_ran = 0;

    my ($sth) = fork_handle(
        frames => [{error => 'write blew up in the child'}],
        extra  => {on_finish => sub { $on_finish_ran++ }},
    );

    ok(!$sth->cancel_on_destroy, "a handle with on_finish waits rather than cancels on destroy");

    my @warns;
    {
        local $SIG{__WARN__} = sub { push @warns => $_[0] };
        undef $sth;    # drive DESTROY
    }

    ok(!(grep { /failed in the child process/ } @warns), "no in-cleanup exception leaked from the destructor")
        or diag(explain(\@warns));
    ok(scalar(grep { /did not complete cleanly/ } @warns), "the unclean-completion warning was emitted");
    is($on_finish_ran, 0, "on_finish did not run for an unclean child");
};

done_testing;
