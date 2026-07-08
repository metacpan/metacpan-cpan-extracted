use Test2::V0;
use POSIX qw/_exit/;

# Regression: an async/aside statement handle inherited by a forked child
# shares the owner's driver socket. If the child's global destruction runs the
# normal DESTROY (cancel/wait/fetch), it corrupts the owner's connection. A
# non-owner process must touch nothing on destruction.

require DBIx::QuickORM::STH::Async;

{
    package t::AsyncDialect;
    sub new                    { bless {}, shift }
    sub async_cancel_supported { 1 }
    sub async_ready            { 0 }
    sub async_cancel           { $_[0]->{touched}++; 1 }
    sub async_result           { $_[0]->{touched}++; die "async_result touched the shared socket\n" }
}
{
    package t::AsyncCon;
    sub new         { bless {dialect => t::AsyncDialect->new}, shift }
    sub dialect     { $_[0]->{dialect} }
    sub clear_async { }
}

my $con = t::AsyncCon->new;
my $sth = DBIx::QuickORM::STH::Async->new(
    connection => $con,
    source     => bless({}, 't::Src'),
    sth        => bless({}, 't::Sth'),
    dbh        => bless({}, 't::Dbh'),
);

my $pid = fork;
defined($pid) or skip_all "fork() is not available";
if (!$pid) {
    # Child: the inherited handle is not ours. Destroying it must not touch the
    # driver (no cancel/result). Exit 0 only if the driver was left untouched.
    undef $sth;    # trigger DESTROY in the child
    _exit($con->dialect->{touched} ? 1 : 0);
}

waitpid($pid, 0);
is($? >> 8, 0, "a forked child's handle destruction leaves the shared driver untouched");

# The owner can still finalize its own handle (cancel is allowed here).
ok(lives { undef $sth }, "the owner can still destroy its own handle");

done_testing;
