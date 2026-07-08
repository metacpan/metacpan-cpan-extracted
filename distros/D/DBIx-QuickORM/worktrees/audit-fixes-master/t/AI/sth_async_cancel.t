use Test2::V0;

# Regression: DBIx::QuickORM::STH::Async::cancel() must not collect the result
# of the query it just cancelled. set_done() calls _fetch(), which used to run
# async_result (pg_result) on the cancelled query -- which croaks -- and would
# run on_ready (e.g. a write's cache-maintenance callback) for a query that
# never completed. cancel() now marks the fetch spent, mirroring Fork::cancel.

require DBIx::QuickORM::STH::Async;

# A Pg-shaped dialect: the query is never "ready", cancel succeeds, and
# async_result (pg_result) croaks if called after a cancel -- exactly the
# behavior that used to blow up out of cancel()/DESTROY.
{
    package t::AsyncDialect;
    sub new                    { bless {}, shift }
    sub async_cancel_supported { 1 }
    sub async_ready            { 0 }
    sub async_cancel           { $_[0]->{cancelled}++; 1 }
    sub async_result           { die "async_result (pg_result) called on a cancelled query\n" }
}
{
    package t::AsyncCon;
    sub new         { bless {dialect => t::AsyncDialect->new}, shift }
    sub dialect     { $_[0]->{dialect} }
    sub clear_async { }
}

my $con = t::AsyncCon->new;
my $ran_on_ready = 0;

my $sth = DBIx::QuickORM::STH::Async->new(
    connection => $con,
    source     => bless({}, 't::Src'),
    sth        => bless({}, 't::Sth'),
    dbh        => bless({}, 't::Dbh'),
    on_ready   => sub { $ran_on_ready++; return },
);

ok(lives { $sth->cancel }, "cancel() does not run async_result on the cancelled query")
    or diag($@);
ok($con->dialect->{cancelled}, "the in-flight query was actually cancelled");
is($ran_on_ready, 0, "on_ready did not run for the cancelled query");

done_testing;
