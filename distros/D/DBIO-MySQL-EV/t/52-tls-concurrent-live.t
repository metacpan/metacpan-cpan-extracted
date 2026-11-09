use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use Fcntl ();

# LIVE: the ev transport is concurrent over TLS (karr k85).
#
# libmariadb (3.4.9) leaves the socket of a TLS connection blocking, and its
# asynchronous TLS read/write then block in the kernel: a bare EV::MariaDB
# handle with ssl_cipher holds the whole event loop for every statement
# (query() returns after the round trip, its callback runs inside it, no timer
# ticks; docs/upstream/ev-mariadb-tls-blocks-the-loop.md). The transport works
# around it: DBIO::MySQL::EV::Pool::_mysql_new_handle, where every handle of
# this dist is made, sets O_NONBLOCK on the socket in the handle's on_connect
# (and so again after every reconnect) -- on every handle (karr k95), not only
# one whose connect info has a ssl_* parameter: the connect info does not say
# whether TLS was negotiated, and over plain TCP the flag changes nothing
# (measured on MySQL 8.0 and MariaDB 11.8, part 1 holds it). libmariadb 3.4.9
# negotiated no TLS against either server without a ssl_* parameter
# (Ssl_cipher empty); part 1 is that connect info, and would still pass if a
# server one day made it TLS.
#
# This file holds that work-around, on a handle made the way the transport makes
# it:
#
#   1. no ssl_* parameter (clear text on these servers): the socket is
#      non-blocking, statements leave the loop running, big results and
#      parameters, reset and close behave as ever
#   2. TLS: the same, for query() and for prepare/execute; the socket is
#      non-blocking, the session really speaks TLS; close_stmt works
#   3. TLS: a reconnect (reset) gets the flag again
#   4. TLS: close_async and finish end without a hang or an error, and the
#      server's session is gone afterwards (the TLS shutdown)
#   5. TLS through the transport: two statements on two pooled connections
#      overlap (0.5 s each, together well under 1 s)
#
# A bare handle (no work-around) is measured as a control and only reported:
# the day libmariadb leaves the socket non-blocking itself, the work-around is
# redundant and the diag line says so -- nothing here turns red for that.
#
# The measure is a 50 ms EV timer during SELECT SLEEP(0.5): ~10 ticks when the
# loop runs, 0 when it is held. Generous thresholds (>= 3), so a loaded machine
# does not flip it.
#
# Limits, deliberately not claimed: the connect and the TLS handshake still
# block the loop (the flag is set after them).
#
# Gated like the other live tests: DBIO_TEST_MYSQL_DSN (dbi:mysql: or
# dbi:MariaDB:), _USER, _PASS, plus EV and EV::MariaDB. Without TLS on the
# server the TLS parts skip.

use DBIO::MySQL::EV::TestHarness;

DBIO::MySQL::EV::TestHarness->skip_all_unless_live;

use EV;
use EV::MariaDB;
use DBIO::MySQL::EV::ConnectInfo ();
use DBIO::MySQL::EV::Pool ();

alarm 120;
$SIG{ALRM} = sub { BAIL_OUT('t/52: alarm, the file hung') };

my @INFO = ($ENV{DBIO_TEST_MYSQL_DSN}, $ENV{DBIO_TEST_MYSQL_USER}, $ENV{DBIO_TEST_MYSQL_PASS});

# Waits for $cond to hold, bounded.
sub run_until {
  my ($cond, $limit) = @_;
  my $end = Time::HiRes::time() + ($limit // 10);
  EV::run(EV::RUN_ONCE) until $cond->() || Time::HiRes::time() > $end;
  return $cond->() ? 1 : 0;
}

# Connects a handle; returns it, or (undef, $error). $how is 'transport' (made
# by the pool's handle seam, as the transport makes it) or 'bare'
# (EV::MariaDB->new). $connects counts on_connect calls.
sub connect_handle {
  my ($tls, $how, $connects) = @_;
  my ($conninfo) = @{ DBIO::MySQL::EV::ConnectInfo::dbi_to_conninfo(
    [ $INFO[0] . ($tls ? ';ssl_cipher=DEFAULT' : ''), @INFO[1, 2] ]
  ) };
  delete $conninfo->{pool_size};
  my ($ready, $err);
  my %args = (
    %$conninfo,
    on_connect => sub { $$connects++ if $connects; $ready = 1 },
    on_error   => sub { $err //= join ' ', grep { defined } @_; $ready //= 0 },
  );
  my $mdb = $how eq 'bare'
    ? EV::MariaDB->new(%args)
    : DBIO::MySQL::EV::Pool->_mysql_new_handle(%args);
  run_until(sub { defined $ready }) or return (undef, 'connect timed out');
  return $ready ? ($mdb) : (undef, $err // 'connect failed');
}

sub is_nonblocking {
  my ($mdb) = @_;
  my $fd = $mdb->socket;
  return undef unless defined $fd && $fd =~ /\A[0-9]+\z/;
  open(my $dup, '+<&', $fd) or return undef;
  my $flags = fcntl($dup, Fcntl::F_GETFL(), 0);
  close $dup;
  return undef unless defined $flags;
  return ($flags & Fcntl::O_NONBLOCK()) ? 1 : 0;
}

sub query_rows {
  my ($mdb, $sql) = @_;
  my ($got, $rows, $err);
  $mdb->query($sql, sub { ($rows, $err) = @_; $got = 1 });
  run_until(sub { $got });
  return ($rows, $err);
}

sub cipher_of {
  my ($mdb) = @_;
  my ($rows) = query_rows($mdb, "SHOW SESSION STATUS LIKE 'Ssl_cipher'");
  return $rows && $rows->[0] ? $rows->[0][1] // '' : '';
}

# Runs $start->($cb) while a 50 ms timer counts; returns how long the start call
# took, whether the callback ran inside it, the ticks and the elapsed time at
# the callback.
sub measure {
  my ($start) = @_;
  my $ticks = 0;
  my $timer = EV::timer(0.05, 0.05, sub { $ticks++ });
  my ($in_call, $inside, $elapsed, $fin, $res, $err) = (1);
  my $t0 = Time::HiRes::time();
  $start->(sub {
    ($res, $err) = @_;
    $inside  = $in_call;
    $elapsed = Time::HiRes::time() - $t0;
    $fin     = 1;
  });
  $in_call = 0;
  my $took = Time::HiRes::time() - $t0;
  run_until(sub { $fin });
  undef $timer;
  return +{
    ticks => $ticks, inside => $inside ? 1 : 0, took => $took,
    elapsed => $elapsed, res => $res, err => $err,
  };
}

sub sleep_query { my ($mdb) = @_; measure(sub { $mdb->query('SELECT SLEEP(0.5)', $_[0]) }) }

# prepare + execute SLEEP(?) + close_stmt; returns the measure of the execute and
# the outcome of the prepare and close_stmt.
sub sleep_prepared {
  my ($mdb) = @_;
  my ($stmt, $perr, $pdone);
  my $pm = measure(sub { my $cb = shift; $mdb->prepare('SELECT SLEEP(?)', sub { ($stmt, $perr) = @_; $cb->(@_) }) });
  my $em = $stmt ? measure(sub { my $cb = shift; $mdb->execute($stmt, [ 0.5 ], $cb) }) : undef;
  my ($cok, $cerr);
  if ($stmt) {
    my $done;
    $mdb->close_stmt($stmt, sub { ($cok, $cerr) = @_; $done = 1 });
    run_until(sub { $done });
  }
  return +{ prepare => $pm, perr => $perr, execute => $em, close_ok => $cok, close_err => $cerr };
}

sub report {
  my ($label, $m) = @_;
  diag sprintf '%s: call took %.3fs, callback inside the call=%d, ticks=%d, answered after %.3fs',
    $label, @$m{qw(took inside ticks elapsed)};
}

sub concurrent_ok {
  my ($m, $what) = @_;
  cmp_ok $m->{elapsed}, '>=', 0.4, "$what: the statement took its 0.5 s";
  ok !$m->{inside}, "$what: the callback does not run inside the call";
  cmp_ok $m->{took}, '<', 0.2, "$what: the call returns at once";
  cmp_ok $m->{ticks}, '>=', 3, "$what: the 50 ms timer ticked meanwhile (~10 expected)";
}

# ------------------------------------------------------------ 1. plain TCP
subtest 'no ssl_* parameter (clear text on these servers): the loop runs while the server sleeps' => sub {
  my ($mdb, $err) = connect_handle(0, 'transport');
  plan skip_all => "no connection: $err" unless $mdb;
  my $cipher = cipher_of($mdb);
  diag 'no ssl_* parameter: ' . (length $cipher ? "the session speaks TLS ($cipher)" : 'the session is clear text');
  is is_nonblocking($mdb), 1, 'the transport made the socket non-blocking (k95: every handle)';
  my $m = sleep_query($mdb);
  report('plain query', $m);
  concurrent_ok($m, 'query');
  my $p = sleep_prepared($mdb);
  ok $p->{execute}, 'prepare worked' or diag $p->{perr};
  if ($p->{execute}) {
    concurrent_ok($p->{execute}, 'execute');
    is_deeply [ @{ $p->{execute}{res} // [] } ], [ [0] ], 'SLEEP returned its row' or diag $p->{execute}{err};
    ok $p->{close_ok}, 'close_stmt worked' or diag $p->{close_err};
  }

  my ($rows) = query_rows($mdb, q{SELECT REPEAT('ab', 3000000)});
  is length($rows && $rows->[0][0] // ''), 6_000_000, 'a 6 MB result set arrives whole';
  my ($stmt, $got, $big);
  $mdb->prepare('SELECT LENGTH(?)', sub { ($stmt) = @_; $got = 1 });
  run_until(sub { $got });
  $got = 0;
  $mdb->execute($stmt, [ 'x' x 12_000_000 ], sub { ($big) = @_; $got = 1 });
  run_until(sub { $got });
  is $big && $big->[0][0], 12_000_000, 'a 12 MB bound parameter goes out whole';
  $got = 0;
  $mdb->close_stmt($stmt, sub { $got = 1 });
  run_until(sub { $got });

  my $connects = 0;
  my ($r) = connect_handle(0, 'transport', \$connects);
  if ($r) {
    $r->reset;
    ok run_until(sub { $connects >= 2 }), 'reset: on_connect fired again';
    is is_nonblocking($r), 1, 'reset: the socket of the new session is non-blocking';
    my $rm = sleep_query($r);
    concurrent_ok($rm, 'query after reset');
    ($rows) = query_rows($r, 'SELECT 1+1');
    is $rows && $rows->[0][0], 2, 'reset: the handle is usable';
    my ($done, $cerr);
    $r->close_async(sub { (undef, $cerr) = @_; $done = 1 });
    ok run_until(sub { $done }, 5), 'close_async called back, no hang';
    ok !$cerr, 'close_async: no error' or diag $cerr;
  }

  my ($bare) = connect_handle(0, 'bare');
  diag 'control: the bare no-ssl handle is ' . (is_nonblocking($bare) ? 'already non-blocking' : 'blocking') if $bare;
};

# -------------------------------------------------------------------- 2. TLS
subtest 'TLS: statements leave the loop running (karr k85 work-around)' => sub {
  my ($mdb, $err) = connect_handle(1, 'transport');
  plan skip_all => "no TLS connection to this server: $err" unless $mdb;
  my $cipher = cipher_of($mdb);
  plan skip_all => 'the server did not offer TLS (Ssl_cipher empty)' unless length $cipher;
  pass "the session really speaks TLS ($cipher)";
  is is_nonblocking($mdb), 1, 'the transport made the socket non-blocking';

  my $m = sleep_query($mdb);
  report('tls query', $m);
  concurrent_ok($m, 'query');

  my $p = sleep_prepared($mdb);
  ok $p->{execute}, 'prepare worked' or diag $p->{perr};
  if ($p->{execute}) {
    report('tls prepare', $p->{prepare});
    report('tls execute', $p->{execute});
    concurrent_ok($p->{execute}, 'execute');
    is_deeply [ @{ $p->{execute}{res} // [] } ], [ [0] ], 'SLEEP returned its row' or diag $p->{execute}{err};
    ok $p->{close_ok}, 'close_stmt worked' or diag $p->{close_err};
  }
  my ($rows) = query_rows($mdb, 'SELECT 1+1');
  is $rows && $rows->[0][0], 2, 'the handle is usable after all of it';

  # A non-blocking socket means partial reads and writes of TLS records: a
  # result and a parameter far larger than the socket buffers must come through whole.
  ($rows) = query_rows($mdb, q{SELECT REPEAT('ab', 3000000)});
  is length($rows && $rows->[0][0] // ''), 6_000_000, 'a 6 MB result set over the non-blocking TLS socket arrives whole';
  my ($stmt, $got, $big);
  $mdb->prepare('SELECT LENGTH(?)', sub { ($stmt) = @_; $got = 1 });
  run_until(sub { $got });
  $got = 0;
  $mdb->execute($stmt, [ 'x' x 5_000_000 ], sub { ($big) = @_; $got = 1 });
  run_until(sub { $got });
  is $big && $big->[0][0], 5_000_000, 'a 5 MB bound parameter goes out whole';
  $got = 0;
  $mdb->close_stmt($stmt, sub { $got = 1 });
  run_until(sub { $got });

  # The control: a bare handle, no work-around. Reported only.
  my ($bare) = connect_handle(1, 'bare');
  if ($bare) {
    my $nb = is_nonblocking($bare);
    my $b  = sleep_query($bare);
    report('tls BARE handle (control, not asserted)', $b);
    diag 'control: the bare TLS handle is ' . ($nb ? 'ALREADY non-blocking -- libmariadb fixed it, the work-around is redundant'
                                                    : 'blocking, as in docs/upstream/ev-mariadb-tls-blocks-the-loop.md');
  }
};

# ------------------------------------------------------------- 3. reconnect
subtest 'TLS: a reconnect gets the non-blocking socket again' => sub {
  my $connects = 0;
  my ($mdb, $err) = connect_handle(1, 'transport', \$connects);
  plan skip_all => "no TLS connection to this server: $err" unless $mdb;
  plan skip_all => 'the server did not offer TLS' unless length cipher_of($mdb);
  is $connects, 1, 'connected once';
  my ($rows) = query_rows($mdb, 'SELECT CONNECTION_ID()');
  my $before = $rows && $rows->[0][0];

  $mdb->reset;
  ok run_until(sub { $connects >= 2 }), 'on_connect fired again after reset' or return;
  is is_nonblocking($mdb), 1, 'the socket of the new session is non-blocking';
  ($rows) = query_rows($mdb, 'SELECT CONNECTION_ID()');
  my $after = $rows && $rows->[0][0];
  ok $before && $after && $before != $after, 'it is a new session';
  length cipher_of($mdb) ? pass('... still TLS') : fail('... still TLS');

  my $m = sleep_query($mdb);
  report('tls query after reset', $m);
  concurrent_ok($m, 'query after reset');
  my $p = sleep_prepared($mdb);
  concurrent_ok($p->{execute}, 'execute after reset') if $p->{execute};
};

# ---------------------------------------------------- 4. close, TLS shutdown
subtest 'TLS: close_async and finish end cleanly, the session is gone' => sub {
  my ($admin, $aerr) = connect_handle(0, 'transport');
  plan skip_all => "no admin connection: $aerr" unless $admin;

  my $session_count = sub {
    my ($id) = @_;
    my ($rows) = query_rows($admin, "SELECT COUNT(*) FROM information_schema.PROCESSLIST WHERE ID = $id");
    return $rows ? $rows->[0][0] : undef;
  };

  for my $way (qw(close_async finish)) {
    my ($mdb, $err) = connect_handle(1, 'transport');
    plan skip_all => "no TLS connection to this server: $err" unless $mdb;
    plan skip_all => 'the server did not offer TLS' unless length cipher_of($mdb);
    my ($rows) = query_rows($mdb, 'SELECT CONNECTION_ID()');
    my $id = $rows->[0][0];
    is $session_count->($id), 1, "$way: the session $id is on the server";

    my ($done, $cerr, $warn);
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    my $t0 = Time::HiRes::time();
    if ($way eq 'close_async') {
      $mdb->close_async(sub { (undef, $cerr) = @_; $done = 1 });
      ok run_until(sub { $done }, 5), 'close_async called back, no hang';
    }
    else {
      eval { $mdb->finish; 1 } or $cerr = $@;
      $done = 1;
    }
    diag sprintf '%s took %.3fs', $way, Time::HiRes::time() - $t0;
    ok !$cerr, "$way: no error" or diag $cerr;
    ok !$warn, "$way: no warning" or diag $warn;
    my $gone = run_until(sub { ($session_count->($id) // 1) == 0 }, 5);
    ok $gone, "$way: the server's session is gone";
    undef $mdb;   # DESTROY after the close must not hang or die either
    pass "$way: the handle was dropped";
  }
};

# ------------------------------------------------- 5. through the transport
subtest 'TLS through the transport: two pooled connections overlap' => sub {
  my $dsn = $INFO[0] . ';ssl_cipher=DEFAULT';
  my $h = eval {
    my $x = DBIO::MySQL::EV::TestHarness->new(dsn => $dsn, connect_attrs => { pool_size => 2 });
    $x->warm_pool;
    $x;
  };
  plan skip_all => "no TLS transport to this server: " . ($@ // '') unless $h;
  my $async = $h->async;

  my $f = $async->_query_async("SHOW SESSION STATUS LIKE 'Ssl_cipher'");
  run_until(sub { $f->is_ready });
  my $row = $f->is_done ? ($f->get)[0] : undef;
  plan skip_all => 'the server did not offer TLS' unless $row && length($row->[1] // '');
  pass "the pooled session speaks TLS ($row->[1])";

  # Warm both connections of the pool, then time two SLEEPs side by side.
  my @warm = map { $async->_query_async('SELECT SLEEP(0.1)') } 1 .. 2;
  run_until(sub { !grep { !$_->is_ready } @warm });

  my $ticks = 0;
  my $timer = EV::timer(0.05, 0.05, sub { $ticks++ });
  my $t0 = Time::HiRes::time();
  my @f = map { $async->_query_async('SELECT SLEEP(0.5)') } 1 .. 2;
  run_until(sub { !grep { !$_->is_ready } @f });
  my $elapsed = Time::HiRes::time() - $t0;
  undef $timer;
  diag sprintf 'two SLEEP(0.5) over TLS on two pooled connections: %.3fs, ticks=%d', $elapsed, $ticks;
  ok !(grep { !$_->is_done } @f), 'both statements succeeded';
  cmp_ok $elapsed, '<', 0.9, 'they overlapped (serial would be >= 1.0 s)';
  cmp_ok $ticks, '>=', 3, 'the loop kept turning meanwhile';
  eval { $h->disconnect };
};

done_testing;
