use strict;
use warnings;
use Test::More;

# LIVE test: the session of a pooled ev connection is the borrow's own
# (karr k99, core k398, ADR 0079).
#
# CLAIM: when a borrow ends -- a transaction, a plain statement, a COPY -- the
# transport resets the connection with DISCARD ALL and runs the connect actions
# again before anyone else gets it. What one borrow set in the server session
# is gone in the next borrow, which runs on the SAME backend (a pool of one)
# with the session its connect gave it:
#   - SET ROLE: current_user is the login again;
#   - set_config(..., false) and SET: the setting is empty / the connect's;
#   - search_path and application_name (on_connect_do): as after the connect;
#   - a temporary table, a prepared statement, a session advisory lock: gone,
#     the lock released on the server (seen from another session);
#   - the same after a COPY, whose end is the pool's release like any other;
#   - a reset that fails retires the connection: the next borrow runs on a new
#     backend, and the old one is gone from the server.
#
# WHY it matters: the connection is shared by every caller of the application.
# A role, a tenant setting or a search_path that survives its borrow is applied
# to the next request, which may be another user's. A mock cannot show that the
# SERVER's session is clean, which is why this runs against PostgreSQL.
#
# Gated like the other live tests: DBIO_TEST_PG_DSN (and EV::Pg).

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

use EV;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

alarm 120;

my $TAG   = "k99_$$";
my $ROLE  = "dbio_$TAG";
my $LOCK  = 990_099;

my $admin = LiveServer->control_dbh;
my ($LOGIN) = $admin->selectrow_array('SELECT current_user::text');

my $have_role = eval { $admin->do(qq{CREATE ROLE "$ROLE" NOLOGIN}); 1 };
if ($have_role) {
  # PostgreSQL before 16 does not make the creator a member
  eval { $admin->do(qq{GRANT "$ROLE" TO CURRENT_USER}); 1 };
}
else {
  die $@ unless ($admin->state // '') eq '42501';   # insufficient_privilege
}

$admin->do(qq{DROP TABLE IF EXISTS public.${TAG}_copy});
$admin->do(qq{DROP TABLE IF EXISTS public.${TAG}_flag});
$admin->do(qq{CREATE TABLE public.${TAG}_copy (a integer)});
$admin->do(qq{CREATE TABLE public.${TAG}_flag (armed boolean NOT NULL)});
$admin->do(qq{INSERT INTO public.${TAG}_flag VALUES (false)});
# A row inserted by the COPY sets a session setting: state a COPY leaves on its
# connection, which only the reset can take away.
$admin->do(qq{CREATE FUNCTION public.${TAG}_fn() RETURNS trigger LANGUAGE plpgsql AS \$\$
  BEGIN PERFORM set_config('dbio.k99', 'set-by-copy', false); RETURN NEW; END \$\$});
$admin->do(qq{CREATE TRIGGER ${TAG}_trg BEFORE INSERT ON public.${TAG}_copy
  FOR EACH ROW EXECUTE FUNCTION public.${TAG}_fn()});

END {
  if ($admin) {
    local ($@, $?);
    eval { $admin->do(qq{DROP TABLE IF EXISTS public.${TAG}_copy}); 1 };
    eval { $admin->do(qq{DROP TABLE IF EXISTS public.${TAG}_flag}); 1 };
    eval { $admin->do(qq{DROP FUNCTION IF EXISTS public.${TAG}_fn()}); 1 };
    eval { $admin->do(qq{DROP ROLE IF EXISTS "$ROLE"}); 1 } if $have_role;
    $admin->disconnect;
  }
}

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  connect_attrs => {
    pool_size     => 1,
    on_connect_do => [ q{SET application_name = 'dbio_k99'}, q{SET search_path = public, pg_catalog} ],
  },
);
my $async = $h->async;

# One borrow: a transaction whose pinned connection runs @sql in order; the
# rows of the last statement come back.
sub txn_borrow {
  my (@sql) = @_;
  my $rows;
  $h->await($async->txn_do_async(sub {
    my ($txn) = @_;
    my $f = $async->future_class->done;
    for my $sql (@sql) {
      $f = $f->then(sub {
        $async->_query_async_pinned($txn->txn_conn, $sql, [])
          ->then(sub { $rows = [ @_ ]; $async->future_class->done });
      });
    }
    return $f;
  }));
  return $rows;
}

# One borrow that is a single plain statement.
sub statement { my ($sql) = @_; return [ $h->await($async->_query_async($sql, [])) ] }

# What a borrow asks of its session.
my $probe = qq{SELECT current_user::text,
    coalesce(current_setting('dbio.k99', true), ''),
    current_setting('search_path'),
    current_setting('application_name'),
    (to_regclass('pg_temp.${TAG}_tmp') IS NOT NULL)::int,
    (SELECT count(*) FROM pg_prepared_statements WHERE name = '${TAG}_stmt'),
    (SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid() AND objid = $LOCK),
    pg_backend_pid()};

sub pid_alive {
  my ($pid) = @_;
  my ($n) = $admin->selectrow_array('SELECT count(*) FROM pg_stat_activity WHERE pid = ?', undef, $pid);
  return $n;
}

# Run the EV loop for a moment.
sub tick {
  my ($seconds) = @_;
  my $done = 0;
  EV::now_update();
  my $t = EV::timer($seconds, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

my $fresh = txn_borrow($probe)->[0];
my ($pid) = $fresh->[7];
is $fresh->[0], $LOGIN, 'a fresh connection runs as the login';
is $fresh->[3], 'dbio_k99', 'the connect action (on_connect_do) is in effect on a fresh connection';
is $fresh->[2], 'public, pg_catalog', '... and the connection\'s search_path is the one it set';

# --- a transaction borrow ------------------------------------------------------------

{
  my @sql = (
    q{SELECT set_config('dbio.k99', 'tenant-a', false)},
    q{SET search_path = pg_catalog},
    q{SET application_name = 'someone_else'},
    qq{CREATE TEMPORARY TABLE ${TAG}_tmp (a integer)},
    qq{PREPARE ${TAG}_stmt AS SELECT 1},
    qq{SELECT pg_advisory_lock($LOCK)},
  );
  txn_borrow(@sql);

  is pid_alive($pid), 1, 'txn_do_async: the backend is the same one after the borrow (it was reset, not replaced)';
  my ($held) = $admin->selectrow_array(
    q{SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = ? AND objid = ?}, undef, $pid, $LOCK);
  is $held, 0, 'txn_do_async: the session advisory lock of the ended borrow is released on the server';

  my $next = txn_borrow($probe)->[0];
  is $next->[7], $pid, 'txn_do_async: the next borrow runs on the SAME backend';
  is $next->[1], '',            'txn_do_async: set_config(..., false) is gone';
  is $next->[2], $fresh->[2],   'txn_do_async: search_path is the one after the connect';
  is $next->[3], 'dbio_k99',    'txn_do_async: on_connect_do is in effect again';
  is $next->[4], 0,             'txn_do_async: the temporary table is gone';
  is $next->[5], 0,             'txn_do_async: the prepared statement is gone';
  is $next->[6], 0,             'txn_do_async: the session advisory lock is not held';
}

SKIP: {
  skip "the test user $LOGIN may not create roles", 4 unless $have_role;

  my $inside = txn_borrow(qq{SET ROLE "$ROLE"}, q{SELECT current_user::text})->[0];
  is $inside->[0], $ROLE, 'SET ROLE: the borrow runs as the role';
  my $next = txn_borrow($probe)->[0];
  is $next->[7], $pid, 'SET ROLE: the next borrow runs on the SAME backend';
  is $next->[0], $LOGIN, 'SET ROLE: ... as the login, not the role';

  # SET ROLE in a plain statement is a borrow of its own.
  statement(qq{SET ROLE "$ROLE"});
  my $after = statement($probe)->[0];
  is $after->[0], $LOGIN, 'SET ROLE in a plain statement: the next call runs as the login';
}

# --- plain statements ----------------------------------------------------------------

{
  statement(q{SELECT set_config('dbio.k99', 'tenant-b', false)});
  statement(q{SET search_path = pg_catalog});
  my $row = statement($probe)->[0];
  is $row->[7], $pid, 'plain statements: the next call runs on the SAME backend';
  is $row->[1], '',          'plain statements: set_config(..., false) of the call before is gone';
  is $row->[2], $fresh->[2], 'plain statements: search_path is the one after the connect';
  is $row->[3], 'dbio_k99',  'plain statements: on_connect_do is in effect';
}

# --- COPY ----------------------------------------------------------------------------

{
  # The row sets a setting in the COPY's own session (trigger).
  my $n = $h->await($async->copy_in("public.${TAG}_copy", ['a'], sub { $_[0]->([$_]) for 1 .. 3 }));
  ok $n, 'copy_in: the COPY completes';
  my ($rows) = $admin->selectrow_array("SELECT count(*) FROM public.${TAG}_copy");
  is $rows, 3, 'copy_in: its rows are in the table';

  my $row = statement($probe)->[0];
  is $row->[7], $pid, 'copy_in: the next call runs on the SAME backend';
  is $row->[1], '', 'copy_in: what the COPY set in its session is gone (the COPY\'s end is reset like any other)';
}

# --- a reset that fails retires the connection ---------------------------------------

$h->disconnect;

{
  my $h2 = DBIO::PostgreSQL::EV::TestHarness->new(
    connect_attrs => {
      pool_size     => 1,
      # division by zero while the flag is armed; the divisor comes from a
      # subquery, as a constant would be folded and fail at planning either way
      on_connect_do => [ qq{SELECT 1 / CASE WHEN (SELECT armed FROM public.${TAG}_flag) THEN 0 ELSE 1 END} ],
    },
  );
  my $a2 = $h2->async;
  my $row = sub { [ $h2->await($a2->_query_async(q{SELECT pg_backend_pid()}, [])) ]->[0][0] };

  my $first = $row->();
  tick(0.2);   # its reset is answered
  is pid_alive($first), 1, 'a reset that succeeds keeps the backend';

  $admin->do(qq{UPDATE public.${TAG}_flag SET armed = true});
  my $second = $row->();
  is $second, $first, 'the borrow before the failing reset runs on the same backend';

  # The reset replays the connect action, which now fails: the connection is
  # retired and its backend ends.
  my $deadline = time + 10;
  tick(0.1) while pid_alive($first) && time < $deadline;
  is pid_alive($first), 0, 'the reset failed: the connection is closed, its backend is gone from the server';

  $admin->do(qq{UPDATE public.${TAG}_flag SET armed = false});
  my $third = $row->();
  isnt $third, $first, 'the next borrower runs on a new backend, with a session of its own';

  $h2->disconnect;
}

done_testing;
