use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";

use DBIO::MySQL::NotifyTable;
use FakeNotifyServer;

# UNIT test of DBIO::MySQL::NotifyTable (karr k54, this dist's ADR 0008): the
# sans-I/O half of the emulated LISTEN/NOTIFY that both MySQL transports share
# (future_io here, ev in dbio-mysql-ev). No DBI, no loop: the statements the
# class builds are answered by t/lib/FakeNotifyServer.pm, an in-memory model of
# the table with insert-time ids, commit-time visibility, a settable server
# clock and utf8mb4_bin's PAD SPACE comparison. This file pins the delivery
# semantics the ADR promises -- no history, delivery on commit, exactly once,
# the out-of-order commit caught within the lookback, and the one documented
# limit -- plus validation, the bind-only statements and the cleanup pacing.

# A listener driven by hand: subscribe / poll / cleanup against the model.
sub listener {
  my ($server, %cfg) = @_;
  return DBIO::MySQL::NotifyTable->new(%cfg);
}

sub subscribe {
  my ($nt, $server, $channel) = @_;
  my ($sql, $bind) = $nt->subscribe_sql($channel);
  $nt->subscribed($channel, $server->answer($sql, $bind)->{rows});
  return;
}

sub poll {
  my ($nt, $server) = @_;
  my ($sql, $bind, $token) = $nt->poll_sql or return [];
  return $nt->polled($token, $server->answer($sql, $bind)->{rows});
}

sub payloads { [ map { $_->[1] } @{ $_[0] } ] }

# ---------------------------------------------------------------------------
# 1. Configuration is validated up front. The table name is interpolated into
#    every statement, so it must be a plain identifier -- ADR 0017 section 3's
#    validate-or-escape at the boundary -- and the timing knobs must be able to
#    keep their promise: a retention that is not longer than lookback plus poll
#    interval would delete a late-committing notification before the poll that
#    is supposed to catch it.
# ---------------------------------------------------------------------------

{
  my %d = DBIO::MySQL::NotifyTable->defaults;
  is_deeply \%d,
    { table => 'dbio_notify', poll_interval => 1, lookback => 60, retention => 3600, cleanup_limit => 1000 },
    'defaults: dbio_notify, 1 s poll, 60 s lookback, 1 h retention, 1000-row cleanup batches';

  my $nt = DBIO::MySQL::NotifyTable->new;
  is $nt->$_, $d{$_}, "new() without arguments uses the default $_" for sort keys %d;
  is $nt->quoted_table, '`dbio_notify`', 'the table name is backtick-quoted';

  ok eval { DBIO::MySQL::NotifyTable->new(table => 'x' x 64); 1 }, 'a 64-character table name is accepted';
  ok eval { DBIO::MySQL::NotifyTable->new(table => '_Notify_2'); 1 }, 'letters, digits and _ are accepted';
  for my $bad ('x' x 65, 'bad name', 'no`tick', '1abc', 'db.table', "t\n", '', [ 'x' ]) {
    my $what = ref $bad ? 'a reference' : "'$bad'";
    $what =~ s/\n/\\n/;
    throws_ok { DBIO::MySQL::NotifyTable->new(table => $bad) } qr/not a plain identifier/,
      "table name $what is refused";
  }

  throws_ok { DBIO::MySQL::NotifyTable->new(poll_interval => 0) } qr/poll_interval must be a positive/,
    'poll_interval 0 is refused (the watch loop would spin)';
  throws_ok { DBIO::MySQL::NotifyTable->new(lookback => -1) } qr/lookback must be a positive/,
    'a negative lookback is refused';
  throws_ok { DBIO::MySQL::NotifyTable->new(lookback => 'soon') } qr/lookback must be a positive/,
    'a non-numeric lookback is refused';
  throws_ok { DBIO::MySQL::NotifyTable->new(retention => -5) } qr/retention must be 0/,
    'a negative retention is refused';
  throws_ok { DBIO::MySQL::NotifyTable->new(lookback => 60, poll_interval => 1, retention => 61) }
    qr/retention \(61 s\) must be greater than lookback plus poll interval \(61 s\)/,
    'a retention not above lookback + poll interval is refused, naming both';
  ok eval { DBIO::MySQL::NotifyTable->new(retention => 0); 1 }, 'retention 0 (cleanup off) is accepted';
  throws_ok { DBIO::MySQL::NotifyTable->new(cleanup_limit => 1.5) } qr/cleanup_limit must be a positive integer/,
    'a fractional cleanup_limit is refused (it is interpolated into LIMIT)';
  throws_ok { DBIO::MySQL::NotifyTable->new(poll_intervall => 2) } qr/unknown notify table setting\(s\): poll_intervall/,
    'a misspelt setting is refused rather than ignored';
}

# ---------------------------------------------------------------------------
# 2. The statements. Channel and payload travel only as bind values -- never
#    in the SQL text (ADR 0017 section 3, restated by core ADR 0056). A channel
#    or payload that does not fit its column is refused before any statement
#    exists: under a non-strict sql_mode the server would silently truncate it,
#    and a truncated channel never matches the name it was sent under.
# ---------------------------------------------------------------------------

{
  my $nt   = DBIO::MySQL::NotifyTable->new;
  my $evil = q{x'); DROP TABLE t; -- `};
  my ($sql, $bind) = $nt->notify_sql($evil, $evil);
  is $sql, 'INSERT INTO `dbio_notify` (`channel`, `payload`, `pid`, `created_at`) '
         . 'VALUES (?, ?, CONNECTION_ID(), UTC_TIMESTAMP(6))',
    'notify is a fixed INSERT: sender CONNECTION_ID(), time UTC_TIMESTAMP(6)';
  is_deeply $bind, [ $evil, $evil ], '... channel and payload only as binds';

  (undef, $bind) = $nt->notify_sql('jobs');
  is_deeply $bind, [ 'jobs', '' ], 'an undef payload is sent as the empty string (PostgreSQL has no NULL payload)';

  ($sql, $bind) = $nt->subscribe_sql($evil);
  unlike $sql, qr/DROP TABLE/, 'subscribe SQL carries no channel text';
  is_deeply $bind, [ $evil, $evil ], '... the channel is bound (twice: rows and mark)';

  subscribe($nt, FakeNotifyServer->new, $evil);
  ($sql, $bind) = $nt->poll_sql;
  unlike $sql, qr/DROP TABLE/, 'poll SQL carries no channel text';
  is $bind->[0], $evil, '... the channel is bound';

  ok eval { $nt->notify_sql('c' x 255, 'p'); 1 }, 'a 255-character channel fits the column';
  throws_ok { $nt->notify_sql('c' x 256, 'p') } qr/256 characters long.*at most 255.*refused rather than truncated/,
    'a 256-character channel is refused, not truncated';
  throws_ok { $nt->subscribe_sql('c' x 256) } qr/refused rather than truncated/, '... for subscribe too';
  throws_ok { $nt->notify_sql($_, 'p') } qr/non-empty string/, 'channel ' . (defined $_ ? "'$_'" : 'undef') . ' is refused'
    for undef, '';
  throws_ok { $nt->notify_sql([ 'x' ], 'p') } qr/non-empty string/, 'a reference channel is refused';

  ok eval { $nt->notify_sql(c => 'p' x 65535); 1 }, 'a 65535-byte payload fits TEXT';
  throws_ok { $nt->notify_sql(c => 'p' x 65536) } qr/65536 bytes long.*refused rather than truncated/,
    'a 65536-byte payload is refused';
  throws_ok { $nt->notify_sql(c => "\x{20ac}" x 21846) } qr/65538 bytes long/,
    '... counted in UTF-8 bytes, not characters (21846 x U+20AC = 65538 bytes)';

  like $nt->create_table_sql, qr/\ACREATE TABLE IF NOT EXISTS `dbio_notify` \(/,
    'the DDL is CREATE TABLE IF NOT EXISTS on the quoted name';
  like $nt->create_table_sql, qr/`channel`\s+VARCHAR\(255\) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL/,
    '... channel compares case-sensitively (utf8mb4_bin), 255 characters';
  like $nt->create_table_sql, qr/`created_at` DATETIME\(6\) NOT NULL/,
    '... created_at is DATETIME(6), not TIMESTAMP: no session time_zone conversion';
  like $nt->create_table_sql, qr/ENGINE=InnoDB/, '... InnoDB';
  is $nt->drop_table_sql, 'DROP TABLE IF EXISTS `dbio_notify`', 'drop_table_sql';
}

# ---------------------------------------------------------------------------
# 3. No history: the mark taken at subscribe hides everything already
#    visible, and what is committed afterwards arrives -- in id order, in the
#    contract order ($channel, $payload, $sender_pid). A listener that replayed
#    history would fire every callback for old events on each start.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s);
  $s->insert(jobs => "old$_") for 1 .. 3;
  subscribe($nt, $s, 'jobs');

  is_deeply poll($nt, $s), [], 'nothing already visible at subscribe is delivered';

  $s->insert(jobs => 'new1', pid => 41);
  $s->insert(jobs => 'new2', pid => 42);
  is_deeply poll($nt, $s), [ [ 'jobs', 'new1', 41 ], [ 'jobs', 'new2', 42 ] ],
    'what was committed after it arrives, in id order, as [$channel, $payload, $sender_pid]';
  is_deeply poll($nt, $s), [], '... once';
}

# ---------------------------------------------------------------------------
# 4. THE OUT-OF-ORDER COMMIT. AUTO_INCREMENT ids are handed out at INSERT,
#    rows become visible at COMMIT: A takes id 10, B takes 11 and commits
#    first. A naive "id > mark" poll moves the mark past 10 and loses A for
#    good. The lookback window must deliver A when it commits -- exactly once,
#    never B twice.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s);
  subscribe($nt, $s, 'jobs');
  $s->insert(filler => $_) for 1 .. 9;   # ids 1 .. 9 on another channel

  my $id_a = $s->insert(jobs => 'A', visible => 0);
  my $id_b = $s->insert(jobs => 'B', visible => 0);
  is_deeply [ $id_a, $id_b ], [ 10, 11 ], 'A took id 10, B took id 11';

  $s->commit($id_b);
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['B'], 'B committed first and is delivered';

  $s->advance(5);
  $s->commit($id_a);
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['A'], 'A, the lower id committed later, is delivered too';

  my @more = map { $s->advance(1); @{ poll($nt, $s) } } 1 .. 5;
  is_deeply \@more, [], 'and neither is delivered again on the following polls';

  # A poll's window is bounded by the cutoff its channel's PREVIOUS poll
  # brought back -- the lag that makes the guarantee independent of the poll
  # interval -- so the ids leave the remembered set one poll after the window
  # has moved past them.
  $s->advance(120);
  is_deeply [ @{ poll($nt, $s) }, @{ poll($nt, $s) } ], [],
    'nor once they have left the lookback window';
  is scalar(keys %{ $nt->{channels}{jobs}{seen} }), 0,
    'the remembered ids shrink with the window -- the dedup memory is bounded by it';
}

# ---------------------------------------------------------------------------
# 5. In flight at LISTEN time. A notification INSERTed before the listener
#    subscribed but committed after it is delivered, as PostgreSQL delivers a
#    NOTIFY at commit to whoever listens then. The mark is a plain MAX(id), so
#    this is the out-of-order hole at the mark itself.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s);
  my $early = $s->insert(jobs => 'open-at-listen', visible => 0);
  $s->insert(jobs => 'committed-before-listen');   # a higher id, visible: the mark
  subscribe($nt, $s, 'jobs');
  is $nt->{channels}{jobs}{mark}, 2, 'the mark is past the open transaction\'s id';

  $s->advance(2);
  $s->commit($early);
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['open-at-listen'],
    'the notification open at subscribe is delivered when it commits; the committed one is history';
}

# ---------------------------------------------------------------------------
# 6. The documented limit, pinned so that a change in it is a visible
#    decision: a transaction that commits more than the lookback after its
#    INSERT, after a later notification on the same channel was delivered, is
#    lost. Without a later delivered notification it is not lost, however long
#    it took -- the id is above the mark.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s, lookback => 10, poll_interval => 1, retention => 3600);
  subscribe($nt, $s, 'jobs');

  my $slow = $s->insert(jobs => 'slow', visible => 0);
  $s->insert(jobs => 'fast');
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['fast'], 'the later notification is delivered first';
  $s->advance(11);
  poll($nt, $s);
  $s->commit($slow);   # 12 s after its INSERT, lookback 10
  $s->advance(1);
  is_deeply poll($nt, $s), [], 'LIMIT: committed after the lookback, behind a delivered later id -> lost';

  my $s2  = FakeNotifyServer->new;
  my $nt2 = listener($s2, lookback => 10, poll_interval => 1, retention => 3600);
  subscribe($nt2, $s2, 'jobs');
  my $long = $s2->insert(jobs => 'long', visible => 0);
  for (1 .. 30) { $s2->advance(1); poll($nt2, $s2) }
  $s2->commit($long);   # 30 s after its INSERT, nothing later delivered
  $s2->advance(1);
  is_deeply payloads(poll($nt2, $s2)), ['long'],
    'but a long transaction with nothing later delivered on its channel still arrives';

  my $s3  = FakeNotifyServer->new;
  my $nt3 = listener($s3, lookback => 10, poll_interval => 1, retention => 3600);
  subscribe($nt3, $s3, 'jobs');
  my $late = $s3->insert(jobs => 'late', visible => 0);
  $s3->insert(jobs => 'first');
  $s3->advance(1);
  poll($nt3, $s3);
  $s3->advance(8);
  $s3->commit($late);   # 9 s after its INSERT: within the lookback
  $s3->advance(1);
  is_deeply payloads(poll($nt3, $s3)), ['late'], 'and one that commits within the lookback is delivered';
}

# ---------------------------------------------------------------------------
# 7. Channels are independent. Each keeps its own mark and cutoff: taking the
#    mark of a new channel -- whose cutoff is "now minus lookback" -- must not
#    move an existing channel's window forward past a notification that is
#    about to commit. Here channel A's polling stalls; B subscribes after A's
#    late notification committed; A's next poll must still find it.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s, lookback => 10, poll_interval => 1, retention => 3600);
  subscribe($nt, $s, 'a');
  my $late = $s->insert(a => 'late-a', visible => 0);   # t = 0
  $s->insert(a => 'first-a');
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['first-a'], 'a later notification on A is delivered';
  $s->advance(8);
  $s->commit($late);    # t = 9: within A's lookback
  $s->advance(5);       # A's polling stalls
  subscribe($nt, $s, 'b');   # t = 14: B's own cutoff is t = 4, past late-a's INSERT
  is_deeply payloads(poll($nt, $s)), ['late-a'],
    'A still delivers its late commit: B\'s mark did not move A\'s window';

  $s->insert(b => 'b1');
  $s->insert(a => 'a2');
  $s->insert(b => 'b2');
  is_deeply poll($nt, $s), [ [ 'b', 'b1', 777 ], [ 'a', 'a2', 777 ], [ 'b', 'b2', 777 ] ],
    'two channels on one poll, interleaved in id order';
}

# ---------------------------------------------------------------------------
# 8. Exact channel names. The column's utf8mb4_bin collation pads trailing
#    spaces, so SQL returns 'jobs ' rows to a 'jobs' poll; core's registry is
#    exact, and so must the match be. Case already differs in SQL.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s);
  subscribe($nt, $s, 'jobs');
  $s->insert('jobs '  => 'trailing');
  $s->insert('Jobs'   => 'upper');
  $s->insert(jobs     => 'exact');
  my ($sql, $bind, $token) = $nt->poll_sql;
  my $rows = $s->answer($sql, $bind)->{rows};
  ok scalar(grep { defined $_->[1] && $_->[1] eq 'jobs ' } @$rows),
    'precondition: the server returns the padded channel\'s row to the poll';
  is_deeply $nt->polled($token, $rows), [ [ 'jobs', 'exact', 777 ] ],
    'only the exact channel is delivered';
}

# ---------------------------------------------------------------------------
# 9. Subscriptions changing under a poll in flight. The transport builds the
#    statement, then the rows arrive later; meanwhile a channel may be
#    unsubscribed, or unsubscribed and subscribed again with a new mark. Rows
#    for it are dropped -- the old subscription is gone, and the new one's
#    mark decides what it gets -- while the other channels are delivered.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s);
  subscribe($nt, $s, $_) for qw(a b);
  $s->insert(a => 'a1');
  $s->insert(b => 'b1');

  my ($sql, $bind, $token) = $nt->poll_sql;
  my $rows = $s->answer($sql, $bind)->{rows};
  $nt->unsubscribe('a');
  is_deeply $nt->polled($token, $rows), [ [ 'b', 'b1', 777 ] ],
    'rows for a channel unsubscribed while the poll was in flight are dropped';
  is_deeply [ $nt->channels ], ['b'], '... and it stays unsubscribed';

  ($sql, $bind, $token) = $nt->poll_sql;
  $s->insert(b => 'b2');
  $rows = $s->answer($sql, $bind)->{rows};
  subscribe($nt, $s, 'b');   # a new subscription of b while that poll was out
  is_deeply $nt->polled($token, $rows), [],
    'rows for a channel subscribed anew while the poll was in flight are dropped';
  is_deeply poll($nt, $s), [], '... and its new mark treats b2 as history';

  $nt->unsubscribe('b');
  is_deeply [ $nt->poll_sql ], [], 'poll_sql returns nothing with no channel subscribed';
}

# ---------------------------------------------------------------------------
# 10. The window never moves backwards. The cutoff comes from the server's
#     clock; if that clock steps back, a poll reports an older cutoff, and a
#     window that followed it would take back rows it has already forgotten
#     and deliver them a second time.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s, lookback => 10, poll_interval => 1, retention => 3600);
  subscribe($nt, $s, 'jobs');
  $s->insert(jobs => 'once');
  $s->advance(1);
  is_deeply payloads(poll($nt, $s)), ['once'], 'delivered';
  $s->insert(jobs => 'later');   # moves the mark past 'once'
  $s->advance(30);
  poll($nt, $s);
  poll($nt, $s);
  $s->advance(-25);              # the server clock steps back
  # The poll after the step still binds the old cutoff and brings back the
  # stepped one; the poll after THAT is where a window that followed the clock
  # would take the forgotten rows back.
  is_deeply [ @{ poll($nt, $s) }, @{ poll($nt, $s) } ], [],
    'a clock step back does not deliver anything twice';
}

# ---------------------------------------------------------------------------
# 11. Malformed results are errors, not silence: a result without the cutoff
#     row, or a subscribe result without its mark row, means the statement was
#     not the one built here.
# ---------------------------------------------------------------------------

{
  my $nt = DBIO::MySQL::NotifyTable->new;
  throws_ok { $nt->subscribed(jobs => [ [ 1, undef, undef, undef, undef ] ]) } qr/no mark row/,
    'a subscribe result without its mark row croaks';
  subscribe($nt, FakeNotifyServer->new, 'jobs');
  my (undef, undef, $token) = $nt->poll_sql;
  throws_ok { $nt->polled($token, [ [ 1, 'jobs', 'p', 7, undef ] ]) } qr/no cutoff row/,
    'a poll result without its cutoff row croaks';
}

# ---------------------------------------------------------------------------
# 12. Retention. The cleanup is due on the first poll, then once a minute of
#     polling, and back to back while it deletes whole batches (a backlog is
#     worked off in bounded steps); a failed run waits a period. Retention 0
#     turns it off. The DELETE is bounded by LIMIT and walks created_at.
# ---------------------------------------------------------------------------

{
  my $s  = FakeNotifyServer->new;
  my $nt = listener($s, poll_interval => 10, lookback => 20, retention => 100, cleanup_limit => 2);
  subscribe($nt, $s, 'jobs');
  is_deeply [ $nt->cleanup_sql ], [], 'no cleanup before the first poll';

  poll($nt, $s);
  my ($sql, $bind) = $nt->cleanup_sql;
  is $sql, 'DELETE FROM `dbio_notify` WHERE `created_at` < UTC_TIMESTAMP(6) - INTERVAL 100000000 MICROSECOND LIMIT 2',
    'due on the first poll: a bounded DELETE of rows older than the retention';
  is_deeply $bind, [], '... with no binds';

  $s->insert(old => $_, at => $s->now - 500) for 1 .. 5;
  $nt->cleaned($s->answer($sql, $bind)->{rv});
  is scalar(@{ $s->{rows} }), 3, 'a full batch deleted two of five old rows';
  poll($nt, $s);
  ok scalar($nt->cleanup_sql), 'after a full batch the next poll cleans again';
  $nt->cleaned($s->answer($nt->cleanup_sql)->{rv});
  poll($nt, $s);
  $nt->cleaned($s->answer($nt->cleanup_sql)->{rv});
  is scalar(@{ $s->{rows} }), 0, '... until the backlog is gone';

  my $polls = 0;
  do { poll($nt, $s); $polls++ } until $nt->cleanup_sql || $polls > 100;
  is $polls, 6, 'then once a minute of polling: every 6th poll at a 10 s interval';

  $nt->cleaned(undef);
  ok !$nt->cleanup_sql, 'a failed cleanup waits a period instead of retrying every poll';

  my $off = listener($s, retention => 0);
  subscribe($off, $s, 'jobs');
  poll($off, $s) for 1 .. 3;
  is_deeply [ $off->cleanup_sql ], [], 'retention 0: never';
}

done_testing;
