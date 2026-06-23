use strict;
use warnings;
use Test::More;

{
  package Test::Introspect;
  use base 'DBIO::Introspect::Base';
  sub _build_model { return { tables => { foo => 1 } } }
}

my $intro = Test::Introspect->new(dbh => 'fake');
is $intro->dbh, 'fake', 'dbh accessor';
is_deeply $intro->model, { tables => { foo => 1 } }, 'model built lazily';
is $intro->model, $intro->model, 'model cached (same ref)';

# Abstract base must die without _build_model
{
  package Bare::Introspect;
  use base 'DBIO::Introspect::Base';
}
eval { Bare::Introspect->new(dbh => 'x')->model };
ok $@, '_build_model not overridden → dies';
like $@, qr/_build_model/, 'error mentions _build_model';

# _aggregate_by helper
{
  my @rows = (
    { table => 'users',   name => 'id'    },
    { table => 'users',   name => 'email' },
    { table => 'orders',  name => 'id'    },
  );

  my $grouped = DBIO::Introspect::Base->_aggregate_by(\@rows, 'table');

  is ref($grouped), 'HASH', '_aggregate_by returns hashref';
  is scalar @{ $grouped->{users}  }, 2, 'users has 2 rows';
  is scalar @{ $grouped->{orders} }, 1, 'orders has 1 row';
  is $grouped->{users}[0]{name}, 'id',    'first user column is id';
  is $grouped->{users}[1]{name}, 'email', 'second user column is email';
}

# _aggregate_by_ordered helper — deterministic first-seen key order
{
  my @rows = (
    { fk => 'b_fk', col => 'x' },
    { fk => 'a_fk', col => 'p' },
    { fk => 'b_fk', col => 'y' },
    { fk => 'a_fk', col => 'q' },
    { fk => undef,  col => 'skip' },
  );

  my $groups = DBIO::Introspect::Base->_aggregate_by_ordered(\@rows, 'fk');

  is ref($groups), 'ARRAY', '_aggregate_by_ordered returns arrayref';
  is scalar @$groups, 2, 'two groups (undef key skipped)';
  is $groups->[0][0], 'b_fk', 'first group is first-seen key, not sorted';
  is $groups->[1][0], 'a_fk', 'second group keeps insertion order';
  is_deeply [ map { $_->{col} } @{ $groups->[0][1] } ], [qw/x y/],
    'row order within group preserved';
  is_deeply [ map { $_->{col} } @{ $groups->[1][1] } ], [qw/p q/],
    'second group rows preserved in order';

  is_deeply(
    DBIO::Introspect::Base->_aggregate_by_ordered(undef, 'fk'), [],
    'undef rows -> empty arrayref',
  );
}

# --- Normalized contract: default impls read the canonical model ---
# An empty model returns empty/safe values, never dies.
{
  package Test::EmptyContract;
  use base 'DBIO::Introspect::Base';
  sub _build_model { {} }
}

my $empty = Test::EmptyContract->new(dbh => 'fake');
is_deeply $empty->table_keys, [], 'table_keys: empty model -> []';
is_deeply $empty->table_columns('foo'), [], 'table_columns: empty model -> []';
is_deeply $empty->table_columns_info('foo'), {}, 'table_columns_info: empty -> {}';
is_deeply $empty->table_pk_info('foo'), [], 'table_pk_info: empty -> []';
is_deeply $empty->table_uniq_info('foo'), [], 'table_uniq_info: empty -> []';
is_deeply $empty->table_fk_info('foo'), [], 'table_fk_info: empty -> []';
is $empty->table_is_view('foo'), 0, 'table_is_view: empty -> 0';

# Default impls against a populated canonical model (the single-schema shape).
{
  package Test::CanonContract;
  use base 'DBIO::Introspect::Base';
  sub _build_model {
    return {
      tables => {
        users => { table_name => 'users', kind => 'table' },
        v_recent => { table_name => 'v_recent', kind => 'view' },
      },
      columns => {
        users => [
          { column_name => 'id',    data_type => 'integer', not_null => 1,
            is_pk => 1, pk_position => 1, is_auto_increment => 1 },
          { column_name => 'email', data_type => 'varchar', size => 255,
            not_null => 1, default_value => undef, is_pk => 0 },
          { column_name => 'org_id', data_type => 'integer', not_null => 0,
            is_pk => 0 },
        ],
      },
      indexes => {
        users => {
          users_email_uniq => { is_unique => 1, columns => ['email'] },
          users_pkey       => { is_unique => 1, columns => ['id'], origin => 'pk' },
          users_org_idx    => { is_unique => 0, columns => ['org_id'] },
        },
      },
      foreign_keys => {
        users => [
          { from_columns => ['org_id'], to_table => 'orgs',
            to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION' },
        ],
      },
    };
  }
}

my $c = Test::CanonContract->new(dbh => 'fake');

is_deeply $c->table_keys, [qw/users v_recent/], 'table_keys sorted bare names';
is_deeply $c->table_columns('users'), [qw/id email org_id/],
  'table_columns in declaration order';

my $info = $c->table_columns_info('users');
is $info->{id}{data_type}, 'integer', 'columns_info data_type';
is $info->{id}{is_nullable}, 0, 'not_null -> is_nullable 0';
is $info->{org_id}{is_nullable}, 1, 'nullable -> is_nullable 1';
is $info->{id}{is_auto_increment}, 1, 'is_auto_increment carried when present';
ok !exists $info->{email}{is_auto_increment}, 'is_auto_increment omitted when absent';
is $info->{email}{size}, 255, 'size carried when defined';
ok !exists $info->{id}{size}, 'size omitted when undef';

is_deeply $c->table_pk_info('users'), ['id'], 'pk_info from is_pk by pk_position';

is_deeply $c->table_uniq_info('users'),
  [ [ 'users_email_uniq' => ['email'] ] ],
  'uniq_info derived from indexes: unique, non-pk, non-PRIMARY';

is_deeply $c->table_fk_info('users'), [
  {
    local_columns  => ['org_id'],
    remote_table   => 'orgs',
    remote_schema  => undef,
    remote_columns => ['id'],
    attrs          => { on_delete => 'CASCADE', on_update => 'NO ACTION' },
  },
], 'fk_info shape from canonical foreign_keys';

is $c->table_is_view('users'), 0, 'table is not a view';
is $c->table_is_view('v_recent'), 1, 'view detected via kind';

# table_uniq_info prefers an explicit unique_constraints section when present
{
  package Test::UniqConstraints;
  use base 'DBIO::Introspect::Base';
  sub _build_model {
    return {
      unique_constraints => { t => [ [ 'uc_a' => ['a','b'] ] ] },
      indexes => { t => { ignored => { is_unique => 1, columns => ['z'] } } },
    };
  }
}
is_deeply(
  Test::UniqConstraints->new(dbh => 'x')->table_uniq_info('t'),
  [ [ 'uc_a' => ['a','b'] ] ],
  'explicit unique_constraints section wins over indexes',
);

# view_definition, table_comment, column_comment default to undef
is $empty->view_definition('foo'), undef, 'view_definition defaults undef';
is $empty->table_comment('foo'), undef, 'table_comment defaults undef';
is $empty->column_comment('foo', 'bar'), undef, 'column_comment defaults undef';

# result_class_extra_statements defaults to empty list
my @extras = $empty->result_class_extra_statements('foo');
is scalar(@extras), 0, 'result_class_extra_statements defaults ()';

done_testing;
