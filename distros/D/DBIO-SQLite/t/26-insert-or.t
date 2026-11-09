use strict;
use warnings;

use Test::More;

use DBIO::SQLite::Test ':DiffSQL';

# karr k38 -- SQLite's OR-conflict clause on INSERT: INSERT OR IGNORE and
# INSERT OR REPLACE. It sits between the INSERT keyword and INTO, and is a
# DIFFERENT mechanism from the statement-tail ON CONFLICT clause of the atomic
# upsert (ADR 0036, exercised in t/21-upsert.t).
#
# The driver SQLMaker consumes an `insert_or` option from the same $options
# transport that already carries on_conflict and returning: it is deleted
# before delegating to the generic insert, and the OR-clause is spliced in
# afterwards. Without the option the statement is byte-for-byte the plain
# INSERT INTO it always was -- the same regression-safety on_conflict has.

my $schema = DBIO::SQLite::Test->init_schema( no_populate => 1 );
my $sm     = $schema->storage->sql_maker;

# --------------------------------------------------------- no option: unchanged

is_same_sql_bind (
  sql_bind( $sm->insert( 'artist', { name => 'x', rank => 2 }, {} ) ),
  'INSERT INTO "artist" ("name", "rank") VALUES (?, ?)',
  [ [ name => 'x' ], [ rank => 2 ] ],
  'without insert_or the statement is a plain INSERT INTO',
);

# ------------------------------------------------------------ INSERT OR IGNORE

{
  my ($sql, @bind) = $sm->insert(
    'artist', { name => 'x', rank => 2 }, { insert_or => 'ignore' },
  );

  is (
    $sql,
    'INSERT OR IGNORE INTO "artist" ("name", "rank") VALUES (?, ?)',
    "insert_or => 'ignore' emits INSERT OR IGNORE INTO",
  );

  is_deeply (
    \@bind,
    [ [ 'name', 'x' ], [ 'rank', 2 ] ],
    '... with the same bind values as a plain insert',
  );
}

# ----------------------------------------------------------- INSERT OR REPLACE

{
  my ($sql, @bind) = $sm->insert(
    'artist', { name => 'x', rank => 2 }, { insert_or => 'replace' },
  );

  is (
    $sql,
    'INSERT OR REPLACE INTO "artist" ("name", "rank") VALUES (?, ?)',
    "insert_or => 'replace' emits INSERT OR REPLACE INTO",
  );

  is_deeply (
    \@bind,
    [ [ 'name', 'x' ], [ 'rank', 2 ] ],
    '... with the same bind values as a plain insert',
  );
}

# ---------------------------------------------------- the option is consumed

{
  my $options = { insert_or => 'ignore' };
  $sm->insert( 'artist', { name => 'x' }, $options );

  is_deeply (
    $options,
    {},
    'insert_or is deleted from $options -- consumed like on_conflict, so it '
  . 'never reaches the generic insert or lingers in the transport',
  );
}

# ------------------------------------------------ an unknown mode fails loud

{
  my $ok = eval {
    $sm->insert( 'artist', { name => 'x' }, { insert_or => 'rollback' } );
    1;
  };
  my $err = $@;

  ok ( ! $ok, 'an unsupported insert_or mode throws rather than mis-rendering' );
  like (
    $err,
    qr/\Qinsert_or\E/,
    '... and names the option in the message',
  );
}

# ------------------------------------------------- executed against SQLite
#
# Everything above compares strings. That shows where the clause lands, not
# that SQLite accepts the spliced statement, nor that IGNORE and REPLACE do
# what their names say. So run what the SQLMaker returned -- its SQL and its
# binds, nothing hand-written -- against a real uniqueness conflict:
# artist.name carries a UNIQUE index.
#
# The plain conflicting insert comes first on purpose. Unless it fails, the
# conflict is not real, and "no error" from the two OR-forms proves nothing.

{
  my %conflicting = ( artistid => 2, name => 'dup', rank => 2 );

  run_insert( { artistid => 1, name => 'dup', rank => 1 } );

  is_deeply (
    stored_artists(),
    [ [ 1, 'dup', 1 ] ],
    'executed: the plain statement stores the seed row',
  );

  {
    my $ok  = eval { run_insert( {%conflicting} ); 1 };
    my $err = $@;

    ok ( ! $ok, 'executed: a plain insert of a row with a taken name fails' );
    like (
      $err,
      qr/UNIQUE constraint failed: artist\.name/,
      '... on the UNIQUE index of artist.name -- the conflict is real',
    );
  }

  {
    my $rv  = eval { run_insert( {%conflicting}, { insert_or => 'ignore' } ) };
    my $err = $@;

    is ( $err, '', "executed: insert_or => 'ignore' on the same row raises no error" );
    cmp_ok ( $rv, '==', 0, '... and reports no row written' );
    is_deeply (
      stored_artists(),
      [ [ 1, 'dup', 1 ] ],
      '... leaving the stored row untouched',
    );
  }

  is_deeply (
    do {
      run_insert( { artistid => 3, name => 'other', rank => 3 }, { insert_or => 'ignore' } );
      stored_artists();
    },
    [ [ 1, 'dup', 1 ], [ 3, 'other', 3 ] ],
    "executed: insert_or => 'ignore' still inserts a row that conflicts with nothing",
  );

  {
    my $ok  = eval { run_insert( {%conflicting}, { insert_or => 'replace' } ); 1 };
    my $err = $@;

    ok ( $ok, "executed: insert_or => 'replace' on the conflicting row raises no error" )
      or diag $err;
    is_deeply (
      stored_artists(),
      [ [ 2, 'dup', 2 ], [ 3, 'other', 3 ] ],
      '... and the conflicting row is gone, the new one stored in its place',
    );
  }
}

done_testing;

# $sm->insert returns ($sql, @bind); is_same_sql_bind wants ($sql, \@bind).
sub sql_bind {
  my ($sql, @bind) = @_;
  return ($sql, \@bind);
}

# Executes the statement exactly as the SQLMaker returns it. The binds come
# back as [ column => value ] pairs; the handle wants the values.
sub run_insert {
  my ($data, $options) = @_;
  my ($sql, @bind) = $sm->insert( 'artist', $data, $options );
  return $schema->storage->dbh->do( $sql, undef, map { $_->[1] } @bind );
}

sub stored_artists {
  return $schema->storage->dbh->selectall_arrayref(
    'SELECT artistid, name, rank FROM artist ORDER BY artistid'
  );
}
