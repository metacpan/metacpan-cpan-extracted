use strict;
use warnings;
use Test::More;

use DBIO::Diff::Compare qw(
  norm norm_type arr_differ changed_fields
  changed_column_fields changed_index_fields changed_fk_fields
  column_change_lossy
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

# --- changed_fields: 'mutual' group (bilateral, phantom-diff-free) --- (ADR 0052)
# A mutual field is compared as a case/whitespace-insensitive token, but ONLY
# when BOTH sides carry a value. undef on EITHER side means that participant has
# no opinion, so the field is not compared and never diffs. This is deliberately
# NOT the desired-state (scalar/type) rule -- that treats "target set, live undef"
# as a real change (ADR 0019 (c)); a mutual field does not.
{
  # both present and different -> change
  is_deeply [ changed_fields(
    { it => 'BTREE' }, { it => 'FULLTEXT' }, mutual => ['it'],
  ) ], ['it'], 'mutual: both present + differ -> change';

  # both present, case/whitespace-insensitive equal -> no change
  is_deeply [ changed_fields(
    { it => 'btree' }, { it => 'BTREE' }, mutual => ['it'],
  ) ], [], 'mutual: both present + token-equal (case-insensitive) -> no change';

  # both undef -> no change (no opinion on either side)
  is_deeply [ changed_fields(
    { it => undef }, { it => undef }, mutual => ['it'],
  ) ], [], 'mutual: both undef -> no change';

  # live set, target undef -> no change (target has no opinion)
  is_deeply [ changed_fields(
    { it => 'BTREE' }, { it => undef }, mutual => ['it'],
  ) ], [], 'mutual: live set, target undef -> no change';

  # live undef, target set -> no change (live has no opinion). This is the
  # direction that DIFFERS from the desired-state rule, which WOULD diff here.
  is_deeply [ changed_fields(
    { it => undef }, { it => 'FULLTEXT' }, mutual => ['it'],
  ) ], [], 'mutual: live undef, target set -> no change (bilateral, unlike scalar/type)';
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

is_deeply [ changed_column_fields(
  { data_type => 'integer', is_auto_increment => 0 },
  { data_type => 'integer', is_auto_increment => 1 },
) ], ['is_auto_increment'], 'changed_column_fields: is_auto_increment gained is detected';

is_deeply [ changed_column_fields(
  { data_type => 'integer', is_auto_increment => 1 },
  { data_type => 'integer' },
) ], [], 'changed_column_fields: target leaving is_auto_increment undef is not compared (desired state)';

is_deeply [ changed_column_fields(
  { data_type => 'integer' },
  { data_type => 'integer', is_auto_increment => 1 },
) ], ['is_auto_increment'], 'changed_column_fields: target 1 against live undef is a change';

ok !changed_column_fields(
  { data_type => 'integer' },
  { data_type => 'integer', is_auto_increment => 0 },
), 'changed_column_fields: explicit target 0 equals a live column without the flag';

is_deeply [ changed_column_fields(
  { data_type => 'integer', is_auto_increment => 1 },
  { data_type => 'integer', is_auto_increment => 0 },
) ], ['is_auto_increment'], 'changed_column_fields: explicit target 0 against live 1 is a change';

# --- changed_index_fields ---
ok !changed_index_fields(
  { is_unique => 1, columns => [qw/a b/] },
  { is_unique => 1, columns => [qw/b a/] },
), 'changed_index_fields: unique + same column set (order-independent) -> same';

is_deeply [ changed_index_fields(
  { is_unique => 0, columns => ['a'] },
  { is_unique => 1, columns => ['a'] },
) ], ['is_unique'], 'changed_index_fields: uniqueness change detected';

# --- changed_index_fields: index_type (bilateral, phantom-diff-free) --- (ADR 0052)
# A BTREE<->FULLTEXT switch on the same columns/uniqueness used to be invisible
# (only is_unique + columns were compared). index_type is now part of the
# canonical comparison -- but ONLY when both sides carry a type.

# (a) both sides typed and different -> the index_type change is now seen
is_deeply [ changed_index_fields(
  { is_unique => 0, columns => ['body'], index_type => 'BTREE' },
  { is_unique => 0, columns => ['body'], index_type => 'FULLTEXT' },
) ], ['index_type'],
  'changed_index_fields: BTREE -> FULLTEXT on the same columns is now a change';

# (b) same columns + uniqueness + type (case-insensitive) -> stable, no phantom
ok !changed_index_fields(
  { is_unique => 0, columns => ['a', 'b'], index_type => 'BTREE' },
  { is_unique => 0, columns => ['b', 'a'], index_type => 'btree' },
), 'changed_index_fields: identical typed index (case-insensitive) -> same';

# (c) PHANTOM-DIFF GUARD -- a typeless driver must never manufacture a diff.
# All three undef directions on an otherwise-identical index yield no change.
ok !changed_index_fields(
  { is_unique => 0, columns => ['a'] },
  { is_unique => 0, columns => ['a'] },
), 'phantom guard: no index_type on either side -> no diff';

ok !changed_index_fields(
  { is_unique => 0, columns => ['a'], index_type => 'BTREE' },
  { is_unique => 0, columns => ['a'] },
), 'phantom guard: live carries a type, target does not -> no diff';

ok !changed_index_fields(
  { is_unique => 0, columns => ['a'] },
  { is_unique => 0, columns => ['a'], index_type => 'FULLTEXT' },
), 'phantom guard: target carries a type, live does not -> no diff';

# an index_type change must not mask (or be masked by) a real uniqueness change
{
  my @both = changed_index_fields(
    { is_unique => 0, columns => ['a'], index_type => 'BTREE' },
    { is_unique => 1, columns => ['a'], index_type => 'HASH' },
  );
  is_deeply [ sort @both ], [ sort qw/is_unique index_type/ ],
    'changed_index_fields: uniqueness AND index_type change reported together';
}

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

# --- a removed default is a change (karr k367) ---
is_deeply [ changed_column_fields(
  { data_type => 'integer', default_value => '5' },
  { data_type => 'integer' },
) ], ['default_value'], 'changed_column_fields: live default, target without one -> default_value changed';

is_deeply [ changed_column_fields(
  { data_type => 'integer', default_value => '0' },
  { data_type => 'integer', default_value => undef },
) ], ['default_value'], 'changed_column_fields: a live default of 0 is still a default';

is_deeply [ changed_column_fields(
  { data_type => 'integer', default_value => 'NULL' },
  { data_type => 'integer' },
) ], [], 'changed_column_fields: live DEFAULT NULL counts as no default';

is_deeply [ changed_column_fields(
  { data_type => 'integer', default_value => \'null' },
  { data_type => 'integer' },
) ], [], 'changed_column_fields: live DEFAULT NULL as a literal ref counts as no default';

is_deeply [ changed_column_fields(
  { data_type => 'integer', not_null => 0, default_value => '5', size => 4 },
  { data_type => 'bigint',  not_null => 1, size => 8 },
) ], [qw(not_null default_value data_type size)], 'changed_column_fields: removed default keeps declared field order';

is_deeply [ changed_column_fields(
  { data_type => 'integer' },
  { data_type => 'integer' },
) ], [], 'changed_column_fields: no default on either side is no change';

# --- column_change_lossy -----------------------------------------------------
{
  my $pairs = { 'integer->bigint' => 1 };
  my $lossy = sub { column_change_lossy($_[0], $_[1], $pairs) };

  ok !$lossy->({ data_type => 'varchar', size => 20 }, { data_type => 'varchar', size => 40 }),
    'lossy: a longer varchar is lossless';
  ok !$lossy->({ data_type => 'varchar', size => 20 }, { data_type => 'VARCHAR', size => 20 }),
    'lossy: the same type and size (case aside) is lossless';
  ok $lossy->({ data_type => 'varchar', size => 40 }, { data_type => 'varchar', size => 20 }),
    'lossy: a shorter varchar is lossy';
  ok !$lossy->({ data_type => 'numeric', size => '10,2' }, { data_type => 'numeric', size => '12,2' }),
    'lossy: "p,s" with a larger precision and the same scale is lossless';
  ok $lossy->({ data_type => 'numeric', size => '10,2' }, { data_type => 'numeric', size => '12,4' }),
    'lossy: "p,s" with another scale is lossy';
  ok $lossy->({ data_type => 'numeric', size => [ 10, 2 ] }, { data_type => 'numeric', size => [ 8, 2 ] }),
    'lossy: a pair with a smaller precision is lossy';
  ok !$lossy->({ data_type => 'numeric', size => [ 10, 2 ] }, { data_type => 'numeric', size => '12, 2' }),
    'lossy: array ref and string forms compare as the same sizes';
  ok $lossy->({ data_type => 'numeric', size => 10 }, { data_type => 'numeric', size => [ 10, 2 ] }),
    'lossy: a number against a pair is lossy';
  ok !$lossy->({ data_type => 'varchar', size => 20 }, { data_type => 'varchar' }),
    'lossy: a target without size prescribes nothing';
  ok $lossy->({ data_type => 'varchar' }, { data_type => 'varchar', size => 20 }),
    'lossy: a live column without size against a sized target is lossy';
  ok !$lossy->({ data_type => 'integer' }, { data_type => 'integer' }),
    'lossy: no size on either side is lossless';

  ok !$lossy->({ data_type => 'integer' }, { data_type => 'bigint' }),
    'lossy: a pair named lossless is lossless';
  ok !$lossy->({ data_type => 'INTEGER', size => 4 }, { data_type => 'BigInt', size => 8 }),
    'lossy: the pair is matched case-insensitively, the size is not looked at';
  ok $lossy->({ data_type => 'bigint' }, { data_type => 'integer' }),
    'lossy: the reverse of a named pair is lossy';
  ok $lossy->({ data_type => 'integer' }, { data_type => 'varchar', size => 20 }),
    'lossy: another type is lossy';
  ok column_change_lossy({ data_type => 'integer' }, { data_type => 'bigint' }),
    'lossy: without pairs a type change is lossy';
  ok !$lossy->({ data_type => 'integer' }, {}), 'lossy: a target without data_type keeps the live one';
}

done_testing;
