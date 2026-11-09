use strict;
use warnings;
use Test::More;

# LIVE: the event loop stays free while a long statement is on its way
# (karr k91).
#
# WHY: t/17 proves statements on different connections run side by side, not
# that the transport itself leaves the loop alone. A transport that blocks in
# the call -- a sleep, a ->get on its own Future, a sync libpq call -- would
# still pass t/17 as long as the server side overlaps. What only a free loop
# does is let a timer of its own fire while pg_sleep(1) is outstanding, and
# let a short statement on a second connection finish and be handled before
# the long one. We assert that:
#
#   1. the statement ran: it took >= 1 s wall clock and came back;
#   2. an EV::timer every 50 ms ticked at least 15 times meanwhile (a free
#      loop gives ~20; a blocked one gives 0 until the statement is over);
#   3. a short statement issued after the long one, on a second connection,
#      completed before the long one did.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use Time::HiRes ();
use DBIO::PostgreSQL::EV::Storage;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;
$ci{pool_size} = 2;

# The file's backstop (karr k88).
alarm 120;

sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 30, "TIMEOUT awaiting $what\n");
}

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

# Two connections up and idle first, so the short statement does not spend
# its time on a connect.
await_guarded(
  Future->needs_all(map { $storage->_query_async('SELECT pg_sleep(0.1)', []) } 1 .. 2),
  'preheat 2 connections',
);
is $storage->pool->size, 2, 'two pooled connections';

my $ticks = 0;
my $timer = EV::timer 0.05, 0.05, sub { $ticks++ };

my $t0 = Time::HiRes::time;
my ($t_long, $t_short);
my $long  = $storage->_query_async('SELECT pg_sleep(1)', [])
  ->on_ready(sub { $t_long = Time::HiRes::time });
my $short = $storage->_query_async('SELECT 1', [])
  ->on_ready(sub { $t_short = Time::HiRes::time });

await_guarded(Future->needs_all($long, $short), 'long and short statement');
undef $timer;

ok !$long->is_failed,  'the long statement succeeded';
ok !$short->is_failed, 'the short statement succeeded';

cmp_ok $t_long - $t0, '>=', 0.95, 'the long statement really ran for about a second';
cmp_ok $ticks, '>=', 15,
  "the loop ticked while the statement was out ($ticks ticks of a 50 ms timer)";
ok defined $t_short && defined $t_long && $t_short < $t_long,
  'the short statement on the second connection finished before the long one';

done_testing;
