use strict;
use warnings;

use Test::More;

# karr k63 -- PostgreSQL advisory-lock helpers on DBIO::PostgreSQL::Storage.
# OFFLINE: no DBI, no DSN, no server. Every lock helper renders a FROM-less
# SELECT of the pg_advisory_* function and reads its single-column result
# through _execute_rendered -- the same rendered-statement path results_exist
# uses (t/44) -- so the mock storage captures the exact SQL and binds, and its
# mock() facility feeds a 't'/'f' result back to the bool-returning helpers.
#
# Without the helpers on the driver this file dies at the first method call:
# the methods simply do not exist yet.

use DBIO::Test;
use DBIO::PostgreSQL::Storage;

sub new_storage {
  my $schema = DBIO::Test->init_schema(
    no_deploy    => 1,
    storage_type => 'DBIO::PostgreSQL::Storage',
  );
  return $schema->storage;
}

# --- exact SQL and binds: session-level, single key ------------------------
{
  my $storage = new_storage;
  $storage->reset_captured;

  $storage->pg_advisory_lock(42);

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'pg_advisory_lock issues exactly one statement';
  is $q[0]{sql}, 'SELECT pg_advisory_lock(?)',
    '... the single-key form binds one placeholder';
  is_deeply [ map { $_->[1] } @{ $q[0]{bind} } ], [42],
    '... with the key bound, not interpolated';
}

# --- exact SQL and binds: session-level, two keys --------------------------
{
  my $storage = new_storage;
  $storage->reset_captured;

  $storage->pg_advisory_lock(10, 20);

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'pg_advisory_lock(a, b) issues one statement';
  is $q[0]{sql}, 'SELECT pg_advisory_lock(?, ?)',
    '... the two-key form binds two placeholders';
  is_deeply [ map { $_->[1] } @{ $q[0]{bind} } ], [10, 20],
    '... with both keys bound in order';
}

# --- the shared / xact spellings dispatch to the right function ------------
{
  my $storage = new_storage;
  $storage->reset_captured;

  $storage->pg_advisory_lock_shared(1);
  $storage->pg_advisory_xact_lock(2);
  $storage->pg_advisory_xact_lock_shared(3);

  my @sql = map { $_->{sql} } $storage->captured_queries;
  is_deeply \@sql, [
    'SELECT pg_advisory_lock_shared(?)',
    'SELECT pg_advisory_xact_lock(?)',
    'SELECT pg_advisory_xact_lock_shared(?)',
  ], 'shared and xact lock helpers each render their own function';
}

# --- unlock_all takes no key and renders no placeholders -------------------
{
  my $storage = new_storage;
  $storage->reset_captured;

  $storage->pg_advisory_unlock_all;

  my @q = $storage->captured_queries;
  is scalar @q, 1, 'pg_advisory_unlock_all issues one statement';
  is $q[0]{sql}, 'SELECT pg_advisory_unlock_all()',
    '... with no placeholders at all';
  is_deeply $q[0]{bind}, [], '... and no binds';
}

# --- bool return: try-lock, acquired vs not --------------------------------
#
# The mock() facility returns the registered rows for a matching statement, so
# a single-column 't' / 'f' stands in for what pg_try_advisory_lock answers.
{
  my $storage = new_storage;
  $storage->mock(qr/pg_try_advisory_lock\(/, [['t']]);
  ok $storage->pg_try_advisory_lock(42),
    'pg_try_advisory_lock returns true for a "t" result';

  $storage->mock(qr/pg_try_advisory_lock\(/, [['f']]);
  ok !$storage->pg_try_advisory_lock(42),
    'pg_try_advisory_lock returns false for an "f" result';
}

# --- bool return: unlock, released vs not ----------------------------------
{
  my $storage = new_storage;
  $storage->mock(qr/pg_advisory_unlock\(/, [['t']]);
  ok $storage->pg_advisory_unlock(42),
    'pg_advisory_unlock returns true when a lock was released';

  $storage->mock(qr/pg_advisory_unlock\(/, [['f']]);
  ok !$storage->pg_advisory_unlock(42),
    'pg_advisory_unlock returns false when nothing was held';
}

# --- bool return: the '1'/'0' spelling DBD::Pg uses without pg_bool_tf -----
{
  my $storage = new_storage;
  $storage->mock(qr/pg_try_advisory_xact_lock\(/, [['1']]);
  ok $storage->pg_try_advisory_xact_lock(7),
    'a "1" result is truthy too (pg_bool_tf off)';

  $storage->mock(qr/pg_try_advisory_xact_lock\(/, [['0']]);
  ok !$storage->pg_try_advisory_xact_lock(7),
    '... and a "0" result is falsy';
}

# --- wrong argument count throws -------------------------------------------
{
  my $storage = new_storage;

  eval { $storage->pg_advisory_lock() };
  like $@, qr/requires either one bigint key or two int keys/,
    'no key at all is a clear exception';

  eval { $storage->pg_advisory_lock(1, 2, 3) };
  like $@, qr/requires either one bigint key or two int keys/,
    'three keys is a clear exception';

  eval { $storage->pg_advisory_unlock_all(1) };
  like $@, qr/takes no key arguments/,
    'unlock_all with a key is a clear exception';
}

done_testing;
