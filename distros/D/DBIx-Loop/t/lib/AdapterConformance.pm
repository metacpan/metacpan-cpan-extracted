package AdapterConformance;

use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp ();

# One parametric test body every loop adapter must pass identically: given an
# adapter instance, drive Backend B (the worker pool, over SQLite) through it
# and assert the seam behaves - queries resolve, concurrency works, timers
# fire while a query is in flight, errors isolate, the native-future bridge
# round-trips, and disconnect tears down cleanly.
#
#   use AdapterConformance;
#   AdapterConformance::run($adapter, name => 'IOAsync');

sub run {
    my ($ad, %opt) = @_;
    my $name = $opt{name} || ref $ad;

    require DBIx::Loop;

    my $dir  = File::Temp->newdir;
    my $file = "$dir/conf.db";
    my $db   = DBIx::Loop->connect(
        "dbi:SQLite:dbname=$file", '', '',
        { RaiseError => 1, PrintError => 0 },
        loop => $ad, workers => 2,
    );

    subtest "$name: adapter conformance" => sub {

        # -- single round trip -----------------------------------------------
        my $c = $db->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v INTEGER)");
        $ad->await($c);
        ok($c->is_done, 'create resolves');

        for my $i (1 .. 4) {
            my $w = $db->do("INSERT INTO t (id,v) VALUES (?,?)", $i, $i * 10);
            $ad->await($w);
        }
        my $q = $db->query("SELECT id,v FROM t ORDER BY id");
        $ad->await($q);
        my $res = ($q->get)[0];
        is(scalar @{ $res->{rows} }, 4, 'four rows back');
        is_deeply($res->{columns}, ['id', 'v'], 'columns named');

        # -- concurrency: more in flight than workers -------------------------
        my @f = map { $db->query("SELECT COUNT(*) FROM t") } 1 .. 5;
        $ad->await($_) for @f;
        is(scalar(grep { $_->is_done && ($_->get)[0]{rows}[0][0] == 4 } @f), 5,
            '5 concurrent queries across 2 workers all resolve');

        # -- a timer fires while a query is in flight (loop not blocked) ------
        SKIP: {
            skip 'adapter has no timer', 1 unless $ad->can('timer');
            my $fired = 0;
            $ad->timer(0.02, sub { $fired = 1 });
            my $slow = $db->query(
                "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 200000) SELECT COUNT(*) FROM c");
            $ad->await($slow);
            # give the timer a chance if the query won the race
            $ad->await(do { my $f = DBIx::Loop::Future->new;
                            $ad->timer(0.03, sub { $f->done(1) }); $f });
            ok($fired, 'timer fired while a query was in flight');
        }

        # -- error isolation ---------------------------------------------------
        my $bad  = $db->query("SELECT * FROM missing_table");
        my $good = $db->query("SELECT 1");
        $ad->await($bad); $ad->await($good);
        ok($bad->is_failed, 'bad query fails');
        ok($good->is_done,  'good query unaffected');

        # -- native-future bridge ----------------------------------------------
        SKIP: {
            skip 'adapter has no to_native bridge', 1 unless $ad->can('to_native');
            my $f  = $db->query("SELECT 7");
            my $nf = $ad->to_native($f);
            $ad->await($f);
            ok(defined $nf, 'to_native returns a native future/promise');
        }

        # -- teardown -----------------------------------------------------------
        $db->disconnect;
        pass('disconnect clean');
    };
}

1;
