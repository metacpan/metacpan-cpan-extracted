use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k47: _pipeline_sync reports EV::Pg's error.
#
# WHY: EV::Pg calls a pipeline_sync callback with (1) when the server
# acknowledged the sync point and with (undef, $error) when the batch never got
# there -- the connection was lost ("connection lost") or closed ("connection
# finished"), or an error result arrived while the sync was the next thing it
# waited for. In that last case EV::Pg keeps the sync callback at the head of
# its queue and calls it a second time once the connection goes (Pg.xs 0.07:
# deliver_result, then process_results skips advance_cb_queue for a sync entry;
# measured live, see t/36-pipeline-sync-lost-live.t).
#
# Before the fix the callback ignored its arguments: the sync Future was done
# either way, and the second call died out of EV::Pg ("already done").
# pipeline() only failed because exit_pipeline happened to croak on the dead
# connection afterwards -- with its own error, not the cause.
#
# What this file claims:
#   1. the sync Future is done when EV::Pg reports the sync point;
#   2. it fails with EV::Pg's own message when EV::Pg reports an error;
#   3. it settles once: EV::Pg's second call after an error neither dies nor
#      replaces the first error;
#   4. through core's pipeline scaffold, on a connection whose exit_pipeline
#      does NOT croak, a lost sync still fails the pipeline, with the sync's
#      error, although the coderef returned a plain value -- the outcome comes
#      from the sync, not from the exit happening to fail -- and the connection
#      is handed back once;
#   5. a firing in a process other than the one that issued the sync returns
#      at once and leaves the Future alone (karr k45, kept by the fix).
#
# Without the fix 2, 3 and 4 fail. SyncPg stands in for an EV::Pg connection:
# pipeline_sync only records the callback, and the test fires it by hand.

use DBIO::PostgreSQL::EV::Storage;

{
  package SyncPg;
  sub new             { bless { syncs => [], exits => 0 }, shift }
  sub enter_pipeline  { $_[0]{in_pipeline} = 1; return }
  sub exit_pipeline   { $_[0]{in_pipeline} = 0; $_[0]{exits}++; return }
  sub pipeline_sync   { my ($self, $cb) = @_; push @{ $self->{syncs} }, $cb; return }
  sub pending_count   { scalar @{ $_[0]{syncs} } }
  sub fire            { my ($self, @args) = @_; $self->{syncs}[-1]->(@args) }
}

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { dbname => 'fake' }, {} ]);

my $LOST  = 'connection lost';
my $FATAL = "FATAL:  terminating connection due to administrator command\n";

# --- 1. the sync point was acknowledged -----------------------------------------

{
  my $pg = SyncPg->new;
  my $f  = $storage->_pipeline_sync($pg);
  ok !$f->is_ready, 'the sync Future is pending until EV::Pg calls back';
  $pg->fire(1);
  ok $f->is_done, 'EV::Pg reports the sync point: the sync Future is done';
}

# --- 2. EV::Pg reports an error --------------------------------------------------

{
  my $pg = SyncPg->new;
  my $f  = $storage->_pipeline_sync($pg);
  $pg->fire(undef, $LOST);
  ok $f->is_failed, 'EV::Pg reports an error: the sync Future fails'
    or diag 'it is ' . ($f->is_done ? 'done' : 'pending');
  is scalar(($f->failure)[0] // ''), $LOST, "with EV::Pg's own message";
}

# --- 3. EV::Pg calls the sync callback twice ------------------------------------

{
  my $pg = SyncPg->new;
  my $f  = $storage->_pipeline_sync($pg);
  $pg->fire(undef, $FATAL);
  my $second = eval { $pg->fire(undef, $LOST); 1 } ? '' : $@;
  is $second, '', "EV::Pg's second call after an error does not die";
  ok $f->is_failed, 'the sync Future failed';
  is scalar(($f->failure)[0] // ''), $FATAL, 'with the first error, not replaced by the second';
}

# --- 4. through core's scaffold, on a connection whose exit does not croak ------

{
  my $pg = SyncPg->new;
  my ($released, $retired) = (0, 0);
  my $p = $storage->_pipeline_on_conn(
    $pg,
    sub { 'plain-ok' },
    sub { $released++ },
    sub { $retired++ },
  );
  ok !$p->is_ready, 'the pipeline waits for the sync';
  $pg->fire(undef, $LOST);
  ok $p->is_failed, 'a lost sync fails the pipeline, although the coderef returned a plain value'
    or diag 'it resolved: ' . join ', ', map { $_ // 'undef' } $p->get;
  is scalar(($p->failure)[0] // ''), $LOST, "with the sync's error";
  is $pg->{exits}, 1, 'pipeline mode was exited';
  is $released + $retired, 1, 'the connection was handed back once';
}

{
  my $pg = SyncPg->new;
  my $p  = $storage->_pipeline_on_conn($pg, sub { 'plain-ok' }, sub { 1 }, sub { 1 });
  $pg->fire(1);
  is_deeply [ $p->get ], [ 'plain-ok' ], 'an acknowledged sync still resolves the pipeline with the coderef value';
}

# --- 5. a firing in another process (karr k45) ----------------------------------

{
  my $pg = SyncPg->new;
  my $f  = $storage->_pipeline_sync($pg);
  {
    local $$ = $$ + 1;
    $pg->fire(undef, 'connection finished');
  }
  ok !$f->is_ready, "a firing in another process leaves the sync Future pending";
  $pg->fire(1);
  ok $f->is_done, 'and the issuing process still settles it';
}

done_testing;
