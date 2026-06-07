use strict;
use warnings;

use Test2::V0;
use Test2::Tools::QuickDB;

# Regression for the PostgreSQL SERIAL-jump corruption (the original FreeBSD
# smoke failure where a cloned row got id 34 instead of 2).
#
# When a source database is stopped and then cloned, the clone must continue the
# auto-increment sequence cleanly. On PostgreSQL a server that is shut down
# uncleanly leaves the data dir in crash-recovery state with the sequence
# pre-logged ahead by SEQ_LOG_VALS (32); cloning and starting that dir then runs
# recovery and the next value jumps forward. Driver::stop() forces a CHECKPOINT
# before shutting the server down to prevent this, so the clone's next id must be
# the plain next value.
#
# The broad t/Pool/postgresql.t tolerates non-deterministic ids for portability,
# so this is the explicit, exact-id regression.

my $db = get_db_or_skipall({driver => 'PostgreSQL'});

$db->start unless $db->started;

my $dbh = $db->connect('quickdb');
$dbh->do('CREATE TABLE seqtest (id SERIAL PRIMARY KEY, val TEXT)');
$dbh->do("INSERT INTO seqtest(val) VALUES('base')");
my ($base_id) = $dbh->selectrow_array("SELECT id FROM seqtest WHERE val = 'base'");
is($base_id, 1, "base row got id 1");
$dbh->disconnect;

# Stop through the normal Driver::stop() path (which checkpoints first), then
# clone the stopped source.
$db->stop;

my $clone = $db->clone(autostart => 1);

my $ch = $clone->connect('quickdb');
$ch->do("INSERT INTO seqtest(val) VALUES('clone')");
my ($clone_id) = $ch->selectrow_array("SELECT id FROM seqtest WHERE val = 'clone'");
is(
    $clone_id, 2,
    "cloned db continues the sequence at 2 (no SEQ_LOG_VALS +32 jump)"
);
$ch->disconnect;

$clone->stop;

done_testing;
