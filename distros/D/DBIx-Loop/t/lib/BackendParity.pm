package BackendParity;

use 5.008003;
use strict;
use warnings;
use Test::More;

# The cross-backend parity body: the same assertions must hold whichever
# backend serves the queries (the worker pool over SQLite, or the native fd
# backend over Pg). Callers hand in a connected DBIx::Loop and its adapter,
# plus SQL dialect fragments where the engines differ.
#
#   BackendParity::run($db, $ad,
#       name        => 'pool/SQLite',
#       create      => 'CREATE TABLE p (id INTEGER PRIMARY KEY, name TEXT, n INTEGER)',
#       temp_create => '...',       # optional; skips insert-id test when absent
#   );

sub run {
    my ($db, $ad, %opt) = @_;
    my $name = $opt{name} || 'backend';

    my $await = sub { my $f = shift; $ad->await($f); return ($f->get)[0] };

    subtest "$name: backend parity" => sub {

        $await->($db->do($opt{create}
            || 'CREATE TABLE p (id INTEGER PRIMARY KEY, name TEXT, n INTEGER)'));

        # -- writes report rows_affected (and an insert id where meaningful) --
        my $w = $await->($db->do(
            "INSERT INTO p (id, name, n) VALUES (?,?,?)", 1, 'rex', 10));
        is($w->{rows_affected}, 1, 'insert: one row affected');

        # -- empty result set ---------------------------------------------------
        my $empty = $await->($db->query("SELECT id, name FROM p WHERE id = ?", 999));
        is_deeply($empty->{rows}, [], 'empty result: rows is an empty arrayref');
        is_deeply($empty->{columns}, ['id', 'name'], 'empty result: columns still named');

        # -- NULLs cross as undef ----------------------------------------------
        $await->($db->do("INSERT INTO p (id, name, n) VALUES (?,?,?)", 2, undef, undef));
        my $nulls = $await->($db->query("SELECT name, n FROM p WHERE id = ?", 2));
        is_deeply($nulls->{rows}[0], [undef, undef], 'NULL columns come back undef');

        # -- Unicode survives the round trip -----------------------------------
        my $uni = "sn\x{f8}man \x{2603}";
        $await->($db->do("INSERT INTO p (id, name, n) VALUES (?,?,?)", 3, $uni, 1));
        my $back = $await->($db->query("SELECT name FROM p WHERE id = ?", 3));
        is($back->{rows}[0][0], $uni, 'Unicode value round-trips');

        # -- a wide row ----------------------------------------------------------
        my $wide = $await->($db->query(
            "SELECT id, name, n, id+1, id+2, id+3, id+4, id+5, id+6, id+7 "
          . "FROM p WHERE id = 1"));
        is(scalar @{ $wide->{rows}[0] }, 10, 'ten columns cross intact');

        # -- a larger result set --------------------------------------------------
        {
            my @f;
            for my $i (100 .. 599) {
                push @f, $db->do("INSERT INTO p (id, name, n) VALUES (?,?,?)",
                                 $i, "row$i", $i);
            }
            $ad->await($_) for @f;
            my $big = $await->($db->query("SELECT id, name, n FROM p WHERE id >= 100 ORDER BY id"));
            is(scalar @{ $big->{rows} }, 500, '500-row result set crosses');
            is($big->{rows}[499][1], 'row599', 'last row intact');
        }

        # -- error shape ----------------------------------------------------------
        my $bad = $db->query("SELECT nope FROM table_that_is_not_there");
        $ad->await($bad);
        ok($bad->is_failed, 'bad SQL fails the future');
        ok(length($bad->failure), 'failure carries a message');
    };
}

1;
