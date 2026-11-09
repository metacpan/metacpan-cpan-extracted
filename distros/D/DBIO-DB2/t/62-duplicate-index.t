use strict;
use warnings;

use Test::More;

# OFFLINE (karr k47, ADR 0010). Db2 does not create an index over a column
# sequence that the primary key, a UNIQUE constraint or another index already
# has in the same order: CREATE INDEX answers SQL0605W (err 605, state 42S11,
# rv undef) and makes nothing. Before the fix install_ddl wrote every
# db2_indexes entry and the diff every missing index, so install died halfway
# and an upgrade brought the never-created index back on every diff.
#
# Measured live (Db2 12.1.5, t/61), what counts as covered:
#   - non-unique index over the PK columns, a UNIQUE constraint's columns or an
#     earlier index's columns (unique or not)            -> 605, nothing made
#   - UNIQUE index over the PK / a UNIQUE constraint's / an earlier UNIQUE
#     index's columns                                    -> 605, nothing made
#   - UNIQUE index over the columns of an earlier NON-unique index
#                                                        -> created, beside it
#   - same columns in another order, or a longer / shorter sequence
#                                                        -> created
# install_ddl and the diff therefore leave out exactly those, in the order the
# server meets them: PK, UNIQUE constraints, then indexes in name order.

use DBIO::DB2::DDL;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::Index;

{
  package T::K47::Item;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    a    => { data_type => 'integer' },
    b    => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(item_a => ['a']);
  sub db2_indexes {
    return {
      i_pk      => { columns => ['id'] },              # PK: dup
      u_pk      => { columns => ['id'], unique => 1 }, # PK: dup
      i_uc      => { columns => ['a'] },               # UNIQUE constraint: dup
      i_ab      => { columns => [qw(a b)] },           # kept
      i_ab_twin => { columns => [qw(a b)] },           # dup of i_ab
      i_ba      => { columns => [qw(b a)] },           # other order: kept
      i_idb     => { columns => [qw(id b)] },          # longer than PK: kept
      u_ab      => { columns => [qw(a b)], unique => 1 }, # unique after non-unique: kept
      z_ab      => { columns => [qw(a b)] },           # dup of i_ab / u_ab
      z_uab     => { columns => [qw(a b)], unique => 1 }, # dup of u_ab
    };
  }
}
{
  package T::K47::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Item => 'T::K47::Item');
}

my $ddl = DBIO::DB2::DDL->install_ddl('T::K47::Schema');
my @idx = $ddl =~ /CREATE (?:UNIQUE )?INDEX "(\w+)"/g;
is_deeply \@idx, [qw(i_ab i_ba i_idb u_ab)],
  'install_ddl writes only the indexes no earlier PK, constraint or index covers';
like $ddl, qr/CREATE UNIQUE INDEX "u_ab" ON "item" \("a", "b"\);/,
  '... a UNIQUE index over the columns of a non-unique one is written';

# ---- the helper, row by row
my @cases = (
  # cols, unique, existing, dup?, label
  [ ['id'],     0, [ [['id'], 1] ],          1, 'non-unique over unique' ],
  [ ['id'],     1, [ [['id'], 1] ],          1, 'unique over unique' ],
  [ ['id'],     0, [ [['id'], 0] ],          1, 'non-unique over non-unique' ],
  [ ['id'],     1, [ [['id'], 0] ],          0, 'unique over non-unique is no duplicate' ],
  [ [qw(a b)],  0, [ [[qw(b a)], 1] ],       0, 'other order is no duplicate' ],
  [ [qw(a b)],  0, [ [['a'], 1] ],           0, 'prefix is no duplicate' ],
  [ [],         0, [ [[], 1] ],              0, 'no columns: nothing to compare' ],
);
for my $c (@cases) {
  my ($cols, $uniq, $ex, $want, $label) = @$c;
  is +(DBIO::DB2::DDL::_index_is_duplicate($cols, $uniq, $ex) ? 1 : 0), $want, "_index_is_duplicate: $label";
}

# ---- the diff, over models in the catalog shape
sub model {
  my (%o) = @_;
  return {
    tables  => { item => { table_name => 'item' } },
    columns => { item => [
      { column_name => 'id', catalog_type => 'INTEGER', is_pk => 1, pk_position => 1 },
      { column_name => 'a',  catalog_type => 'INTEGER', is_pk => 0, pk_position => 0 },
      { column_name => 'b',  catalog_type => 'INTEGER', is_pk => 0, pk_position => 0 },
    ] },
    indexes => { item => $o{indexes} || {} },
    foreign_keys       => {},
    unique_constraints => { item => $o{ucs} || [] },
  };
}
sub ix { my ($n, $u, @c) = @_; return ($n => { index_name => $n, is_unique => $u, columns => [@c] }) }

my $empty = model();
my $target = model(
  ucs     => [ [ item_a => ['a'] ] ],
  indexes => { ix('i_pk', 0, 'id'), ix('u_pk', 1, 'id'), ix('i_uc', 0, 'a'),
               ix('i_ab', 0, qw(a b)), ix('i_ab_twin', 0, qw(a b)), ix('i_ba', 0, qw(b a)),
               ix('u_ab', 1, qw(a b)) },
);
my @sql = map { $_->as_sql } @{ DBIO::DB2::Diff->new(source => $empty, target => $target)->operations };
is_deeply [ map { /INDEX "(\w+)"/ } @sql ], [qw(i_ab i_ba u_ab)],
  'diff: no CREATE INDEX over the PK, a UNIQUE constraint or an earlier index';

# the live DB holds what was created; a second diff against the same target is empty
my $live = model(
  ucs     => [ [ item_a => ['a'] ] ],
  indexes => { ix('i_ab', 0, qw(a b)), ix('i_ba', 0, qw(b a)), ix('u_ab', 1, qw(a b)) },
);
is scalar @{ DBIO::DB2::Diff->new(source => $live, target => $target)->operations }, 0,
  'diff: the follow-up diff is empty -- the left-out indexes are not expected';

# a rename: the old index goes first, or the server refuses the create (605)
my $old = model(indexes => { ix('i_old', 0, 'b') });
my $new = model(indexes => { ix('i_new', 0, 'b') });
@sql = map { $_->as_sql } @{ DBIO::DB2::Diff->new(source => $old, target => $new)->operations };
is_deeply \@sql, [ 'DROP INDEX "i_old";', 'CREATE INDEX "i_new" ON "item" ("b");' ],
  'diff: the DROP INDEX of a renamed index comes before the CREATE over its columns';

# an unrelated drop keeps its place (after the creates)
my $old2 = model(indexes => { ix('i_gone', 0, 'a') });
my $new2 = model(indexes => { ix('i_b', 0, 'b') });
@sql = map { $_->as_sql } @{ DBIO::DB2::Diff->new(source => $old2, target => $new2)->operations };
is_deeply \@sql, [ 'CREATE INDEX "i_b" ON "item" ("b");', 'DROP INDEX "i_gone";' ],
  'diff: a drop that frees no column sequence of a create stays after the creates';

done_testing;
