#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# dbil_abi v2: the statement observer. `start` fires before a statement runs,
# with the PREPARED sql and the bind COUNT; `done` fires exactly once when
# that statement's future settles, correlated by the token start returned.
#
# Registering a C callback is not something Perl can do, so this drives the
# selftest consumer in dbil_abi_impl.h and reads back what it saw.

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
    plan skip_all => 'Storable required' unless eval { require Storable; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

sub st { return DBIx::Loop::_abi_observer_state() }

my $dir  = File::Temp->newdir;
my $file = "$dir/obs.db";
my $ad   = DBIx::Loop::Loop::IOAsync->new;
my $db   = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$file", '', '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad, workers => 2,
);

sub await1 { my $f = shift; $ad->await($f); return ($f->get)[0] }

# ---- nothing registered -----------------------------------------------------
{
    is(DBIx::Loop::_abi_version(), 2, 'dbil_abi is at version 2');
    my ($starts) = st();
    is($starts, 0, 'no statement has been observed');
    await1($db->do('CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)'));
    my ($s2) = st();
    is($s2, 0, 'and a statement with no observer registered is still not');
}

# ---- register ---------------------------------------------------------------
is(DBIx::Loop::_abi_observer_install(), 1,
    'a C consumer registers a statement observer through the table');

# ---- a write ----------------------------------------------------------------
{
    my ($s0, $d0) = st();
    await1($db->do('INSERT INTO t (name) VALUES (?)', 'ada'));
    my ($s1, $d1, $ok, $err, $nbind, $is_query, $sql) = st();

    is($s1 - $s0, 1, 'one start for one statement');
    is($d1 - $d0, 1, 'one done for one start');
    is($nbind, 1, 'the bind COUNT is reported');
    is($is_query, 0, 'a write is not a query');
    is($sql, 'INSERT INTO t (name) VALUES (?)',
        'the observer sees the PREPARED sql, placeholder and all');
    unlike($sql, qr/ada/,
        'and never the bind value: the literal data does not reach an observer');
}

# ---- a read -----------------------------------------------------------------
{
    my ($s0, $d0, $ok0) = st();
    my $rows = await1($db->selectall_arrayref('SELECT name FROM t WHERE id = ?', 1));
    is($rows->[0][0], 'ada', 'the query returned its row');

    my ($s1, $d1, $ok1, $err1, $nbind, $is_query) = st();
    ok($s1 > $s0, 'the read was observed');
    is($d1 - $d0, $s1 - $s0, 'every start settled');
    is($is_query, 1, 'a read is a query');
    ok($ok1 > $ok0, 'and is reported as resolved');
    isnt($err1, -1, 'the token handed to done matched the one start returned');
}

# ---- a failure settles the observer too -------------------------------------
{
    my ($s0, $d0, $ok0, $err0) = st();
    my $r = eval { await1($db->do('INSERT INTO nosuchtable (x) VALUES (1)')) };
    ok(!defined $r || $@, 'a bad statement fails');

    my ($s1, $d1, $ok1, $err1) = st();
    is($s1 - $s0, 1, 'the failing statement was started');
    is($d1 - $d0, 1, 'and settled exactly once');
    is($err1 - $err0, 1, 'reported as a failure');
    is($ok1 - $ok0, 0, 'and not as a success');
}

# ---- the Perl door onto the same registry -----------------------------------
#
# DBIx::Loop->on_exec takes two coderefs and registers a pair of shims into the
# table the C consumer above is already in, so this also proves the two doors
# coexist: every statement below is seen by both.
#
# There is no deregistration - that is the contract, not an oversight - so the
# whole section shares ONE registration and steers it with package variables.

our (@START, @DONE, $DIE, $REENTER);

is(DBIx::Loop->on_exec(
    sub {
        my ($is_query, $sql, $nbind) = @_;
        die "start blew up\n" if $DIE;
        # the query log that writes to the database: the shape this hook will
        # be handed on day one, and an infinite regress without the guard
        $db->do('INSERT INTO t (name) VALUES (?)', 'from-observer')
            if $REENTER;
        push @START, { is_query => $is_query, sql => $sql, nbind => $nbind };
        return { sql => $sql, seq => scalar @START };   # the token: any scalar
    },
    sub {
        my ($token, $res, $err) = @_;
        die "done blew up\n" if $DIE;
        push @DONE, { token => $token,
                      ok    => (defined $err ? 0 : 1),
                      err   => (defined $err ? "$err" : undef) };
    },
), 1, 'a Perl consumer registers through DBIx::Loop->on_exec');

# a write: the prepared sql and the bind COUNT, never the values
{
    @START = (); @DONE = ();
    await1($db->do('INSERT INTO t (name) VALUES (?)', 'grace'));

    is(scalar @START, 1, 'start fired once');
    is($START[0]{sql}, 'INSERT INTO t (name) VALUES (?)',
        'with the PREPARED statement, placeholder and all');
    unlike($START[0]{sql}, qr/grace/,
        'and never the bind value, which is the literal data');
    is($START[0]{nbind}, 1, 'the bind count is reported instead');
    is($START[0]{is_query}, 0, 'a write is not a query');
    is(scalar @DONE, 1, 'done fired once');
    is($DONE[0]{ok}, 1, 'reported as resolved');
    is_deeply($DONE[0]{token},
        { sql => 'INSERT INTO t (name) VALUES (?)', seq => 1 },
        'the token round-trips as an arbitrary Perl scalar');
}

# a read, and both doors saw it
{
    my ($starts) = st();
    @START = (); @DONE = ();
    my $rows = await1($db->selectall_arrayref('SELECT name FROM t WHERE id = ?', 1));
    is($rows->[0][0], 'ada', 'the query returned its row');

    my ($starts2) = st();
    is($starts2 - $starts, 1, 'the C observer still fires');
    is(scalar @START, 1, 'and the Perl one fires for the same statement');
    is($START[0]{is_query}, 1, 'a read is a query');
    is(scalar @DONE, 1, 'and it settled');
}

# a failure reaches done with the error
{
    @START = (); @DONE = ();
    eval { await1($db->do('INSERT INTO nosuchtable (x) VALUES (1)')) };
    is(scalar @START, 1, 'the failing statement started');
    is(scalar @DONE,  1, 'and settled exactly once');
    is($DONE[0]{ok}, 0, 'reported as a failure');
    ok(length($DONE[0]{err} // ''), 'with the error in hand');
}

# An observer that queries the database would otherwise observe itself, for
# ever. The guard skips the callbacks for anything issued from inside one, so
# an observer cannot see its own queries - which is the only useful reading of
# what it should see anyway.
{
    @START = (); @DONE = ();
    local $REENTER = 1;
    await1($db->do('INSERT INTO t (name) VALUES (?)', 'hopper'));
    is(scalar @START, 1,
        'a statement issued from inside the observer is not itself observed');
    like($START[0]{sql}, qr/hopper|VALUES \(\?\)/,
        'only the outer statement was reported');
    my $rows = await1($db->selectall_arrayref(
        "SELECT COUNT(*) FROM t WHERE name = 'from-observer'"));
    ok($rows->[0][0] >= 1, 'and the inner statement really did run');

    # The skip has to be symmetric. A skipped start returns no token, and if
    # done fired anyway the inner statement would settle into a done with no
    # start behind it - one half of a pair, holding a token the callback was
    # never handed. That is what a NULL token could not distinguish from "the
    # callback ran and returned undef", which is why a skip has its own.
    @START = (); @DONE = ();
    await1($db->selectall_arrayref('SELECT COUNT(*) FROM t'));
    is(scalar @DONE, scalar @START,
        'every done has a start behind it, including after re-entrancy');
}

# An observer is a bystander: C can promise not to croak, Perl cannot, so a
# die is turned into a warning rather than being allowed to fail the statement
# it was only watching.
{
    my @warn;
    my $ok = do {
        # only THIS statement runs with a dying observer: the check below must
        # not be counted too, or the warning tally is measuring the test
        local $SIG{__WARN__} = sub { push @warn, "@_" };
        local $DIE = 1;
        eval { await1($db->do('INSERT INTO t (name) VALUES (?)', 'lovelace')); 1 };
    };
    ok($ok, 'a dying observer does not fail the statement');
    my $rows = await1($db->selectall_arrayref(
        "SELECT COUNT(*) FROM t WHERE name = 'lovelace'"));
    is($rows->[0][0], 1, 'which really did run');
    is(scalar(grep { /on_exec start callback died/ } @warn), 1,
        'the start death was warned');
    is(scalar(grep { /on_exec done callback died/ } @warn), 1,
        'and so was the done death');
}

# registration argument checking, in the caller's own frame
{
    my $err = '';
    eval { DBIx::Loop->on_exec('not a coderef') } or $err = $@;
    like($err, qr/start callback must be a code reference/,
        'a non-coderef start croaks at registration');
    $err = '';
    eval { DBIx::Loop->on_exec(sub { }, 'nope') } or $err = $@;
    like($err, qr/done callback must be a code reference/,
        'and so does a non-coderef done');
    is(DBIx::Loop->on_exec(sub { }), 1, 'the done callback is optional');
}

done_testing;
