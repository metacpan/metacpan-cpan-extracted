use strict;
use warnings;
use Test::More;
use Future;

# OFFLINE test for karr #3 (core #70 share): the future_io transport now
# internalises '?'-dialect shaping.
#
# WHAT THIS PROVES:
#  1. _query_async / _query_async_pinned RECEIVE sql_maker '?'-placeholder
#     SQL and shape it into the driver dialect ('$N') INSIDE the transport,
#     before the query reaches the wire (_submit_query). No caller pre-shape.
#  2. Transition-window safety: feeding ALREADY-shaped SQL (contains '$N',
#     no bare '?') back through the same path leaves it UNCHANGED -- the
#     '?'->'$N' rewrite is idempotent -- including a literal '?' inside a
#     quoted string literal, which the shaper must never touch. This is why
#     core can keep shaping at its own call site during the PR train.

# --- ShapingMock: a concrete driver transport ---
# Inherits the REAL DBIO::Async::Storage::_query_async / _query_async_pinned
# (the code under test); overrides only the DB-specific seams. _transform_sql
# is a recognisable, quote-aware '?'->'$N' rewrite (the Pg-style dialect);
# _submit_query records the SQL that actually reaches the wire.

{
  package ShapingMock;
  use base 'DBIO::Async::Storage';
  use Future;

  # Quote-aware positional-placeholder rewrite: replace each BARE '?' with an
  # incrementing '$N', copying single-quoted string literals (with '' escapes)
  # verbatim so a '?' inside a literal is left alone. Text that is already
  # '$N' contains no bare '?', so a second pass is a no-op (idempotent).
  sub _transform_sql {
    my ($self, $sql) = @_;
    my $n   = 0;
    my $out = '';
    while (length $sql) {
      if ($sql =~ s/^('(?:[^']|'')*')//) {
        $out .= $1;                       # quoted literal, copied verbatim
      }
      elsif ($sql =~ s/^\?//) {
        $out .= '$' . (++$n);             # bare placeholder -> $N
      }
      elsif ($sql =~ s/^([^'?]+)//) {
        $out .= $1;                       # ordinary run
      }
      else {
        $out .= substr($sql, 0, 1, '');   # lone quote / fallback
      }
    }
    return $out;
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, $sql;        # capture the wire SQL
    return;
  }

  # Bypass the Future::IO fd seam (no real socket in an offline test) and
  # resolve everything synchronously so ->get returns without a loop.
  sub _await_readable { Future->done }
  sub _collect_result { Future->done([1]) }
  sub _conn_ready     { 1 }

  sub _create_pool_connection   { {} }
  sub _shutdown_pool_connection { }
  sub _normalize_conninfo       { $_[1] }
}

sub new_storage {
  my $storage = ShapingMock->new(undef);
  $storage->connect_info([{ host => 'localhost' }]);
  return $storage;
}

# --- 1. pooled path: '?' dialect shaped to '$N' before it hits the wire ---

{
  my $storage = new_storage;
  my $f = $storage->_query_async(
    'SELECT * FROM t WHERE a = ? AND b = ?', ['x', 'y']
  );
  $f->get;

  is $storage->{wire}[0],
    'SELECT * FROM t WHERE a = $1 AND b = $2',
    'pooled _query_async shapes ?->$N internally (wire sees driver dialect)';
}

# --- 2. pinned (txn) path: same internal shaping ---

{
  my $storage = new_storage;
  my $conn    = $storage->pool->acquire->get;
  my $f = $storage->_query_async_pinned(
    $conn, 'INSERT INTO t (x, y) VALUES (?, ?)', ['v', 'w']
  );
  $f->get;

  is $storage->{wire}[0],
    'INSERT INTO t (x, y) VALUES ($1, $2)',
    'pinned _query_async_pinned shapes ?->$N internally too';
}

# --- 3. transition-window idempotency through the real _query_async path ---
# Already-shaped SQL ('$N', no bare '?') fed back through the shaping path is
# unchanged -- and a literal '?' inside a quoted string literal survives. This
# is the double-shape safety net for the core #70 PR train.

{
  my $storage = new_storage;
  my $shaped  =
    q{SELECT * FROM t WHERE a = $1 AND note = 'why? really' AND b = $2};
  my $f = $storage->_query_async($shaped, ['x', 'y']);
  $f->get;

  is $storage->{wire}[0], $shaped,
    'already-shaped SQL passes through _query_async unchanged '
    . '(idempotent double-shape; ? inside quoted literal untouched)';
}

# --- 4. _transform_sql itself: the edge cases the ticket calls out ---

{
  my $storage = new_storage;

  is $storage->_transform_sql('a = ? AND b = ?'),
    'a = $1 AND b = $2',
    '_transform_sql rewrites bare ? to positional $N';

  is $storage->_transform_sql(q{UPDATE t SET label = 'huh?' WHERE id = $1}),
    q{UPDATE t SET label = 'huh?' WHERE id = $1},
    '_transform_sql leaves existing $N and a ? inside a quoted literal untouched';

  is $storage->_transform_sql(q{WHERE note = 'a?b' AND x = ? AND y = ?}),
    q{WHERE note = 'a?b' AND x = $1 AND y = $2},
    '_transform_sql rewrites only bare ?, skipping the ? inside the literal';
}

done_testing;
