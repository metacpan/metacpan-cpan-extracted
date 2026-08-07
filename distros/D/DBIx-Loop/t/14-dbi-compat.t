#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# The DBI-compatible select* family: same shapes as DBI, wrapped in futures,
# running over the pool backend.

BEGIN {
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
    plan skip_all => 'DBD::SQLite required' unless eval { require DBD::SQLite; 1 };
}
use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $dir = File::Temp->newdir;
my $ad  = DBIx::Loop::Loop::IOAsync->new;
my $db  = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$dir/compat.db", '', '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad, workers => 2,
);

sub await1 { my $f = shift; $ad->await($f); return ($f->get)[0] }

await1($db->do("CREATE TABLE pets (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)"));
await1($db->do("INSERT INTO pets VALUES (?,?,?)", @$_))
    for [1, 'rex', 3], [2, 'milo', 5], [3, 'aria', 1];

is_deeply(await1($db->selectall_arrayref("SELECT id,name FROM pets ORDER BY id")),
    [[1,'rex'],[2,'milo'],[3,'aria']], 'selectall_arrayref');

is_deeply(await1($db->selectrow_arrayref("SELECT id,name FROM pets WHERE id=?", 2)),
    [2,'milo'], 'selectrow_arrayref');

{
    my $f = $db->selectrow_array("SELECT id,name FROM pets WHERE id=?", 3);
    $ad->await($f);
    is_deeply([$f->get], [3,'aria'], 'selectrow_array returns a list');
}

is_deeply(await1($db->selectrow_hashref("SELECT id,name,age FROM pets WHERE id=?", 1)),
    { id => 1, name => 'rex', age => 3 }, 'selectrow_hashref');

is(await1($db->selectrow_hashref("SELECT id FROM pets WHERE id=?", 99)),
    undef, 'selectrow_hashref: no row -> undef');

is_deeply(await1($db->selectcol_arrayref("SELECT name FROM pets ORDER BY id")),
    ['rex','milo','aria'], 'selectcol_arrayref');

is_deeply(await1($db->selectall_hashref("SELECT id,name FROM pets", 'id')),
    { 1 => {id=>1,name=>'rex'}, 2 => {id=>2,name=>'milo'}, 3 => {id=>3,name=>'aria'} },
    'selectall_hashref keyed by id');

# insert_id from do()
{
    my $w = await1($db->do("INSERT INTO pets (name,age) VALUES (?,?)", 'nyx', 2));
    is($w->{rows_affected}, 1, 'do: rows_affected');
    is($w->{insert_id}, 4, 'do: insert_id from last_insert_id');
}

# failures propagate through the mapped futures
{
    my $f = $db->selectall_arrayref("SELECT * FROM no_table");
    $ad->await($f);
    ok($f->is_failed, 'select* failure propagates');
}

# selectall_hashref's key checks. A missing key is caught before the query is
# sent, so it croaks; a key that names no column is only knowable once the
# columns come back, so it FAILS THE FUTURE rather than dying at settle time.
{
    eval { $db->selectall_hashref("SELECT id FROM pets") };
    like($@, qr/key field is required/, 'a missing key field croaks up front');

    my $f = $db->selectall_hashref("SELECT id,name FROM pets", 'nosuch');
    $ad->await($f);
    ok($f->is_failed, 'a key naming no column fails the future');
    like($f->failure, qr/no such column 'nosuch'/, '...and names the column');
}

$db->disconnect;
done_testing();
