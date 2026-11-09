use strict;
use warnings;
use Test::More;

# LIVE, karr k88 (1): what ends pooled work hands its connection back to the
# pool the connection was acquired from -- against a real EV::Pg and a real
# PostgreSQL. The live half of t/75-completion-same-pool-mock.t, which has the
# whole of the why.
#
# WHY HERE: t/75 runs over a stand-in EV::Pg and stands on one thing it assumes
# of the real one: that finish, called inside the delivery of a statement's
# result, does not call that statement's callback again. Only then is the
# completion still on the call stack when the storage's pool slot is emptied,
# and only then does it matter which pool the completion talks to. If a real
# EV::Pg called it again, from inside finish, the old pool would still be in
# the slot and none of this could happen. And only a server says what a
# disconnect made at that moment leaves behind: whether the session is gone,
# and what became of a COPY.
#
# What this file claims, with the storage disconnected INSIDE the delivery --
# in a then or a failure handler on the Future of a pooled statement, of a
# notify and of a copy_in, and in a copy_in's coderef:
#   1. the work's Future ends as it does without the disconnect, once;
#   2. no pool is built as the work ends, and the storage is left without one;
#   3. the server has no session left for the pool;
#   4. no callback of this transport dies out of EV::Pg;
#   5. the next statement completes, on a pool built for it and on a new
#      session; after a disconnect that one is gone too;
#   6. a COPY the server had answered stays loaded; a COPY whose coderef
#      disconnected the storage loads nothing.
# With a connect_info this transport refuses in place of the disconnect -- it
# disconnects, drops what the storage could connect from, and throws:
#   7. the completion does not die out of EV::Pg for want of a pool to build,
#      and a copy_in whose coderef did it settles its Future. Before the fix
#      the first warned "exception in callback: conninfo or conninfo_provider
#      required", and the second stayed pending for good.
# And the control, green before the fix as well:
#   0. a disconnect from OUTSIDE, with the statement on the server: EV::Pg
#      calls the statement's callback from inside finish, the Future fails
#      with "connection finished", and no pool is built. This is why a plain
#      disconnect never showed the fault.
#
# Before the fix 2 fails in every case of the first group -- the storage
# carries a new pool, empty and not shut down -- and 7 as said.
#
# Every wait on the EV loop is bounded by a watchdog, and alarm is the backstop.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use DBIO::PostgreSQL::EV::Pool;

alarm 180;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF   = 'DBIO::PostgreSQL::EV::Future';
my $POOL  = 'DBIO::PostgreSQL::EV::Pool';
my $TAG   = "dbio_k88_completion_$$";
my $TABLE = 'dbio_karr88_completion';
my @COPY  = ($TABLE, [qw( name )]);

# The server's view, from a connection that belongs to no pool. A server that
# is not there fails the file here, with a plan (karr k77).
my $observer = LiveServer->control_dbh(application_name => "${TAG}_observer");
$observer->do('SET client_min_messages = warning');
{
  my ($seen_as) = $observer->selectrow_array(
    'SELECT application_name FROM pg_catalog.pg_stat_activity WHERE pid = pg_backend_pid()'
  );
  plan skip_all => 'the test DSN sets an application_name of its own; this file tells its backends apart by PGAPPNAME'
    unless defined $seen_as && $seen_as eq "${TAG}_observer";
}
$ENV{PGAPPNAME} = $TAG;   # every connection a harness opens from here on

$observer->do("DROP TABLE IF EXISTS $TABLE");
$observer->do("CREATE TABLE $TABLE (name text NOT NULL)");

END {
  if ($observer) {
    local $@;
    eval { $observer->do("DROP TABLE IF EXISTS $TABLE") };
  }
}

# Every pool that is built, or that someone tried to build. The pool class
# inherits its constructor from core's pool.
my $BUILDS = 0;
{
  no strict 'refs';
  my $new = $POOL->can('new');
  *{"${POOL}::new"} = sub { $BUILDS++; goto &$new };
}

# A SELECT of SQL expressions through the async API, as a consumer writes it.
sub exprs {
  my @sql = @_;
  return ('pg_namespace', [ map { \$_ } @sql ], { nspname => 'pg_catalog' });
}
my @PID = exprs('pg_backend_pid()');

# Run the loop until $f is ready, at most 10 seconds.
sub drive {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $deadline = EV::time() + 10;
  until ($f->is_ready) {
    last if EV::time() > $deadline;
    EV::now_update();
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return $f;
}

# Run the EV loop until $cond holds; false if it does not within 10 seconds.
sub wait_until {
  my ($cond) = @_;
  EV::now_update();
  my $deadline = EV::time() + 10;
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    EV::now_update();
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# Run the loop a little, so anything that would fire late has fired.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub outcome {
  my ($f) = @_;
  return 'pending'   unless $f->is_ready;
  return 'cancelled' if $f->is_cancelled;
  return 'failed: ' . ($f->failure)[0] if $f->is_failed;
  return 'done';
}

# The sessions the server has for the pool of $h: the owner's DBI connection,
# which carries the same application_name, left out.
sub pool_backends {
  my ($h) = @_;
  my $owner = $h->sync_storage->dbh->{pg_pid};
  return [ grep { $_ != $owner } @{ $observer->selectcol_arrayref(
    'SELECT pid FROM pg_catalog.pg_stat_activity WHERE application_name = ? ORDER BY pid', undef, $TAG,
  ) } ];
}

sub loaded { $observer->selectcol_arrayref("SELECT name FROM $TABLE ORDER BY name") }

# A harness with a pool of two, one connection up and idle: the harness and
# the backend of that connection.
sub warm {
  my ($label) = @_;
  my $h    = DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 2 });
  my $warm = drive($h->async->select_async(@PID));
  die "$label: warming the pool failed: " . outcome($warm) unless $warm->is_done;
  settle();
  $observer->do("TRUNCATE $TABLE");
  @warnings = ();
  return ($h, ($warm->get)[0][0]);
}

# What takes the pool from under the work, inside its delivery.
sub disconnects { $_[0]->disconnect }

sub refused_connect_info {
  my ($async) = @_;
  die "connect_info took a coderef\n" if eval { $async->connect_info([ sub { } ]); 1 };
}

# 1 to 4 of the header, after work whose Future is $f ended on $h. $ran counts
# how often the pool was taken inside the delivery.
sub ended_without_a_pool {
  my ($label, $h, $f, $ran, $builds, $ends) = @_;
  settle();
  is $ran, 1, "$label: the storage lost its pool inside the delivery";
  like outcome($f), $ends, "$label: the Future ends as it does without it";
  is $BUILDS - $builds, 0, "$label: no pool is built as the work ends";
  ok !defined $h->async->{pool}, "$label: the storage is left without a pool";
  ok wait_until(sub { !@{ pool_backends($h) } }), "$label: the server has no session left for the pool"
    or diag "left: @{ pool_backends($h) }";
  is scalar(grep { /exception in callback/ } @warnings), 0, "$label: no callback died out of EV::Pg"
    or diag @warnings;
}

# 5 of the header.
sub usable_again {
  my ($label, $h, $pid, $builds) = @_;
  my $next = drive($h->async->select_async(@PID));
  is outcome($next), 'done', "$label: the next statement completes";
  is $BUILDS - $builds, 1, "$label: on a pool built for it";
  my $on = $next->is_done ? ($next->get)[0][0] : 0;
  ok $on && $on != $pid, "$label: and on a new session";
  settle();
  $h->disconnect;
  ok wait_until(sub { !@{ pool_backends($h) } }), "$label: which is gone after a disconnect";
  is scalar(grep { /exception in callback/ } @warnings), 0, "$label: still no callback died out of EV::Pg"
    or diag @warnings;
}

# --- 0. the control: disconnect from outside, the statement on the server -----
{
  my $label = 'select_async on the server, disconnect from outside';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;

  my $f = $async->select_async(exprs('pg_sleep(1)'));
  ok wait_until(sub {
    my ($state) = $observer->selectrow_array('SELECT state FROM pg_catalog.pg_stat_activity WHERE pid = ?', undef, $pid);
    defined $state && $state eq 'active';
  }), "$label: the statement is on the server";

  $async->disconnect;
  like outcome($f), qr/\Afailed: connection finished/,
    "$label: the Future has failed by the time disconnect returns -- EV::Pg called its callback from inside finish";
  is $BUILDS - $builds, 0, "$label: no pool is built";
  ok !defined $async->{pool}, "$label: the storage is left without a pool";
  ok wait_until(sub { !@{ pool_backends($h) } }), "$label: the server has no session left for the pool";
  usable_again($label, $h, $pid, $builds);
}

# --- 1 to 6. disconnect inside the delivery -------------------------------------
{
  my $label = 'select_async, disconnect in a then on its Future';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->select_async(@PID)->then(sub { $ran++; disconnects($async); $EVF->done(@_) }));
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Adone\z/);
  is +($f->is_done ? ($f->get)[0][0] : 0), $pid, "$label: with its own row";
  usable_again($label, $h, $pid, $builds);
}

{
  my $label = 'select_async the server answers with an error, disconnect in its failure handler';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->select_async(exprs('1/0'))->else(sub { $ran++; disconnects($async); $EVF->fail(@_) }));
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Afailed: .*division by zero/s);
  usable_again($label, $h, $pid, $builds);
}

{
  my $label = 'notify, disconnect in a then on its Future';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->notify("${TAG}_ch", 'payload')->then(sub { $ran++; disconnects($async); $EVF->done }));
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Adone\z/);
  usable_again($label, $h, $pid, $builds);
}

{
  my $label = 'copy_in, disconnect in a then on its Future';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive(
    $async->copy_in(@COPY, sub { $_[0]->(['answered']) })->then(sub { $ran++; disconnects($async); $EVF->done(@_) })
  );
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Adone\z/);
  is_deeply loaded(), ['answered'], "$label: the COPY the server had answered stays loaded";
  usable_again($label, $h, $pid, $builds);
}

{
  my $label = 'copy_in, disconnect in its coderef';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->copy_in(@COPY, sub {
    my ($put) = @_;
    $put->(['never']);
    $ran++;
    disconnects($async);
  }));
  # the stream cannot be ended on a connection that was finished under it
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Afailed: not connected/);
  is_deeply loaded(), [], "$label: nothing of the COPY is loaded";
  usable_again($label, $h, $pid, $builds);
}

# --- 7. nothing left to connect from --------------------------------------------
{
  my $label = 'select_async, a refused connect_info in a then on its Future';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->select_async(@PID)->then(sub { $ran++; refused_connect_info($async); $EVF->done(@_) }));
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Adone\z/);
  $h->disconnect;
}

{
  my $label = 'copy_in, a refused connect_info in its coderef';
  my ($h, $pid) = warm($label);
  my $async  = $h->async;
  my $builds = $BUILDS;
  my $ran    = 0;
  my $f = drive($async->copy_in(@COPY, sub {
    my ($put) = @_;
    $put->(['never']);
    $ran++;
    refused_connect_info($async);
  }));
  ended_without_a_pool($label, $h, $f, $ran, $builds, qr/\Afailed: not connected/);
  is_deeply loaded(), [], "$label: nothing of the COPY is loaded";
  $h->disconnect;
}

done_testing;
