#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# selectall_rowhash: every row as a hashref, in the order the server returned
# them - DBI's selectall_arrayref($sql, { Slice => {} }).
#
# selectall_hashref cannot stand in for it. Keying rows by a column destroys
# the ordering, which is exactly what keyset pagination depends on, so this is
# a missing member of the select* family rather than a convenience over one.

BEGIN {
    plan skip_all => 'DBI + DBD::SQLite required'
        unless eval { require DBI; require DBD::SQLite; 1 };
}

our $ADAPTER;
BEGIN {
    for my $try ([ 'IO::Async::Loop' => 'DBIx::Loop::Loop::IOAsync' ],
                 [ 'AnyEvent'        => 'DBIx::Loop::Loop::AnyEvent' ],
                 [ 'Mojo::IOLoop'    => 'DBIx::Loop::Loop::Mojo'     ]) {
        my ($loop, $adapter) = @$try;
        next unless eval "require $loop; require $adapter; 1";
        $ADAPTER = $adapter;
        last;
    }
    plan skip_all => 'no event loop available' unless $ADAPTER;
}

use DBIx::Loop;

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $ad  = $ADAPTER->new;
my $db  = DBIx::Loop->connect("dbi:SQLite:dbname=$dir/rh.db", '', '',
    { RaiseError => 1, PrintError => 0 }, loop => $ad, workers => 2);

sub await1 {
    my ($f) = @_;
    $ad->await($f);
    my ($r) = $f->get;
    return $r;
}

await1($db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT, n INTEGER)"));
await1($db->do("INSERT INTO t (id, v, n) VALUES (?, ?, ?)", @$_))
    for ([ 3, 'three', 30 ], [ 1, 'one', 10 ], [ 2, undef, 20 ]);

# ---- order is the query's, not a hash's -------------------------------------
{
    my $rows = await1($db->selectall_rowhash("SELECT id, v, n FROM t ORDER BY id"));
    is(ref $rows, 'ARRAY', 'selectall_rowhash returns an arrayref');
    is(scalar @$rows, 3, 'one entry per row');
    is(ref $rows->[0], 'HASH', 'each entry is a hashref');
    is_deeply([ map { $_->{id} } @$rows ], [ 1, 2, 3 ],
              'in the order the query asked for');

    my $desc = await1($db->selectall_rowhash("SELECT id FROM t ORDER BY id DESC"));
    is_deeply([ map { $_->{id} } @$desc ], [ 3, 2, 1 ],
              'and the reverse order is preserved too, so it is the rows and '
            . 'not an accident of hashing');
}

# ---- columns and values ------------------------------------------------------
{
    my $rows = await1($db->selectall_rowhash("SELECT id, v, n FROM t WHERE id = 1"));
    is_deeply($rows, [ { id => 1, v => 'one', n => 10 } ],
              'every selected column is a key');
}

# ---- a NULL column is an undef value, not a missing key ----------------------
{
    my $rows = await1($db->selectall_rowhash("SELECT id, v FROM t WHERE id = 2"));
    ok(exists $rows->[0]{v}, 'a NULL column is still present as a key');
    is($rows->[0]{v}, undef, 'with an undef value');
}

# ---- the empty result is an empty arrayref, not undef -----------------------
{
    my $rows = await1($db->selectall_rowhash("SELECT id FROM t WHERE id = 999"));
    is(ref $rows, 'ARRAY', 'no rows still returns an arrayref');
    is(scalar @$rows, 0, 'an empty one');
}

# ---- duplicate column names: last wins, as a hash must ----------------------
# Worth pinning rather than leaving to chance: a join that selects the same
# name twice silently loses one, and a caller should be able to rely on which.
{
    my $rows = await1($db->selectall_rowhash(
        "SELECT id AS c, v AS c FROM t WHERE id = 1"));
    is(scalar keys %{ $rows->[0] }, 1, 'a repeated column name collapses to one key');
    is($rows->[0]{c}, 'one', 'and the last one selected is the value kept');
}

# ---- binds work, and it composes like the rest of the family ----------------
{
    my $rows = await1($db->selectall_rowhash(
        "SELECT id, v FROM t WHERE id > ? ORDER BY id", 1));
    is_deeply([ map { $_->{id} } @$rows ], [ 2, 3 ], 'bind values are passed through');

    my $f = $db->selectall_rowhash("SELECT id FROM t ORDER BY id")
               ->then(sub { scalar @{ $_[0] } });
    $ad->await($f);
    is(($f->get)[0], 3, 'and the future chains like any other');
}

# ---- a failing query fails the future ---------------------------------------
{
    my $f = $db->selectall_rowhash("SELECT * FROM no_such_table");
    $ad->await($f);
    ok($f->is_failed, 'a bad query fails the future');
    like($f->failure, qr/no_such_table/, 'and the error names the table');
}

$db->disconnect;
done_testing;
