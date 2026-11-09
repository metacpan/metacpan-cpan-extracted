use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Diff;

# The primary key in the diff (karr k53). Two holes, both offline-visible:
#
# - Diff::Table::Create rendered no PRIMARY KEY, so a table created through
#   upgrade() lost its key although the target columns carried is_pk /
#   pk_position (Introspect::_mark_pk_columns).
# - A retained table's key was never compared: Diff::Index leaves the PK index
#   out (its server-assigned name differs per deployment), and nothing else
#   looked at it. PK(a) -> PK(a,b) produced an empty diff.
#
# The key is compared as an ORDERED column list, never by name, and applied as
# ALTER TABLE t DROP CONSTRAINT <live name>; ALTER TABLE t ADD PRIMARY KEY (...);
# (both accepted live on ASE 16.0 SP02; a second ADD PRIMARY KEY is Msg 1923).

sub tbl { +{ table_name => $_[0], kind => 'table' } }
sub col {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => 'integer', not_null => 1,
     default_value => $o{default}, is_auto_increment => 0,
     is_pk => $o{pk} ? 1 : 0, pk_position => $o{pk} // 0 };
}
sub pkidx {
  my ($name, @cols) = @_;
  +{ $name => { index_name => $name, is_unique => 1, columns => \@cols, origin => 'pk' } };
}
sub model {
  my (%o) = @_;
  +{ tables => { map { $_ => tbl($_) } keys %{ $o{columns} } },
     columns => $o{columns}, indexes => $o{indexes} // {}, foreign_keys => {} };
}
sub stmts { map { $_->as_sql } @{ DBIO::Sybase::Diff->new(source => $_[0], target => $_[1])->operations } }

# --- a created table carries its key, in key order ---------------------------
{
  my @sql = stmts(
    model(columns => {}),
    model(columns => { t => [ col('a', pk => 2), col('b', pk => 1), col('c') ] }),
  );
  is_deeply \@sql, [ "CREATE TABLE t (\n  a INT NOT NULL,\n  b INT NOT NULL,\n"
    . "  c INT NOT NULL,\n  PRIMARY KEY (b, a)\n);" ],
    'CREATE TABLE renders PRIMARY KEY in pk_position order, not column order';
}

# --- same key, different server-assigned name: no op -------------------------
{
  my @sql = stmts(
    model(columns => { t => [ col('a', pk => 1), col('b') ] }, indexes => { t => pkidx('t_111', 'a') }),
    model(columns => { t => [ col('a', pk => 1), col('b') ] }, indexes => { t => pkidx('t_999', 'a') }),
  );
  is_deeply \@sql, [], 'an identical key under another name is no change';
}

# --- PK(a) -> PK(a,b), b new: drop, add column, add key ----------------------
{
  my @sql = stmts(
    model(columns => { t => [ col('a', pk => 1) ] }, indexes => { t => pkidx('t_111', 'a') }),
    model(columns => { t => [ col('a', pk => 1), col('b', pk => 2, default => 0) ] }, indexes => { t => pkidx('t_999', 'a', 'b') }),
  );
  is scalar(@sql), 3, 'three statements';
  is $sql[0], 'ALTER TABLE t DROP CONSTRAINT t_111;', 'the live key is dropped by its live name';
  like $sql[1], qr/\AALTER TABLE t ADD b INT\b/, 'the new key column is added';
  is $sql[2], 'ALTER TABLE t ADD PRIMARY KEY (a, b);', '... and only then the new key';
}

# --- key order change only: key ops, and no column MODIFY -------------------
# is_pk / pk_position move, the column itself does not; core's
# changed_column_fields does not compare them, so no empty MODIFY may appear.
{
  my @sql = stmts(
    model(columns => { t => [ col('a', pk => 1), col('b', pk => 2) ] }, indexes => { t => pkidx('t_111', 'a', 'b') }),
    model(columns => { t => [ col('a', pk => 2), col('b', pk => 1) ] }, indexes => { t => pkidx('t_999', 'b', 'a') }),
  );
  is_deeply \@sql, [ 'ALTER TABLE t DROP CONSTRAINT t_111;', 'ALTER TABLE t ADD PRIMARY KEY (b, a);' ],
    'a reordered key is a change, and nothing but the key';
}

# --- key removed / key added -------------------------------------------------
{
  is_deeply [ stmts(
    model(columns => { t => [ col('a', pk => 1) ] }, indexes => { t => pkidx('t_111', 'a') }),
    model(columns => { t => [ col('a') ] }),
  ) ], [ 'ALTER TABLE t DROP CONSTRAINT t_111;' ], 'a removed key is only dropped';
  is_deeply [ stmts(
    model(columns => { t => [ col('a') ] }),
    model(columns => { t => [ col('a', pk => 1) ] }, indexes => { t => pkidx('t_999', 'a') }),
  ) ], [ 'ALTER TABLE t ADD PRIMARY KEY (a);' ], 'a new key is only added';
}

# --- a key column dropped: the key goes first --------------------------------
{
  my @sql = stmts(
    model(columns => { t => [ col('a', pk => 1), col('b', pk => 2) ] }, indexes => { t => pkidx('t_111', 'a', 'b') }),
    model(columns => { t => [ col('a', pk => 1) ] }, indexes => { t => pkidx('t_999', 'a') }),
  );
  is_deeply \@sql, [ 'ALTER TABLE t DROP CONSTRAINT t_111;', 'ALTER TABLE t DROP b;',
    'ALTER TABLE t ADD PRIMARY KEY (a);' ],
    'key drop precedes the drop of its column, key add follows it';
}

# --- no live name, no drop ----------------------------------------------------
{
  my ($op) = DBIO::Sybase::Diff::Table->diff_primary_keys(
    { t => tbl('t') }, { t => tbl('t') },
    { t => [ col('a', pk => 1) ] }, { t => [ col('a') ] }, {},
  );
  ok !eval { $op->as_sql; 1 }, 'a drop without the live constraint name refuses to render';
  like $@, qr/no primary-key constraint name for table t/, '... naming the table';
}

done_testing;
