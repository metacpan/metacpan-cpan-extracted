use strict;
use warnings;
use Test::More;
use Storable ();

use DBIO::Forked::Future;

# Unit tests for the Future itself, driven by a pipe we feed by hand (no fork):
# write a frozen blob into the write end, hand the read end to the Future.
# pid is undef, so there is nothing to reap.

sub make_future {
  my ($payload, %opt) = @_;   # $payload: hashref to freeze, or undef to skip
  pipe(my $rh, my $wh) or die "pipe: $!";
  if (defined $payload) {
    print {$wh} Storable::freeze($payload);
    close $wh if !$opt{leave_open};
  }
  my $f = DBIO::Forked::Future->new(read_fh => $rh);
  return ($f, $wh);   # caller keeps $wh alive when leave_open
}

# --- success: is_ready true at EOF, get returns rows, idempotent ------------
{
  my ($f) = make_future({ rows => [ ['x'], ['y'] ] });
  ok($f->is_ready, 'is_ready true once a full blob is written and the pipe closed');
  ok(!$f->is_failed, 'is_failed false on success');
  is_deeply([ $f->get ], [ ['x'], ['y'] ], 'get returns the rows');
  is_deeply([ $f->get ], [ ['x'], ['y'] ], 'get is idempotent');
}

# --- error blob re-throws from get ------------------------------------------
{
  my ($f) = make_future({ error => "kaboom\n" });
  ok($f->is_failed, 'is_failed true for an error blob');
  my @r = eval { $f->get };
  ok($@, 'get dies for an error blob');
  like($@, qr/kaboom/, 'get re-throws the child error');
}

# --- is_ready is EOF-clean: bytes present but no EOF yet => not ready --------
{
  my ($f, $wh) = make_future(undef, leave_open => 1);
  syswrite($wh, 'partial');   # some bytes, write end still open => no EOF
  ok(!$f->is_ready, 'is_ready false: data available but no EOF (not a premature peek)');
  close $wh;                  # now EOF, but the buffer holds a non-Storable blob
  ok($f->is_ready, 'is_ready true once EOF arrives');
  ok($f->is_failed, 'a corrupt/partial blob surfaces as a failure, not a crash');
}

# --- then maps the resolved values ------------------------------------------
{
  my ($f) = make_future({ rows => [ [10], [20] ] });
  my $g = $f->then(sub { my @rows = @_; return scalar @rows });
  isa_ok($g, 'DBIO::Forked::Future', 'then returns a Forked::Future');
  is(($g->get)[0], 2, 'then maps the two rows to their count');
}

# --- catch recovers an error into a value -----------------------------------
{
  my ($f) = make_future({ error => "bad\n" });
  my $g = $f->catch(sub { my $e = shift; return "recovered:$e" });
  my @out = $g->get;
  like($out[0], qr/recovered:bad/, 'catch turns the error into a value');
  ok(!$g->is_failed, 'a recovered future is not failed');
}

# --- then propagates failure without calling its callback -------------------
{
  my ($f) = make_future({ error => "nope\n" });
  my $called = 0;
  my $g = $f->then(sub { $called = 1; return 'unreached' });
  eval { $g->get };
  like($@, qr/nope/, 'then propagates the source failure');
  is($called, 0, 'then callback is not run on a failed source');
}

# --- then flattens a returned future (chaining) -----------------------------
{
  my ($f) = make_future({ rows => [ ['a'] ] });
  my ($inner) = make_future({ rows => [ ['flattened'] ] });
  my $g = $f->then(sub { return $inner });   # callback returns another future
  is_deeply([ $g->get ], [ ['flattened'] ], 'then flattens a returned future');
}

# The three blocks below pin one property: a callback is a side effect (in real
# use it fires the next *_async, i.e. forks the next query), so it runs exactly
# once -- however often the derived future is polled while the future the
# callback returned is still pending. Polling must only wait, never re-fire.

# --- then: polling a pending returned future does not re-run the callback ----
{
  my ($f) = make_future({ rows => [ ['src'] ] });
  my ($inner, $wh) = make_future(undef, leave_open => 1);   # write end open => pending
  my $calls = 0;
  my $g = $f->then(sub { $calls++; return $inner });

  ok(!$g->is_ready,  "then: not ready while the returned future is pending (poll $_)") for 1 .. 3;
  ok(!$g->is_failed, 'then: not failed while the returned future is pending');
  is($calls, 1, 'then: callback ran once across four polls of a pending returned future');

  syswrite($wh, Storable::freeze({ rows => [ ['inner'] ] }));
  close $wh;
  ok($g->is_ready, 'then: ready once the returned future resolves');
  is_deeply([ $g->get ], [ ['inner'] ], 'then: get returns the returned future\'s rows');
  is($calls, 1, 'then: callback still ran exactly once after resolution');
}

# --- catch: same for the failure handler, and a blocking get after polls -----
{
  my ($f) = make_future({ error => "bad\n" });
  my ($inner, $wh) = make_future(undef, leave_open => 1);
  my $calls = 0;
  my $g = $f->catch(sub { $calls++; return $inner });

  ok(!$g->is_ready,  "catch: not ready while the returned future is pending (poll $_)") for 1 .. 3;
  ok(!$g->is_failed, 'catch: not failed while the returned future is pending');
  is($calls, 1, 'catch: handler ran once across four polls of a pending returned future');

  syswrite($wh, Storable::freeze({ rows => [ ['recovered'] ] }));
  close $wh;
  # straight to the blocking get, no is_ready in between
  is_deeply([ $g->get ], [ ['recovered'] ], 'catch: get after polls returns the returned future\'s rows');
  is($calls, 1, 'catch: handler still ran exactly once after get');
}

# --- a polled returned future that then FAILS fails the derived one, once ----
{
  my ($f) = make_future({ rows => [ ['src'] ] });
  my ($inner, $wh) = make_future(undef, leave_open => 1);
  my $calls = 0;
  my $g = $f->then(sub { $calls++; return $inner });

  ok(!$g->is_ready, 'failing inner: not ready while the returned future is pending') for 1 .. 2;

  syswrite($wh, Storable::freeze({ error => "inner boom\n" }));
  close $wh;
  ok($g->is_failed, 'failing inner: derived future is failed once the returned future fails');
  eval { $g->get };
  like($@, qr/inner boom/, 'failing inner: get re-throws the returned future\'s error');
  is($calls, 1, 'failing inner: callback ran exactly once');
}

done_testing;
