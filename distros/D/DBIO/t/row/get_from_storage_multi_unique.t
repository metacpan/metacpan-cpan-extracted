use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;

# Regression tests for get_from_storage() and find() heuristics mode.
#
# The Artist table has multiple unique constraints:
#   primary     => ['artistid']
#   artist_name => ['name']
#   artist      => ['artistid']
#   u_nullable  => ['charfield', 'rank']
#
# NoPrimaryKey has no primary key, only:
#   foo_bar     => ['foo', 'bar']

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;

# Map a captured query's WHERE placeholders back onto their columns, so a test
# can assert on the VALUE a given column was looked up by.
sub where_values {
  my ($query) = @_;
  my @cols = $query->{sql} =~ /"me"\."(\w+)"\s*=\s*\?/g;
  my @bind = map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $query->{bind} || [] };
  return { map { ( $cols[$_] => $bind[$_] ) } 0 .. $#cols };
}

# -----------------------------------------------------------------------
# TEST 1: get_from_storage does not throw internally on tables with
# multiple unique constraints
#
# get_from_storage should look up by primary key without attempting to
# satisfy every other unique constraint on the table. Observable:
# - query uses only the PK column
# - no internal exceptions fire (which would reach __DIE__ handlers
#   installed by the application — e.g. logging middleware)
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, [[ 1, 'Miles Davis', 13, undef ]]);

  my $artist = $schema->resultset('Artist')->new_result({
    artistid  => 1,
    name      => 'Miles Davis',
    rank      => 13,
    charfield => undef,
  });
  $artist->in_storage(1);
  $artist->{_column_data_in_storage} = { %{ $artist->{_column_data} } };

  my @die_messages;
  local $SIG{__DIE__} = sub { push @die_messages, $_[0] };

  $storage->reset_captured;
  my $copy;
  lives_ok { $copy = $artist->get_from_storage }
    'get_from_storage lives on table with multiple unique constraints';

  is scalar(@die_messages), 0,
    'get_from_storage does not throw internally for unsatisfiable constraints'
    or diag "Unexpected internal exceptions:\n" . join("\n", @die_messages);

  my @queries = $storage->captured_queries;
  is scalar(@queries), 1, 'get_from_storage issued exactly one SELECT';

  my $sql = $queries[0]{sql};
  like $sql, qr/artistid/,
    'get_from_storage query uses the primary key column';

  isa_ok $copy, 'DBIO::Row', 'get_from_storage returned a row';
}

# -----------------------------------------------------------------------
# TEST 2: find() in heuristics mode skips unsatisfiable constraints
# without throwing internally
#
# Calling find({ artistid => 1 }) without key => enters heuristics.
# The 'artist_name' constraint (requires 'name') and 'u_nullable'
# constraint (requires 'charfield' + 'rank') cannot be satisfied with
# only { artistid => 1 }. Heuristics should skip them cleanly rather
# than throwing+catching exceptions for each one.
#
# Observable: no __DIE__ is triggered (which would fire even inside
# try/catch, affecting any installed handler in the call stack).
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "artist"/i, [[ 1, 'Miles Davis', 13, undef ]]);

  my @die_messages;
  local $SIG{__DIE__} = sub { push @die_messages, $_[0] };

  my $found;
  lives_ok {
    $found = $schema->resultset('Artist')->find({ artistid => 1 });
  } 'find() in heuristics mode lives';

  is scalar(@die_messages), 0,
    'heuristics mode does not throw internally for unsatisfiable constraints'
    or diag "Unexpected internal exceptions:\n" . join("\n", @die_messages);
}

# -----------------------------------------------------------------------
# TEST 3: get_from_storage on a table WITHOUT a primary key
#
# NoPrimaryKey has no PK — get_from_storage should fall back to
# matching by all loaded column values against available unique
# constraints, rather than croak with 'requires a primary key'.
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ 42, 99, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->new_result({
    foo => 42,
    bar => 99,
    baz => 7,
  });
  $row->in_storage(1);
  $row->{_column_data_in_storage} = { %{ $row->{_column_data} } };

  my $copy;
  lives_ok { $copy = $row->get_from_storage }
    'get_from_storage works on a table without a primary key';
}

# -----------------------------------------------------------------------
# TEST 4: discard_changes on a table without a primary key
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ 42, 99, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->new_result({
    foo => 42,
    bar => 99,
    baz => 7,
  });
  $row->in_storage(1);
  $row->{_column_data_in_storage} = { %{ $row->{_column_data} } };

  lives_ok { $row->discard_changes }
    'discard_changes works on a table without a primary key';
}

# -----------------------------------------------------------------------
# TEST 5: the no-PK fallback identifies the row by its IN-STORAGE values,
# not by locally modified ones
#
# The PK path (_storage_ident_condition -> _ident_values($use_storage_state)
# in DBIO::PK) deliberately prefers {_column_data_in_storage} over the current
# in-memory value: a result carrying unsaved changes must still be looked up
# as the row it was loaded from. The primary-key-less fallback has to follow
# the same rule -- otherwise get_from_storage/discard_changes on a dirty row
# searches for the NEW value and either misses or matches a different row.
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ 42, 99, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->new_result({
    foo => 42,
    bar => 99,
    baz => 7,
  });
  $row->in_storage(1);
  $row->{_column_data_in_storage} = { %{ $row->{_column_data} } };

  # dirty a column that participates in the foo_bar unique constraint
  $row->foo(999);
  is $row->get_column('foo'), 999, 'sanity: the in-memory value is the dirty one';

  $storage->reset_captured;
  $row->get_from_storage;

  my @queries = $storage->captured_queries;
  is scalar(@queries), 1, 'get_from_storage issued exactly one SELECT';

  my $where = where_values($queries[0]);
  is $where->{foo}, 42,
    'get_from_storage looks the row up by the in-storage value of the dirty column';
  is $where->{bar}, 99,
    'the untouched constraint column is looked up by its own value';
}

# -----------------------------------------------------------------------
# TEST 6: same rule via discard_changes -- and the refresh actually lands
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ 42, 99, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->new_result({
    foo => 42,
    bar => 99,
    baz => 7,
  });
  $row->in_storage(1);
  $row->{_column_data_in_storage} = { %{ $row->{_column_data} } };

  $row->foo(999);

  $storage->reset_captured;
  $row->discard_changes;

  my ($select) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $select, 'discard_changes issued a SELECT';

  my $where = where_values($select);
  is $where->{foo}, 42,
    'discard_changes looks the row up by the in-storage value, not the dirty one';

  is $row->get_column('foo'), 42, 'discard_changes refreshed the row from storage';
  ok !$row->is_changed, 'discard_changes cleared the dirty state';
}

# -----------------------------------------------------------------------
# TEST 7: the same rule in the plain user flow -- no hand-seeded
# _column_data_in_storage anywhere
#
# TEST 5/6 poke the in-storage map directly, which only proves the value
# PRECEDENCE in get_from_storage. It says nothing about whether that map ever
# gets filled: _track_storage_value used to track primary-key columns only, so
# on a primary-keyless source set_column recorded nothing at all and the
# precedence rule had no values to prefer. Here the row is obtained the way an
# application gets it -- inflated straight out of storage -- so the whole chain
# has to hold for the WHERE to carry the original value.
# -----------------------------------------------------------------------
{
  $storage->clear_mocks;
  $storage->mock_persistent(qr/FROM "noprimarykey"/i, [[ 42, 99, 7 ]]);

  my $row = $schema->resultset('NoPrimaryKey')->search({ foo => 42 })->single;
  ok $row, 'fixture row inflated from storage';
  ok $row->in_storage, 'the loaded row is in_storage';
  ok !$row->{_column_data_in_storage} || !keys %{ $row->{_column_data_in_storage} },
    'a freshly loaded row tracks no previous values yet';

  $row->foo(999);
  is_deeply $row->{_column_data_in_storage}, { foo => 42 },
    'changing a column on a primary-keyless row records its in-storage value';

  $storage->reset_captured;
  $row->discard_changes;

  my ($select) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $select, 'discard_changes issued a SELECT';

  my $where = where_values($select);
  is $where->{foo}, 42,
    'discard_changes on a naturally-loaded dirty row binds the original value';
  is $where->{bar}, 99, 'and the untouched column binds its own value';

  is $row->get_column('foo'), 42, 'the row was refreshed back to the stored value';
  ok !$row->is_changed, 'and is no longer dirty';
}

done_testing;
