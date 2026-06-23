use strict;
use warnings;
use Test::More;

# Regression for karr #44: the desired-state diff must IGNORE attributes the
# target (desired) side leaves undef, instead of treating undef as "set to
# NULL/empty". A portable DBIO schema does not prescribe server-assigned column
# attributes (charset/collation/server defaults), so the driver leaves those
# fields undef on the target. The live introspect reports a real value for them
# (e.g. utf8mb4 on MariaDB). Comparing undef-target against the live value used
# to emit a phantom ALTER on every upgrade. This must no longer happen -- and
# the rule must fire ONLY when the target side is undef:
#
#   (a) target undef, live set   -> NOT a change (don't care, leave it alone)
#   (b) both set and different    -> still a real change
#   (c) target set, live undef    -> still a real change
#
# The contract is solved once in core (DBIO::Diff::Compare) and must apply
# WITHOUT a per-call opt-in flag, so a driver that drives the shared diff walk
# (DBIO::Diff::Op->diff_nested with changed_when => changed_column_fields, or a
# raw changed_fields call) gets it for free.

use DBIO::Test;
use DBIO::Diff::Compare qw(changed_fields changed_column_fields changed_fk_fields);
use DBIO::Diff::Op;

# Anchor in the mock-storage framework (core tests are mock-only; no real DB).
my $schema = DBIO::Test->init_schema;
isa_ok $schema->storage, 'DBIO::Test::Storage', 'mock storage in use (no real DB)';

# A minimal op class that records what the shared diff walk decides.
{
  package Test::ColOp;
  use base 'DBIO::Diff::Op';
  __PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);
}

# Drive the exact walk a driver uses: $source = live introspect, $target =
# desired (compiled-from-schema). Returns the list of "modify" ops emitted.
sub modify_ops {
  my ($source, $target) = @_;
  my @ops = Test::ColOp->diff_nested($source, $target,
    index_by     => 'column_name',
    scope        => 'both',
    changed_when => sub { scalar changed_column_fields($_[0], $_[1]) },
    on_changed   => sub {
      my ($t, $n) = @_;
      Test::ColOp->new(action => 'modify', table_name => $t, column_name => $n);
    },
  );
  return [ map { join '.', $_->table_name, $_->column_name } @ops ];
}

# ---------------------------------------------------------------------------
# (a) target leaves a server-assigned attr undef, live reports a value
#     -> NO phantom ALTER. This is the bug from karr #44.
# ---------------------------------------------------------------------------
{
  my $live = {
    users => [
      # live introspect reports a concrete size the server assigned/normalised
      { column_name => 'name', data_type => 'varchar', size => 255,
        not_null => 1, default_value => undef },
    ],
  };
  my $desired = {
    users => [
      # portable schema did not prescribe a length -> size undef on the target.
      # changed_column_fields compares size, so this exercises the skip through
      # the real diff_nested walk.
      { column_name => 'name', data_type => 'varchar', size => undef,
        not_null => 1, default_value => undef },
    ],
  };

  is_deeply modify_ops($live, $desired), [],
    '(a) a canonical field the target leaves undef does NOT emit a phantom ALTER';
}

# ---------------------------------------------------------------------------
# (b) both sides set and genuinely different -> STILL a real ALTER.
#     Proves the rule did not turn into "ignore everything".
# ---------------------------------------------------------------------------
{
  my $live = {
    users => [
      { column_name => 'name', data_type => 'varchar', size => 255 },
    ],
  };
  my $desired = {
    users => [
      { column_name => 'name', data_type => 'varchar', size => 512 },
    ],
  };

  is_deeply modify_ops($live, $desired), ['users.name'],
    '(b) both sides set and different still emits an ALTER';
}

# ---------------------------------------------------------------------------
# (c) target PRESCRIBES a value, live reports undef for it -> STILL a real
#     ALTER. Proves the skip fires ONLY on the target side, never the live one.
#     If it (wrongly) skipped on either-side-undef, this would vanish.
# ---------------------------------------------------------------------------
{
  my $live = {
    users => [
      { column_name => 'name', data_type => 'varchar', size => undef },
    ],
  };
  my $desired = {
    users => [
      { column_name => 'name', data_type => 'varchar', size => 255 },
    ],
  };

  is_deeply modify_ops($live, $desired), ['users.name'],
    '(c) target prescribes a value the live DB lacks -> still an ALTER';
}

# ---------------------------------------------------------------------------
# Same three directions at the raw changed_fields level WITHOUT any
# desired_state flag -- the contract must be the DEFAULT, not opt-in. This is
# the exact shape a driver (e.g. PostgreSQL) uses when it passes its own field
# spec and forgets the flag; karr #44 requires it to be safe regardless.
# ---------------------------------------------------------------------------
{
  # (a) target undef -> ignored
  is_deeply [ changed_fields(
    { charset => 'utf8mb4', extra => 'x' },
    { charset => undef,     extra => 'x' },
    scalar => ['charset', 'extra'],
  ) ], [],
    'raw changed_fields (no flag): target-undef field ignored';

  # (b) both set and different -> changed
  is_deeply [ changed_fields(
    { charset => 'latin1' },
    { charset => 'utf8mb4' },
    scalar => ['charset'],
  ) ], ['charset'],
    'raw changed_fields (no flag): both set and different still changes';

  # (c) target set, live undef -> changed
  is_deeply [ changed_fields(
    { charset => undef },
    { charset => 'utf8mb4' },
    scalar => ['charset'],
  ) ], ['charset'],
    'raw changed_fields (no flag): target prescribes, live lacks -> changes';
}

# ---------------------------------------------------------------------------
# The contract reaches the other canonical comparators too: a target that
# leaves a foreign-key referential action unspecified must not phantom-diff
# against the engine default the live DB reports.
# ---------------------------------------------------------------------------
{
  # (a) target leaves on_delete undef, live reports the engine default
  is_deeply [ changed_fk_fields(
    { to_table => 'orgs', on_delete => 'NO ACTION', on_update => 'NO ACTION',
      from_columns => ['org_id'], to_columns => ['id'] },
    { to_table => 'orgs', on_delete => undef,       on_update => undef,
      from_columns => ['org_id'], to_columns => ['id'] },
  ) ], [],
    'changed_fk_fields: target-undef referential actions do not phantom-diff';

  # (b) both set and different -> still a change
  is_deeply [ changed_fk_fields(
    { to_table => 'orgs', on_delete => 'NO ACTION',
      from_columns => ['org_id'], to_columns => ['id'] },
    { to_table => 'orgs', on_delete => 'CASCADE',
      from_columns => ['org_id'], to_columns => ['id'] },
  ) ], ['on_delete'],
    'changed_fk_fields: both set and different still changes';
}

done_testing;
