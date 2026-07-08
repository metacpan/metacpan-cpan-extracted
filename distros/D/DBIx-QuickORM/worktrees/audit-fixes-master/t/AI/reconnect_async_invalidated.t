use Test2::V0;
use DBIx::QuickORM::STH::Async;

# A driver-level async query runs on the connection's shared database handle. If
# the connection reconnects (or disconnects) before the result is collected, the
# handle is closed and the query can never complete. reconnect() marks such a
# surviving handle invalidated; using it must then give a clear error instead of
# a raw driver failure, and finalizing it (explicitly or at destruction) must not
# touch the dead driver handle. These are unit tests with a fake dialect whose
# async_* methods die if reached, so they need no real async-capable driver.

{
    package Fake::Dialect;
    sub new { bless {}, shift }
    sub async_ready            { die "async_ready called on an invalidated handle\n" }
    sub async_result           { die "async_result called on an invalidated handle\n" }
    sub async_cancel           { die "async_cancel called on an invalidated handle\n" }
    sub async_cancel_supported { 1 }
}

{
    package Fake::Con;
    sub new         { bless {cleared => 0}, shift }
    sub clear_async { $_[0]->{cleared}++ }
    sub dialect     { Fake::Dialect->new }
}

my $make = sub {
    my $con = Fake::Con->new;
    my $sth = DBIx::QuickORM::STH::Async->new(
        connection => $con,
        source     => bless({}, 'Fake::Source'),
        dbh        => bless({}, 'Fake::DBH'),
        sth        => bless({}, 'Fake::STH'),
        dialect    => Fake::Dialect->new,
        sql        => 'SELECT 1',
        owner_pid  => $$,
    );
    return ($sth, $con);
};

subtest use_after_invalidate_croaks => sub {
    my ($sth) = $make->();
    $sth->mark_invalidated;
    ok($sth->invalidated, "handle reports it was invalidated");

    like(
        dies { $sth->ready },
        qr/invalidated by a database reconnect and can no longer be used/,
        "ready() croaks with a clear message instead of hitting the dead driver",
    );
    like(
        dies { $sth->result },
        qr/invalidated by a database reconnect and can no longer be used/,
        "result() croaks with a clear message instead of hitting the dead driver",
    );

    # Finalize so this handle does not do work when it leaves scope.
    ok(lives { $sth->finalize_invalidated }, "finalize is clean");
};

subtest finalize_is_clean => sub {
    my ($sth, $con) = $make->();
    $sth->mark_invalidated;

    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    ok(lives { $sth->finalize_invalidated }, "finalize_invalidated does not touch the dead driver");
    ok($sth->done, "handle is marked done");
    is($con->{cleared}, 1, "the async slot was released on the connection");
    is(\@warns, [], "no warnings emitted");
};

subtest destroy_is_clean => sub {
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };

    my $con;
    {
        my $sth;
        ($sth, $con) = $make->();
        $sth->mark_invalidated;
        # $sth leaves scope here: DESTROY must finalize without reading or
        # cancelling the dead driver, and without warning.
    }

    is($con->{cleared}, 1, "DESTROY of an invalidated handle released the async slot");
    is(\@warns, [], "DESTROY of an invalidated handle is silent");
};

done_testing;
