use strict;
use warnings;
use Test::More;
use Test::Exception;

# Regression test for karr #13:
#   "copy_in releases pool connection while COPY stream still in flight
#    on the wire"
#
# Storage.pm:copy_in used to call $self->pool->release($pg) synchronously
# immediately after $pg->put_copy_end. EV::Pg only signals "COPY stream
# accepted" at that point — libpq has not yet drained the buffered bytes,
# applied the rows, or sent CommandComplete + ReadyForQuery. Handing the
# connection back to the pool at that moment means the very next
# pool->acquire on the same Storage may hand out the same still-busy
# connection; libpq then refuses the new query with
#   "PQsendQueryParams failed: another command is already in progress"
# and the Storage's CRUD Future fails.
#
# The fix (Storage.pm:copy_in) waits for EV::Pg's SECOND callback firing
# (the one that delivers the final cmd_tuples after libpq has actually
# finished the COPY) before releasing the connection. This test would
# fail loudly against the original implementation and pass against the
# fixed one. It runs the cycle THREE times back-to-back because the bug
# is timing-sensitive: the pool typically has 5 idle slots, so the first
# copy_in is usually followed by an acquire that picks a DIFFERENT idle
# connection; the bug surfaces once the same Storage cycles the same
# physical connection. Three iterations exercise both code paths.
#
# Pre-fix behavior on this test:
#   - iteration 1: first select_async after copy_in picks a different
#     idle connection (or, if pool_size == 1, hits the still-busy one);
#     not always a hard fail, so we run it three times.
#   - iterations 2+3: same connection gets reused, libpq returns
#     "another command is already in progress", select_async Future fails.
#
# Post-fix behavior:
#   - every iteration's follow-up select_async succeeds and returns the
#     rows that were just COPY-loaded.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# Parse DSN into a libpq conninfo hash (same convention as t/10-t/18).
my $dsn  = $ENV{DBIO_TEST_PG_DSN};
my $user = $ENV{DBIO_TEST_PG_USER} || '';
my $pass = $ENV{DBIO_TEST_PG_PASS} || '';

my %ci;
if ($dsn =~ /^dbi:Pg:(.+)/i) {
  for my $kv (split /;/, $1) {
    my ($k, $v) = split /=/, $kv, 2;
    next unless defined $k && length $k;
    $k = 'dbname' if $k eq 'database';
    $ci{$k} = $v;
  }
} else {
  for my $kv (split /\s+/, $dsn) {
    my ($k, $v) = split /=/, $kv, 2;
    $ci{$k} = $v if defined $k && length $k;
  }
}
$ci{user}     = $user if length $user;
$ci{password} = $pass if length $pass;

# Drive a Future to completion on the EV loop under a wall-clock guard.
sub await_guarded {
  my ($f, $what) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT awaiting $what\n" };
  alarm 20;
  EV::run(EV::RUN_ONCE) until $f->is_ready;
  alarm 0;
  return $f;
}

sub run_raw {
  my ($storage, $sql) = @_;
  my $f = $storage->pool->acquire->then(sub {
    my $pg  = shift;
    my $rf  = Future->new;
    $pg->query($sql, sub {
      my (undef, $err) = @_;
      $storage->pool->release($pg);
      $err ? $rf->fail($err) : $rf->done;
    });
    return $rf;
  });
  return await_guarded($f, "run_raw: $sql")->get;
}

my $table = 'dbio_copy_in_regression';

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ \%ci, {} ]);

run_raw($storage, "DROP TABLE IF EXISTS $table");
run_raw($storage,
  "CREATE TABLE $table (id int PRIMARY KEY, name text, score int)"
);

# --- the actual regression: same-storage copy_in + select_async N times ---
# Iterate 3x to force the pool to cycle the same physical connection. With
# only 1 connection in the pool (default for tests), the bug fires on the
# 1st iteration. With 5 connections (also default in some configs) it
# typically fires by the 3rd.

my $ROWS_PER_ITER = 4;
for my $iter (1..3) {
  # Load $ROWS_PER_ITER unique rows for this iteration.
  await_guarded(
    $storage->copy_in($table, [ 'id', 'name', 'score' ], sub {
      my ($put) = @_;
      for my $i (1..$ROWS_PER_ITER) {
        my $row_id = ($iter - 1) * $ROWS_PER_ITER + $i;
        $put->([ $row_id, "iter-$iter-row-$i", $row_id * 100 ]);
      }
    }),
    "iter $iter: copy_in",
  )->get;

  # THE regression assertion: a same-storage select_async immediately
  # after copy_in must succeed and return the rows we just loaded.
  # Before the fix this Future either fails with "another command is
  # already in progress" or returns rows from a stale prior state.
  my $f = $storage->select_async($table, [ 'id', 'name', 'score' ], {});
  my @rows = await_guarded(
    $f, "iter $iter: select_async after copy_in"
  )->get;

  is scalar(@rows), $iter * $ROWS_PER_ITER,
    "iter $iter: select_async returned all $iter*$ROWS_PER_ITER rows (regression: same-storage follow-up works)";

  my %by_id = map { $_->[0] => $_ } @rows;
  my $first_id = ($iter - 1) * $ROWS_PER_ITER + 1;
  my $last_id  = $iter * $ROWS_PER_ITER;
  is_deeply $by_id{$first_id},
    [ $first_id, "iter-$iter-row-1", $first_id * 100 ],
    "iter $iter: first row of this iteration matches what copy_in wrote";
  is_deeply $by_id{$last_id},
    [ $last_id, "iter-$iter-row-$ROWS_PER_ITER", $last_id * 100 ],
    "iter $iter: last row of this iteration matches what copy_in wrote";
}

# --- cleanup -------------------------------------------------------------

my $cleanup = DBIO::PostgreSQL::EV::Storage->new(undef);
$cleanup->connect_info([ \%ci, {} ]);
run_raw($cleanup, "DROP TABLE IF EXISTS $table");
$cleanup->disconnect;
$storage->disconnect;

done_testing;