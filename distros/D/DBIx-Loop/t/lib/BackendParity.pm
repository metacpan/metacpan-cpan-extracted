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
        #
        # The seed writes go one at a time, on purpose. Two pool workers are
        # two processes writing one SQLite file and SQLite serialises writers,
        # so fired off as a 500-deep burst they fight for the write lock; on a
        # loaded machine a starved writer sits out its whole busy timeout and
        # comes back "database is locked". Nothing here ever looked at the
        # write futures, so that arrived as a silent short row count (a CPAN
        # smoker reported 497). Nothing about crossing 500 rows needs
        # concurrent writers - the concurrent-work path is what the read burst
        # below, AdapterConformance and t/02-pool.t are for - and a failed
        # write is now a named failure rather than a missing row.
        {
            my ($written, $err) = (0, undef);
            for my $i (100 .. 599) {
                my $f = $db->do("INSERT INTO p (id, name, n) VALUES (?,?,?)",
                                $i, "row$i", $i);
                $ad->await($f);
                if ($f->is_failed) { $err ||= "row $i: " . $f->failure; next }
                $written++;
            }
            is($written, 500, '500 rows written') or diag($err);

            my @q = map { $db->query(
                "SELECT id, name, n FROM p WHERE id >= 100 ORDER BY id") } 1 .. 3;
            $ad->await($_) for @q;
            is(scalar(grep { $_->is_done } @q), 3,
                'three concurrent 500-row reads all resolve')
                or diag(join '', map { $_->is_failed ? $_->failure : () } @q);
            my $big = $q[0]->is_done ? ($q[0]->get)[0] : { rows => [] };
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
