use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Storage;
use DBIO::Replicated::Pool;
use DBIO::Replicated::Backend::Master;
use DBIO::Replicated::Backend::Replicant;
use DBIO::Replicated::Balancer::First;

# karr k118 -- is_replicating and lag_behind_master for PostgreSQL.
#
# DBIO::Replicated::Pool::validate_replicants asks every replicant these two
# questions and tells three answers apart: no answer leaves the replicant as it
# is ("manual management"), a defined false one deactivates it, a true one is
# held against maximum_lag. This driver inherited core's stubs, which answer
# nothing, so a PostgreSQL standby that had lost its primary, or was hours
# behind, stayed in the pool and kept serving reads.
#
# FULLY OFFLINE. The only thing a server contributes is one row of five facts,
# and that row is handed in here through a fake handle -- so every case below
# is a situation of a real server, written down as what that server reports:
#
#   in_recovery   pg_is_in_recovery()
#   pid, status   the pg_stat_wal_receiver row, if there is one
#   backlog       bytes received and not yet replayed
#   age           seconds since the last replayed transaction was committed
#
# What these tests hold is the reading of that row. That the statement really
# yields it is the business of t/89-replication-status-live.t.

{
  package ReplStatusTest::DBH;

  sub new {
    my ($class, $row) = @_;
    return bless { row => $row, queries => [] }, $class;
  }

  # The row in the column order of the statement; undef for "no row at all".
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    my $row = $self->{row} or return;
    return @{$row}{qw( in_recovery pid status backlog age )};
  }
}

{
  package ReplStatusTest::Debug;

  sub new { bless { lines => [] }, shift }
  sub print { push @{ $_[0]{lines} }, $_[1] }
}

{
  package ReplStatusTest::Storage;
  use base 'DBIO::PostgreSQL::Storage';
  use mro 'c3';

  sub ensure_connected { 1 }
  sub _get_dbh         { $_[0]->{__dbh} }
  sub _server_info     { { normalized_dbms_version => $_[0]->{__version} } }
}

# A storage whose server reports the given row. The version defaults to a
# current one; 0 is what a storage reports that could not read it.
sub server {
  my (%row) = @_;
  my $version = exists $row{version} ? delete $row{version} : 18.001;

  my $storage = ReplStatusTest::Storage->new;
  $storage->{__version} = $version;
  $storage->{__dbh}     = ReplStatusTest::DBH->new(\%row);
  return $storage;
}

# A hot standby that is streaming and has replayed everything: the healthy
# case every other standby below departs from in one respect.
sub standby {
  return server(
    in_recovery => 1,
    pid         => 4711,
    status      => 'streaming',
    backlog     => 0,
    age         => 0.2,
    @_,
  );
}

# "No answer" is the empty list, exactly as core's stubs give it: an undef
# would be an element in the list DBIO::Replicated::Storage takes the maximum
# lag of.
sub no_answer {
  my ($storage, $method, $name) = @_;
  my @answer = $storage->$method;
  is scalar(@answer), 0, $name
    or diag "answered: " . (defined $answer[0] ? $answer[0] : 'undef');
}

# --- 1. a server that is not in recovery is not a replica -------------------
#
# PostgreSQL can answer the question, so the answer is a defined false one. It
# is deliberately NOT what DBIO::MySQL::Storage gives for a server that is not
# a replica (nothing): "nothing" keeps the replicant active for good, which is
# exactly wrong for the second case here.

{
  my $primary = server(in_recovery => 0);

  my $answer = $primary->is_replicating;
  ok defined $answer, 'a primary answers is_replicating'
    or diag 'no answer would leave it in the pool under manual management';
  ok !$answer, '... and the answer is no: it follows nobody';
  no_answer $primary, 'lag_behind_master', '... so it has no lag to report';
}

{
  # A standby after promotion. Its replay functions do not go back to NULL:
  # "If recovery has completed then this will remain static" (PostgreSQL,
  # Recovery Information Functions) -- so the positions still compare equal
  # and the last replayed transaction keeps ageing. Only pg_is_in_recovery()
  # says that this server left its primary.
  my $promoted = server(in_recovery => 0, backlog => 0, age => 86_400);

  my $answer = $promoted->is_replicating;
  ok defined $answer && !$answer,
    'a promoted standby is not replicating, and says so';
  no_answer $promoted, 'lag_behind_master',
    '... and its frozen positions are not read as "caught up, lag 0"';
}

# --- 2. a standby that is not streaming -------------------------------------

{
  # No row in pg_stat_wal_receiver: no WAL receiver process, or one that never
  # got through to its upstream. A standby that lost its primary looks like
  # this, and so does one fed by restore_command alone.
  my $detached = standby(pid => undef, status => undef, backlog => 0, age => 600);

  my $answer = $detached->is_replicating;
  ok defined $answer && !$answer,
    'a standby without a WAL receiver is not replicating';
  no_answer $detached, 'lag_behind_master',
    '... and has no lag, although it replayed everything it ever received';

  my $shipped = standby(pid => undef, status => undef, backlog => undef, age => 3);
  $answer = $shipped->is_replicating;
  ok defined $answer && !$answer,
    'a standby that only restores shipped files is not replicating either';
}

for my $state (qw( starting waiting restarting stopping stopped )) {
  my $s = standby(status => $state);

  my $answer = $s->is_replicating;
  ok defined $answer && !$answer,
    "a WAL receiver that is '$state' is not streaming";
  no_answer $s, 'lag_behind_master', "... and reports no lag ($state)";
}

{
  # A role outside pg_read_all_stats sees the row with its pid and every other
  # column NULL. The row is there only while the receiver is alive and has
  # connected, so it is evidence of a stream -- and reading the missing state
  # as "not streaming" would deactivate every replicant of an ordinary
  # application role.
  my $unprivileged = standby(status => undef);

  ok $unprivileged->is_replicating,
    'a WAL receiver whose state the role cannot read counts as streaming';
  is $unprivileged->lag_behind_master, 0,
    '... and the lag, which needs no privilege, is still measured';

  is standby(status => undef, backlog => 4096, age => 42.7)->lag_behind_master, 42,
    '... also when there is one';
}

# --- 3. how far behind a streaming standby is -------------------------------

{
  # THE case against the naive formula. Nothing has been written on the
  # primary for an hour, so the last replayed transaction is an hour old --
  # and the standby is missing nothing.
  my $idle = standby(backlog => 0, age => 3600.5);

  ok $idle->is_replicating, 'a standby of an idle primary is replicating';

  my $lag = $idle->lag_behind_master;
  ok defined $lag, '... its lag is an answer, not "no answer"';
  is $lag, 0, '... and it is 0, not the age of the last transaction';
}

is standby(backlog => -8192, age => 900)->lag_behind_master, 0,
  'replay ahead of the stream (WAL from the archive) is caught up as well';

is standby(backlog => 16_384, age => 42.7)->lag_behind_master, 42,
  'with WAL outstanding the lag is the age of the last replayed transaction, in whole seconds';

# MySQL counts in whole seconds, and maximum_lag has to mean the same on both.
# It also has to work at its default of 0: a standby under steady load is never
# at exactly the position it has received.
is standby(backlog => 512, age => 0.35)->lag_behind_master, 0,
  'a standby a fraction of a second behind reports 0';

is standby(backlog => 512, age => -3.2)->lag_behind_master, 0,
  'a standby whose clock is behind its primary reports 0, never a negative lag';

{
  # Nothing was ever received by streaming in this run, so there is no
  # position to compare. Not knowing that it is caught up is not being caught
  # up: the age stands.
  is standby(backlog => undef, age => 12.3)->lag_behind_master, 12,
    'without a receive position the lag falls back to the age';
}

{
  # A standby just started: it has not replayed a transaction, so there is no
  # timestamp at all.
  is standby(backlog => 0, age => undef)->lag_behind_master, 0,
    'a fresh standby that has replayed all it received is at lag 0';

  my $catching_up = standby(backlog => 8192, age => undef);
  ok $catching_up->is_replicating, 'a fresh standby with WAL outstanding is replicating';
  no_answer $catching_up, 'lag_behind_master',
    '... but there is no number of seconds for its lag, and none is made up';

  no_answer standby(backlog => undef, age => undef), 'lag_behind_master',
    '... nor when there is neither a position nor a timestamp';
}

# --- 4. the statement behind it ---------------------------------------------

{
  my $s = standby(backlog => 4096, age => 7);
  $s->is_replicating;
  $s->lag_behind_master;

  my @queries = @{ $s->{__dbh}{queries} };
  is scalar(@queries), 2, 'each question is one statement';
  is $queries[0], $queries[1], '... the same one, so both read the same facts';

  # now() is the transaction's start time. A storage that validates its
  # replicants inside a transaction would otherwise see the lag stand still.
  unlike $queries[0], qr/\b(?:now|transaction_timestamp|statement_timestamp)\s*\(|current_timestamp/i,
    '... and it does not measure against a clock that stands still in a transaction';
}

{
  # Before PostgreSQL 10 the functions had other names; asking would throw
  # inside the balancer. Such a server keeps what it had: no answer.
  my $old = standby(version => 9.006024);

  no_answer $old, 'is_replicating', 'a server older than PostgreSQL 10 gives no answer';
  no_answer $old, 'lag_behind_master', '... for the lag either';
  is scalar(@{ $old->{__dbh}{queries} }), 0, '... and is not asked';

  ok standby(version => 0)->is_replicating,
    'an unreadable version is taken to be a current one';
}

# --- 5. what the pool makes of it -------------------------------------------
#
# The point of the whole card. Real Pool, real balancer; only the servers are
# the fakes from above.

{
  my $debug = ReplStatusTest::Debug->new;

  my $master_storage = server(in_recovery => 0);
  $master_storage->debugobj($debug);
  my $master = DBIO::Replicated::Backend::Master->new(storage => $master_storage);

  my $pool = DBIO::Replicated::Pool->new(master => $master, maximum_lag => 5);

  my %replicant;
  my $add = sub {
    my ($name, $storage) = @_;
    $replicant{$name} = $pool->set_replicant($name => DBIO::Replicated::Backend::Replicant->new(
      storage => $storage,
      master  => $master,
    ));
  };

  $add->(healthy  => standby());
  $add->(idle     => standby(backlog => 0, age => 7200));
  $add->(detached => standby(pid => undef, status => undef, backlog => 0, age => 30));
  $add->(behind   => standby(backlog => 1 << 20, age => 90));
  $add->(within   => standby(backlog => 4096, age => 4.9));
  $add->(promoted => server(in_recovery => 0, backlog => 0, age => 30));

  is scalar($pool->active_replicants), 6, 'every replicant starts out active';

  $pool->validate_replicants;

  ok  $replicant{healthy}->active,  'a streaming, caught-up standby stays active';
  ok  $replicant{idle}->active,     'a standby of an idle primary stays active';
  ok !$replicant{detached}->active, 'a standby that lost its primary is deactivated';
  ok !$replicant{behind}->active,   'a standby further behind than maximum_lag is deactivated';
  ok  $replicant{within}->active,   'a standby within maximum_lag stays active';
  ok !$replicant{promoted}->active, 'a promoted standby is deactivated';

  is_deeply $debug->{lines}, [],
    '... and none of them was passed over as "manual management"';

  # A standby that comes back is taken back: the answer is read anew.
  $replicant{behind}->storage->{__dbh}{row}{backlog} = 0;
  $pool->validate_replicants;
  ok $replicant{behind}->active, 'the standby that caught up is active again';
}

{
  # What a reader gets when the only replicant has lost its primary: the
  # master, not stale rows.
  my $debug = ReplStatusTest::Debug->new;

  my $master_storage = server(in_recovery => 0);
  $master_storage->debugobj($debug);
  my $master = DBIO::Replicated::Backend::Master->new(storage => $master_storage);

  my $pool = DBIO::Replicated::Pool->new(master => $master);
  my $replicant = $pool->set_replicant(only => DBIO::Replicated::Backend::Replicant->new(
    storage => standby(),
    master  => $master,
  ));

  my $balancer = DBIO::Replicated::Balancer::First->new(master => $master, pool => $pool);

  $pool->validate_replicants;
  is $balancer->next_storage_with_fallback, $replicant,
    'reads go to the standby while it streams';

  $replicant->storage->{__dbh}{row}{pid}    = undef;
  $replicant->storage->{__dbh}{row}{status} = undef;
  $pool->validate_replicants;
  is $balancer->next_storage_with_fallback, $master,
    '... and to the master once it does not';
}

{
  # The one situation with no answer on a current server (section 3): the
  # pool leaves the replicant in the state it found it in.
  my $debug = ReplStatusTest::Debug->new;

  my $master_storage = server(in_recovery => 0);
  $master_storage->debugobj($debug);
  my $master = DBIO::Replicated::Backend::Master->new(storage => $master_storage);

  my $pool = DBIO::Replicated::Pool->new(master => $master);
  my $fresh = $pool->set_replicant(fresh => DBIO::Replicated::Backend::Replicant->new(
    storage => standby(backlog => 8192, age => undef),
    master  => $master,
  ));

  $pool->validate_replicants;
  ok $fresh->active, 'a fresh standby without a lag figure is left active';

  $fresh->active(0);
  $pool->validate_replicants;
  ok !$fresh->active, '... or inactive, whichever it was';

  is scalar(@{ $debug->{lines} }), 2, '... and the pool says so each time';
}

done_testing;
