use strict;
use warnings;
use Test::More;

# Focused, offline verification of the DBIO::Diff::Compare comparators as
# CONSUMED by the DB2 diff op classes. These functions are MISLEADINGLY NAMED:
# changed_column_fields / changed_index_fields return the LIST OF CHANGED FIELDS, so a
# NON-EMPTY (truthy) result means the column / index DIFFERS. The DB2 Diff
# classes rely on exactly that semantic (scalar is_same_X(...) gating an
# alter / drop+create op), so this test pins the contract down so a future
# rename cannot silently invert it.

use DBIO::Diff::Compare qw(changed_column_fields changed_index_fields);

# --- changed_column_fields: identical column defs => empty list (no change) ---
{
  my $c = { data_type => 'integer', not_null => 1, default_value => '0' };
  my @changed = changed_column_fields($c, { %$c });
  is(scalar @changed, 0, 'identical columns -> no changed fields (falsey)');
  ok(!scalar changed_column_fields($c, { %$c }), 'scalar context is false for identical columns');
}

# --- changed_column_fields: differing data_type => reports that field (truthy) ---
{
  my $old = { data_type => 'integer' };
  my $new = { data_type => 'varchar', size => 50 };
  my @changed = changed_column_fields($old, $new);
  ok(scalar @changed, 'differing columns -> truthy (the name is a misnomer)');
  ok((grep { $_ eq 'data_type' } @changed), 'data_type reported as changed');
}

# --- changed_column_fields: differing not_null only ---
{
  my @changed = changed_column_fields(
    { data_type => 'integer', not_null => 0 },
    { data_type => 'integer', not_null => 1 },
  );
  is_deeply(\@changed, ['not_null'], 'only not_null reported changed');
}

# --- changed_column_fields: desired-state semantics (target omits field) ---
{
  my @changed = changed_column_fields(
    { data_type => 'integer', default_value => '5' },
    { data_type => 'integer' },
  );
  is(scalar @changed, 0, 'omitted target field is "don\'t care" -> no change');
}

# --- changed_index_fields: identical => empty list ---
{
  my $i = { is_unique => 1, columns => ['a', 'b'] };
  is(scalar changed_index_fields($i, { %$i }), 0, 'identical indexes -> no change');
}

# --- changed_index_fields: column set differs (order-independent) ---
{
  my @changed = changed_index_fields(
    { is_unique => 0, columns => ['a'] },
    { is_unique => 0, columns => ['a', 'b'] },
  );
  ok(scalar @changed, 'differing index columns -> truthy');
  ok((grep { $_ eq 'columns' } @changed), 'columns reported changed');

  # order alone is NOT a change for changed_index_fields (set comparison)
  is(scalar changed_index_fields(
    { is_unique => 0, columns => ['a', 'b'] },
    { is_unique => 0, columns => ['b', 'a'] },
  ), 0, 'reordered same column set -> no change (set semantics)');
}

# --- changed_index_fields: uniqueness flip ---
{
  is_deeply(
    [ changed_index_fields(
      { is_unique => 0, columns => ['a'] },
      { is_unique => 1, columns => ['a'] },
    ) ],
    ['is_unique'],
    'is_unique flip reported',
  );
}

done_testing;
