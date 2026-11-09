use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE regression for karr k65: how a COPY ends, and what becomes of its
# connection. t/73 holds the same claims against a stand-in EV::Pg that
# follows Pg.xs; this file ends real COPYs on a real PostgreSQL, on a pool of
# one, through copy_in as a consumer calls it.
#
# WHY: copy_in knew one way to end a COPY -- settle the Future, hand the
# connection back -- whatever state the connection was in, and its writer did
# not look at what put_copy_data answered. Measured at karr k65 against
# PostgreSQL 18.6 with EV::Pg 0.07 and libpq 17.11:
#   - a backend terminated inside the coderef, the coderef writing on: libpq
#     drops the connection inside PQputCopyData (-1, ignored), PQputCopyEnd
#     then answers 1, EV::Pg loses the connection in the flush behind it and
#     drops the COPY's callback. copy_in waited for an answer that could not
#     come: the Future stayed pending and the pool of one checked out;
#   - the same with a coderef that dies in the end: the Future failed with
#     "put_copy_end failed" instead of the coderef's error;
#   - put_copy_data answering 0 (libpq could not grow its output buffer --
#     measured with a slow consumer under an address-space limit): the rows it
#     answered 0 for were missing from a COPY that completed.
#
# What this file claims:
#   1. a COPY whose backend is terminated inside the coderef fails -- it never
#      stays pending -- whatever the coderef does after that; a coderef that
#      dies fails it with its own error; the pool recovers on a fresh
#      connection; the table holds nothing of the load;
#   2. a put_copy_end that answers -1 on an open connection: the COPY fails,
#      the connection is retired, its backend ends, the next call completes on
#      a fresh one, and the table holds nothing of the load;
#   3. a row put_copy_data answers 0 for fails the COPY, also when the coderef
#      catches the writer's die: the table holds nothing of the load, and the
#      connection, which is good, serves the next call;
#   4. a writer kept beyond its COPY dies, and puts nothing into the COPY the
#      next caller has open on that connection;
#   5. no callback of this transport dies out of EV::Pg;
# and the control, green before and after:
#   6. a coderef that dies on a healthy connection fails the COPY with its own
#      error, loads nothing, and keeps the connection.
#
# What a terminated backend does to the client depends on the network between
# them: which write first fails, and whether libpq or EV::Pg notices. The five
# shapes of 1 were chosen to reach the different ends -- the server's absence
# read by the EV loop, by a put, by put_copy_end -- and each notes the error it
# got; the claims hold for every end. 2 and 3 cannot be had from a server: the
# -1 on an open connection and the 0 are libpq failing to allocate. They are
# injected where copy_in calls EV::Pg -- the pooled handle's put_copy_end /
# put_copy_data answers them without reaching libpq, which is what libpq's own
# -1 / 0 leave behind: the COPY open, the row not taken. Everything after
# that is the real libpq and the real server.
#
# Terminating backends needs pg_terminate_backend on this file's own sessions
# only -- the same role -- which PostgreSQL allows without superuser.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use EV;

alarm 300;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $TABLE = 'dbio_copy_in_end_live';
my @COPY  = ($TABLE, [qw( id name )]);
my $CONN  = 'DBIO::PostgreSQL::EV::Pool::_Connection';

# The backend pid of the connection a call runs on.
my @PID = ('pg_namespace', [ \'pg_backend_pid()' ], { nspname => 'pg_catalog' });

sub harness {
  return DBIO::PostgreSQL::EV::TestHarness->new(connect_attrs => { pool_size => 1 });
}

# Wait for $f: (1, @result) once it is done, (0, $error) once it failed. A
# Future still pending after 10 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { $f->fail("watchdog: still pending after 10s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Run the loop a little, so anything that would fire late has fired before the
# pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.1, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub dbh { $_[0]->sync_storage->dbh }

sub terminate {
  my ($h, $pid) = @_;
  my ($ok) = dbh($h)->selectrow_array('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
  return $ok;
}

sub rows_loaded {
  my ($h) = @_;
  return dbh($h)->selectcol_arrayref("SELECT name FROM $TABLE ORDER BY id");
}

# The backend pid the next call runs on, or undef and the error.
sub backend_of_next_call {
  my ($h) = @_;
  my ($ok, @r) = wait_for($h->async->select_async(@PID));
  return $ok ? ($r[0][0]) : (undef, $r[0]);
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# A harness whose one pooled connection is up, and its backend pid.
sub warm {
  my ($label) = @_;
  my $h = harness();
  my ($pid, $err) = backend_of_next_call($h);
  ok defined $pid, "$label: the pooled connection is up" or diag $err;
  dbh($h)->do("TRUNCATE $TABLE");
  settle();
  @warnings = ();
  return ($h, $pid);
}

# The next call completes -- on backend $pid ($same) or on another -- and the
# pool of one is whole.
sub next_call {
  my ($label, $h, $pid, $same) = @_;
  my ($next, $err) = backend_of_next_call($h);
  ok defined $next, "$label: the next call completes" or diag "it failed: $err";
  if ($same) {
    ok defined $next && $next == $pid, "$label: on the same connection (backend $pid)";
  }
  else {
    ok defined $next && $next != $pid, "$label: on a fresh connection (not backend $pid)";
  }
  settle();
  is $h->pool->size, 1, "$label: the pool has its one connection";
  is $h->pool->available, 1, "$label: idle";
  no_callback_died($label);
}

{
  my $h = harness();
  dbh($h)->do("DROP TABLE IF EXISTS $TABLE");
  dbh($h)->do("CREATE TABLE $TABLE (id int PRIMARY KEY, name text)");
  $h->disconnect;
}
@warnings = ();

# --- 6. the control: a dying coderef on a healthy connection --------------------

{
  my $label = 'the coderef dies';
  my ($h, $pid) = warm($label);
  my ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub {
    $_[0]->([ 1, 'a' ]);
    $_[0]->([ 2, 'b' ]);
    die "coderef died\n";
  }));
  ok !$ok, "$label: the COPY fails";
  is $r[0], "coderef died\n", "$label: with the coderef's own error";
  is_deeply rows_loaded($h), [], "$label: the table holds nothing of the load";
  next_call($label, $h, $pid, 1);
  $h->disconnect;
}

# --- 1. the backend terminated inside the coderef -------------------------------
#
# What the coderef does once the backend is gone. after: its writes, each a
# code taking the writer. The pauses let the server's answer to a write -- the
# reset of the connection -- arrive before the next one.

my $pause = sub { Time::HiRes::sleep(0.3) };
my $big   = 'x' x 10_000;   # more than libpq keeps back: it sends in PQputCopyData
my @SHAPES = (
  { label => 'nothing more',
    after => [] },
  { label => 'three rows more',
    after => [ map { my $i = $_; sub { $_[0]->([ 10 + $i, 'more' ]) } } 1 .. 3 ] },
  { label => 'three thousand rows more',
    after => [ sub { $_[0]->([ 10 + $_, 'more' ]) for 1 .. 3000 } ] },
  { label => 'a row, a pause, a row and a big one',
    after => [ sub { $_[0]->([ 11, 'more' ]) }, $pause,
               sub { $_[0]->([ 12, 'more' ]) },
               sub { $_[0]->([ 13, $big ]) } ] },
  { label => 'a row, a pause, a row and two big ones',
    after => [ sub { $_[0]->([ 11, 'more' ]) }, $pause,
               sub { $_[0]->([ 12, 'more' ]) },
               sub { $_[0]->([ 13, $big ]) },
               sub { $_[0]->([ 14, $big ]) } ] },
);

# The ends a COPY comes to when its backend is gone: EV::Pg's own two, and the
# two libpq leaves to copy_in.
my $GONE = qr/^(?:connection lost|not connected|put_copy_data failed: |put_copy_end failed: )/;

for my $shape (@SHAPES) {
  for my $dies (0, 1) {
    my $label = "backend terminated, then $shape->{label}, the coderef "
      . ($dies ? 'dies in the end' : 'returns');
    my ($h, $pid) = warm($label);
    defined $pid or next;

    my $killed;
    my ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub {
      my ($put) = @_;
      $put->([ 1, 'a' ]);
      $put->([ 2, 'b' ]);
      $killed = terminate($h, $pid);
      $pause->();
      if ($dies) {
        # every write may die of the lost connection: this coderef goes on
        # and dies its own death
        eval { $_->($put); 1 } for @{ $shape->{after} };
        die "coderef died\n";
      }
      $_->($put) for @{ $shape->{after} };
    }));

    ok $killed, "$label: its backend is terminated";
    ok !$ok, "$label: the COPY fails" or diag "it loaded $r[0] row(s)";
    unlike $r[0], qr/watchdog|nothing left that could complete/,
      "$label: and does not stay pending";
    if ($dies) {
      is $r[0], "coderef died\n", "$label: with the coderef's own error";
    }
    else {
      like $r[0], $GONE, "$label: with the connection's end";
      note "$label: ", $r[0] =~ /\A([^\n]*)/;
    }
    settle();
    is_deeply rows_loaded($h), [], "$label: the table holds nothing of the load";
    @warnings = grep { !/^DBIO::PostgreSQL::EV pool error: / } @warnings;
    next_call($label, $h, $pid, 0);
    $h->disconnect;
  }
}

# --- 2. put_copy_end answers -1 on an open connection ---------------------------

for my $dies (0, 1) {
  my $label = 'put_copy_end answers -1 on an open connection, the coderef '
    . ($dies ? 'dies' : 'returns');
  my ($h, $pid) = warm($label);
  defined $pid or next;

  my ($ok, @r);
  {
    no strict 'refs';
    no warnings 'once';
    local *{"${CONN}::put_copy_end"} = sub { -1 };
    ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub {
      $_[0]->([ 1, 'a' ]);
      $_[0]->([ 2, 'b' ]);
      die "coderef died\n" if $dies;
    }));
  }
  ok !$ok, "$label: the COPY fails";
  if ($dies) {
    is $r[0], "coderef died\n", "$label: with the coderef's own error";
  }
  else {
    like $r[0], qr/^put_copy_end failed/, "$label: of the failing put_copy_end";
  }
  settle();
  is $h->pool->available, 0, "$label: its connection is not listed idle";
  is $h->pool->size, 0, "$label: nor counted any more";

  next_call($label, $h, $pid, 0);
  my $alive = 1;
  for (1 .. 50) {   # the server ends the backend when it reads the close
    ($alive) = dbh($h)->selectrow_array('SELECT count(*) FROM pg_stat_activity WHERE pid = ?', undef, $pid);
    last unless $alive;
    Time::HiRes::sleep(0.1);
  }
  is $alive, 0, "$label: the COPY's backend has ended";
  is_deeply rows_loaded($h), [], "$label: the table holds nothing of the load";
  $h->disconnect;
}

# --- 3. put_copy_data answers 0 for a row ---------------------------------------

for my $catches (0, 1) {
  my $label = 'put_copy_data answers 0 for the second of three rows'
    . ($catches ? ', the coderef catches the die and goes on' : '');
  my ($h, $pid) = warm($label);
  defined $pid or next;

  my ($ok, @r);
  {
    my $n = 0;
    no strict 'refs';
    no warnings 'once';
    local *{"${CONN}::put_copy_data"} = sub {
      return 0 if ++$n == 2;
      return $_[0]->EV::Pg::put_copy_data($_[1]);
    };
    ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub {
      my ($put) = @_;
      for my $i (1 .. 3) {
        if ($catches) { eval { $put->([ $i, 'row' ]); 1 } }
        else          { $put->([ $i, 'row' ]) }
      }
    }));
  }
  ok !$ok, "$label: the COPY fails" or diag "it loaded $r[0] row(s)";
  like $r[0], qr/^put_copy_data failed/, "$label: with the writer's error";
  settle();
  is_deeply rows_loaded($h), [], "$label: the table holds nothing of the load";
  next_call($label, $h, $pid, 1);
  $h->disconnect;
}

# --- 4. a writer kept beyond its COPY -------------------------------------------

{
  my $label = 'a writer kept beyond its COPY';
  my ($h, $pid) = warm($label);

  my $kept;
  my ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub { $kept = $_[0]; $kept->([ 1, 'first' ]) }));
  ok $ok, "$label: its COPY is done" or diag "it failed: $r[0]";
  settle();

  # A refusal of the transport's own: a DBIO::Exception naming the writer and
  # the caller's line (karr k88, maintainer's decision 2026-10-16) -- also
  # inside a COPY the EV loop runs. Until then a croaked string.
  my $line = __LINE__; my $between = eval { $kept->([ 98, 'between' ]); 1 } ? 'it put its row' : $@;
  isa_ok $between, 'DBIO::Exception', "$label: the refusal when no COPY is open";
  like $between, qr/^DBIO::PostgreSQL::EV::Storage::copy_in_writer\(\): copy_in: the writer was called outside its COPY at \Q$0\E line $line\n\z/,
    "$label: dies when no COPY is open, at the caller's line";

  my $inside;
  ($ok, @r) = wait_for($h->async->copy_in(@COPY, sub {
    my ($put) = @_;
    $put->([ 2, 'second' ]);
    $line = __LINE__; $inside = eval { $kept->([ 99, 'stale' ]); 1 } ? 'it put its row' : $@;
    $put->([ 3, 'second' ]);
  }));
  isa_ok $inside, 'DBIO::Exception', "$label: the refusal while the next COPY is open";
  like $inside, qr/^DBIO::PostgreSQL::EV::Storage::copy_in_writer\(\): copy_in: the writer was called outside its COPY at \Q$0\E line $line\n\z/,
    "$label: dies while the next COPY is open on its connection, at the caller's line";
  ok $ok, "$label: that COPY is done" or diag "it failed: $r[0]";
  is_deeply rows_loaded($h), [qw( first second second )],
    "$label: and the table holds each COPY's own rows, no other";
  next_call($label, $h, $pid, 1);

  dbh($h)->do("DROP TABLE IF EXISTS $TABLE");
  $h->disconnect;
}

done_testing;
