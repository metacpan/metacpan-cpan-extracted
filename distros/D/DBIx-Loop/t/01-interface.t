#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use DBIx::Loop;

# Phase 1: the public interface, the DBIx::Loop::Future primitive (C), the
# capability probe, and the synchronous stub backend. No real loop is driven
# yet - the stub settles inline - so a bare object stands in for the loop
# (real adapters arrive in phase 05).

my $LOOP = bless {}, 'DBIx::Loop::TestLoop';   # placeholder; not driven here

# ---- DBIx::Loop::Future contract ------------------------------------------------
{
    my $f = DBIx::Loop::Future->new;
    ok(!$f->is_ready,  'new future is pending');
    ok(!$f->is_done,   '... not done');
    ok(!$f->is_failed, '... not failed');

    my $seen;
    $f->on_ready(sub { $seen = $_[0]->get });   # registered while pending
    $f->done({ n => 42 });
    ok($f->is_ready && $f->is_done, 'done settles the future');
    is($seen->{n}, 42, 'on_ready fired with the result');

    my ($r) = $f->get;
    is($r->{n}, 42, 'get returns the result');

    # on_ready on an already-settled future fires immediately
    my $late;
    $f->on_ready(sub { $late = $_[0]->is_done });
    ok($late, 'on_ready on a settled future fires at once');

    # double-settle is refused
    eval { $f->done(1) };
    like($@, qr/already settled/, 'cannot settle twice');
}

# ---- failure path ---------------------------------------------------------------
{
    my $f = DBIx::Loop::Future->new;
    my $caught;
    $f->on_ready(sub { $caught = $_[0]->is_failed });
    $f->fail("boom\n");
    ok($f->is_failed, 'fail settles as failed');
    is($f->failure, "boom\n", 'failure() returns the error');
    ok($caught, 'on_ready saw the failure');
    eval { $f->get };
    is($@, "boom\n", 'get rethrows the failure');
}

# ---- then / else chaining -------------------------------------------------------
{
    my $f = DBIx::Loop::Future->new;
    my $g = $f->then(sub { my ($v) = @_; $v + 1 });
    $f->done(10);
    is(($g->get)[0], 11, 'then maps the value');

    # then flattens a returned future
    my $h = DBIx::Loop::Future->new;
    my $chained = $h->then(sub { my $inner = DBIx::Loop::Future->new; $inner->done("deep"); $inner });
    $h->done(1);
    is(($chained->get)[0], 'deep', 'then flattens a returned future');

    # else recovers from failure
    my $e = DBIx::Loop::Future->new;
    my $rec = $e->else(sub { "recovered" });
    $e->fail("nope\n");
    is(($rec->get)[0], 'recovered', 'else recovers a failure');

    # a callback that dies fails the next future with the message
    my $d = DBIx::Loop::Future->new;
    my $died = $d->then(sub { die "boom\n" });
    $d->done(1);
    ok($died->is_failed, 'a callback that dies fails the next future');
    like($died->failure, qr/boom/, '...carrying its message');

    # a failure with no on_fail passes straight through
    my $p = DBIx::Loop::Future->new;
    my $through = $p->then(sub { 'never runs' });
    $p->fail("upstream\n");
    like($through->failure, qr/upstream/, 'a failure passes through then');

    # then on an already-settled future runs at once
    my $s = DBIx::Loop::Future->new;
    $s->done(7);
    is(($s->then(sub { $_[0] + 1 })->get)[0], 8,
       'then on a settled future runs immediately');

    # the whole result list reaches the callback, and comes back out
    my $l = DBIx::Loop::Future->new;
    my $mapped = $l->then(sub { map { $_ * 2 } @_ });
    $l->done(1, 2, 3);
    is_deeply([ $mapped->get ], [ 2, 4, 6 ], 'then passes and returns lists');

    # a long chain settles iteratively enough not to blow up
    my $head = DBIx::Loop::Future->new;
    my $tail = $head;
    $tail = $tail->then(sub { $_[0] + 1 }) for 1 .. 2000;
    $head->done(0);
    is(($tail->get)[0], 2000, 'a 2000-link chain settles');

    # a pending future is not gettable
    eval { DBIx::Loop::Future->new->get };
    like($@, qr/not ready/, 'get on a pending future croaks');
}

# ---- capability probe -----------------------------------------------------------
is(DBIx::Loop::_capability('SQLite'),  'pool',   'SQLite -> pool');
is(DBIx::Loop::_capability('Pg'),      'native', 'Pg -> native');
is(DBIx::Loop::_capability('mysql'),   'native', 'mysql -> native');
is(DBIx::Loop::_capability('MariaDB'), 'native', 'MariaDB -> native');
is(DBIx::Loop::_capability('ODBC'),    'pool',   'unknown driver -> pool');

# ---- a loop is mandatory --------------------------------------------------------
{
    my $err;
    eval { DBIx::Loop->new(dbh => bless({}, 'FakeDBH')) } or $err = $@;
    like($err, qr/a 'loop' is required/, 'construction without a loop croaks');
}

# ---- the stub backend end to end (over SQLite) ----------------------------------
SKIP: {
    eval { require DBI; require DBD::SQLite; 1 } or skip 'DBD::SQLite needed', 6;

    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '',
        { RaiseError => 1, PrintError => 0 });
    my $db  = DBIx::Loop->new(dbh => $dbh, loop => $LOOP);

    is($db->capability, 'pool', 'a SQLite handle classifies as pool');
    isa_ok($db->loop, 'DBIx::Loop::TestLoop', 'loop stored');

    $db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)")->get;
    my $w = $db->do("INSERT INTO t (id,name) VALUES (?,?)", 1, 'rex')->get;
    is($w->{rows_affected}, 1, 'do returns rows_affected');

    my $f = $db->query("SELECT id,name FROM t WHERE id = ?", 1);
    isa_ok($f, 'DBIx::Loop::Future', 'query returns a future');
    my ($res) = $f->get;
    is_deeply($res->{rows}, [[1, 'rex']], 'query rows are arrayrefs');
    is_deeply($res->{columns}, ['id', 'name'], 'query returns column names');
}

done_testing();
