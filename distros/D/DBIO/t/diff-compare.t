use strict;
use warnings;
use Test::More;

use DBIO::Diff::Compare qw(
  norm norm_type arr_differ changed_fields
  changed_column_fields changed_index_fields changed_fk_fields
);

# --- primitives ---
is norm(undef), '', 'norm undef -> empty string';
is norm(0), '0', 'norm 0 -> "0"';
is norm('x'), 'x', 'norm passthrough';

is norm_type(undef), '', 'norm_type undef -> empty';
is norm_type('  character   varying '), 'CHARACTER VARYING',
  'norm_type collapses ws + uppercases + trims';
is norm_type('integer'), 'INTEGER', 'norm_type uppercases';

ok !arr_differ([qw/a b c/], [qw/c b a/]), 'arr_differ: same set, diff order -> equal';
ok arr_differ([qw/a b/], [qw/a b c/]), 'arr_differ: different length -> differ';
ok arr_differ([qw/a b/], [qw/a x/]), 'arr_differ: different member -> differ';
ok !arr_differ(undef, []), 'arr_differ: undef vs empty -> equal';

# --- changed_fields: per-group semantics ---
{
  my @c = changed_fields(
    { a => 'integer', b => 1, c => 'x' },
    { a => 'INTEGER', b => 1, c => 'x' },
    type => ['a'], bool => ['b'], scalar => ['c'],
  );
  is_deeply \@c, [], 'type compare is case/ws-insensitive; identical -> no change';
}
{
  my @c = changed_fields(
    { a => 'int', b => 0, c => undef, d => ['x','y'], e => [10, 2] },
    { a => 'int', b => 1, c => 'set', d => ['y','x'], e => [10, 3] },
    type => ['a'], bool => ['b'], scalar => ['c'], array => ['d'], dim => ['e'],
  );
  # a same; b differs (0 vs 1); c differs (undef vs set); d same set diff order; e differs ([10,2] vs [10,3])
  is_deeply [ sort @c ], [ sort qw/b c e/ ],
    'bool/scalar/dim detect change; array is order-independent';
}
{
  # bool treats undef as 0
  my @c = changed_fields({ x => undef }, { x => 0 }, bool => ['x']);
  is_deeply \@c, [], 'bool: undef == 0';
  @c = changed_fields({ x => undef }, { x => 1 }, bool => ['x']);
  is_deeply \@c, ['x'], 'bool: undef != 1';
}
{
  # desired_state skips fields undef in target (scalar/type/dim/array), not bool
  my @c = changed_fields(
    { a => 'old', n => 1 },
    { a => undef, n => undef },
    scalar => ['a'], bool => ['n'], desired_state => 1,
  );
  # a skipped (new undef); n is bool -> undef==0 vs 1 -> differ
  is_deeply \@c, ['n'], 'desired_state skips scalar undef-in-new but bool still compares';
}
{
  # declared order preserved in return
  my @c = changed_fields(
    { s1 => 'a', s2 => 'b', t1 => 'x' },
    { s1 => 'A', s2 => 'B', t1 => 'X' },
    scalar => ['s1','s2'], type => ['t1'],
  );
  # s1 'a' ne 'A' (scalar is case-sensitive), s2 differ, t1 type-insensitive -> same
  is_deeply \@c, ['s1','s2'], 'scalar is case-sensitive, type is not; order = declared';
}

# --- changed_column_fields (desired-state) ---
ok !changed_column_fields(
  { data_type => 'integer', not_null => 1, default_value => undef, size => undef },
  { data_type => 'INTEGER', not_null => 1 },
), 'changed_column_fields: type-insensitive, unspecified target fields ignored';

is_deeply [ changed_column_fields(
  { data_type => 'integer', size => 10 },
  { data_type => 'integer', size => 20 },
) ], ['size'], 'changed_column_fields: size change detected';

is_deeply [ changed_column_fields(
  { data_type => 'numeric', size => [10, 2] },
  { data_type => 'numeric', size => [10, 4] },
) ], ['size'], 'changed_column_fields: [precision,scale] change detected (ordered)';

# --- changed_index_fields ---
ok !changed_index_fields(
  { is_unique => 1, columns => [qw/a b/] },
  { is_unique => 1, columns => [qw/b a/] },
), 'changed_index_fields: unique + same column set (order-independent) -> same';

is_deeply [ changed_index_fields(
  { is_unique => 0, columns => ['a'] },
  { is_unique => 1, columns => ['a'] },
) ], ['is_unique'], 'changed_index_fields: uniqueness change detected';

# --- changed_fk_fields ---
ok !changed_fk_fields(
  { to_table => 'orgs', on_update => 'NO ACTION', on_delete => 'CASCADE',
    from_columns => ['org_id'], to_columns => ['id'] },
  { to_table => 'orgs', on_update => 'NO ACTION', on_delete => 'CASCADE',
    from_columns => ['org_id'], to_columns => ['id'] },
), 'changed_fk_fields: identical -> same';

{
  my @ch = changed_fk_fields(
    { to_table => 'orgs', on_delete => 'CASCADE', from_columns => ['a'], to_columns => ['id'] },
    { to_table => 'orgz', on_delete => 'RESTRICT', from_columns => ['a'], to_columns => ['id'] },
  );
  is_deeply [ sort @ch ], [ sort qw/to_table on_delete/ ],
    'changed_fk_fields: scalar changes detected';
}

done_testing;
