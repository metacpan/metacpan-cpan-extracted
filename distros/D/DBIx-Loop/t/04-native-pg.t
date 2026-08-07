#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

# Phase 3: the native fd-async backend (Backend A) over DBD::Pg. True
# single-threaded async: fire with {pg_async}, watch pg_socket on the loop,
# pg_ready/pg_result on readiness. One query in flight per connection; the
# rest FIFO-queue (the connection pool arrives in phase 04).
#
# Gated on a real Postgres:
#   DBIX_LOOP_PG_DSN='dbi:Pg:dbname=test;host=127.0.0.1' \
#   DBIX_LOOP_PG_USER=... DBIX_LOOP_PG_PASS=... prove t/03-native-pg.t

BEGIN {
    plan skip_all => 'set DBIX_LOOP_PG_DSN to run the Pg native tests'
        unless $ENV{DBIX_LOOP_PG_DSN};
    plan skip_all => 'DBD::Pg required' unless eval { require DBD::Pg; 1 };
    plan skip_all => 'IO::Async required' unless eval { require IO::Async::Loop; 1 };
}

use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $ad = DBIx::Loop::Loop::IOAsync->new;
my $db = DBIx::Loop->connect(
    $ENV{DBIX_LOOP_PG_DSN},
    $ENV{DBIX_LOOP_PG_USER} || '',
    $ENV{DBIX_LOOP_PG_PASS} || '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad,
);

is($db->capability, 'native', 'Pg with DBD::Pg loaded -> native backend');

sub await1 { my $f = shift; $ad->await($f); return ($f->get)[0] }

# ---- schema + round trip ---------------------------------------------------------
{
    my $r = await1($db->do("CREATE TEMPORARY TABLE dbil_t (id INT PRIMARY KEY, name TEXT)"));
    ok($r, 'create temp table');
    my $w = await1($db->do("INSERT INTO dbil_t (id,name) VALUES (?,?)", 1, 'rex'));
    is($w->{rows_affected}, 1, 'insert reports rows_affected');
    my $res = await1($db->query("SELECT id,name FROM dbil_t WHERE id = ?", 1));
    is_deeply($res->{rows}, [[1, 'rex']], 'row comes back as an arrayref');
    is_deeply($res->{columns}, ['id', 'name'], 'column names returned');
}

# ---- one in flight, the rest queue; all resolve in order ------------------------
{
    my @f = map { $db->query("SELECT ?::int AS n, pg_sleep(0.05)", $_) } 1 .. 4;
    $ad->await($_) for @f;
    my @n = map { ($_->get)[0]{rows}[0][0] } @f;
    is_deeply(\@n, [1, 2, 3, 4], '4 queries FIFO through one connection');
}

# ---- a genuinely async wait: the loop is free while Pg sleeps -------------------
{
    my $ticks = 0;
    my $timer_done = 0;
    $ad->timer(0.05, sub { $ticks++; $timer_done = 1 });
    my $f = $db->query("SELECT pg_sleep(0.3), 42 AS answer");
    $ad->await($f);
    is(($f->get)[0]{rows}[0][1], 42, 'slow query resolves');
    ok($timer_done, 'a loop timer fired while the query was in flight (loop not blocked)');
}

# ---- errors fail only their future ----------------------------------------------
{
    my $bad = $db->query("SELECT * FROM table_that_does_not_exist");
    my $good = $db->query("SELECT 7 AS ok");
    $ad->await($bad); $ad->await($good);
    ok($bad->is_failed, 'bad SQL -> failed future');
    like($bad->failure, qr/does not exist|relation/i, 'failure carries the Pg error');
    is(($good->get)[0]{rows}[0][0], 7, 'the queued query after it still succeeds');
}

$db->disconnect;
done_testing();
