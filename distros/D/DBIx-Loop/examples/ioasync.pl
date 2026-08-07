#!/usr/bin/env perl
use strict;
use warnings;

# DBIx::Loop on IO::Async: three CPU-heavy queries overlap on the worker pool
# while a loop timer keeps ticking - the loop is never blocked.
#
#   perl examples/ioasync.pl

use File::Temp ();
use DBIx::Loop;
use DBIx::Loop::Loop::IOAsync;

my $dir = File::Temp->newdir;
my $ad  = DBIx::Loop::Loop::IOAsync->new;
my $db  = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$dir/demo.db", '', '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad, workers => 3,
);

my $SLOW = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 1000000) SELECT COUNT(*) FROM c";

$ad->timer($_ / 50, sub { print "  tick (loop is live)\n" }) for 1 .. 3;

print "firing 3 slow queries across 3 workers...\n";
my @f = map {
    my $n = $_;
    $db->query($SLOW)->then(sub { print "  query $n done\n"; 1 });
} 1 .. 3;
$ad->await($_) for @f;

# a transaction, pinned to one connection
my $t = $db->txn(sub {
    my ($tx) = @_;
    $tx->do("CREATE TABLE pets (id INTEGER PRIMARY KEY, name TEXT)")
       ->then(sub { $tx->do("INSERT INTO pets (name) VALUES (?)", 'rex') })
       ->then(sub { $tx->query("SELECT COUNT(*) FROM pets") });
});
$ad->await($t);
printf "txn committed; pets = %d\n", (($t->get)[0])->{rows}[0][0];

$db->disconnect;
