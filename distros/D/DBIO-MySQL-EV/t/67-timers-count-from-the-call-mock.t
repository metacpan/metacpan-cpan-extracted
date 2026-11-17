use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# OFFLINE test: a timer of the library that measures a duration counts from
# the call that makes it.
#
# WHY: libev counts a relative EV::timer from its cached "now", which moves on
# only when the loop runs. A program that worked synchronously for longer than
# the duration, then asked for a wait, got a timer that was due at once: the
# statement timeout of execute_when_idle failed a statement that had waited
# no time at all, the listen backoff did not back off, the notify poll ran
# without a pause. What is at stake: a wait lasts what the caller asked for,
# however long the program was busy before.
#
# The stale clock is built here: one non-blocking loop run takes "now", then
# the program blocks for longer than the wait. A wait of $WAIT seconds must
# still be pending after $WAIT/3 seconds of loop and must be over after it
# has run for $WAIT.

use EV;
use DBIO::MySQL::EV::QueryExecutor;
use DBIO::MySQL::EV::Storage;

alarm 60;

our $WAIT = 0.6;

my $TICK = EV::timer(0.01, 0.01, sub {});   # RUN_ONCE never blocks for long

sub stale_clock {
  EV::run(EV::RUN_NOWAIT());
  select undef, undef, undef, $WAIT + 0.4;   # the program is busy; the loop's "now" stands still
}

sub run_for {
  my ($seconds, $cond) = @_;
  my $deadline = Time::HiRes::time() + $seconds;
  while (Time::HiRes::time() < $deadline) {
    last if $cond && $cond->();
    EV::run(EV::RUN_ONCE());
  }
  return;
}

# --- execute_when_idle: the $timeout of a waiting statement -----------------------

{
  package T67::MDB;
  sub new { bless { sent => [] }, shift }
  sub query { my ($self, $sql, $cb) = @_; push @{ $self->{sent} }, { sql => $sql, cb => $cb }; return }
}

{
  my $executor = DBIO::MySQL::EV::QueryExecutor->new;
  my $mdb      = T67::MDB->new;
  $executor->execute($mdb, 'SELECT 1', []);   # in flight, never answered

  stale_clock();
  my $f = $executor->execute_when_idle($mdb, 'ROLLBACK', [], $WAIT);
  run_for($WAIT / 3, sub { $f->is_ready });
  ok !$f->is_ready, 'execute_when_idle: the timeout counts from the call, not from the loop\'s last now';

  run_for($WAIT * 2, sub { $f->is_ready });
  ok $f->is_failed, '... and it does fail once the wait is over';
  like(($f->failure // '') . '', qr/did not answer within/, '... naming the wait');
  DBIO::MySQL::EV::QueryExecutor->forget($mdb);
}

# --- _listen_delay -------------------------------------------------------------------

{
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  stale_clock();
  my $f = $s->_listen_delay($WAIT);
  run_for($WAIT / 3, sub { $f->is_ready });
  ok !$f->is_ready, '_listen_delay: the delay counts from the call';
  run_for($WAIT * 2, sub { $f->is_ready });
  ok $f->is_done, '... and ends after it';
}

# --- _mysql_listen_arm: the notify poll interval --------------------------------------

{
  package T67::Notify;
  sub new { bless {}, shift }
  sub poll_interval { $main::WAIT }
}

{
  my $s     = DBIO::MySQL::EV::Storage->new(undef);
  my $fired = 0;
  no warnings 'redefine';
  local *DBIO::MySQL::EV::Storage::_mysql_listen_cb = sub { sub { $fired++ } };

  my $conn  = { notify => T67::Notify->new };
  my $watch = {};
  stale_clock();
  $s->_mysql_listen_arm($conn, $watch);
  run_for($WAIT / 3, sub { $fired });
  ok !$fired, '_mysql_listen_arm: the poll interval counts from the arming';
  run_for($WAIT * 2, sub { $fired });
  ok $fired, '... and the poll comes after it';
}

done_testing;
