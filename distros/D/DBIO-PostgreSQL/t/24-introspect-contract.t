use strict;
use warnings;

use Test::More;

# Needs DBIO core (not installed): prove -I/path/to/dbio/lib -l t/...

use DBIO::PostgreSQL::Introspect;

package DBIO::PostgreSQL::Introspect::Mock;
use base 'DBIO::PostgreSQL::Introspect';

sub new {
  my ($class, %args) = @_;
  my $self = bless \%args, $class;
  $self->{model} = $args{model};
  return $self;
}

sub _build_model { die "should not be called" }

package main;

# Same fixture data as the original, now passed via model directly
my $MODEL_FIXTURE = {
  tables => {
    'auth.users' => {
      schema_name     => 'auth',
      table_name      => 'users',
      kind            => 'r',
      kind_label      => 'table',
      comment         => 'Application users.',
      rls_enabled     => 1,
      rls_forced      => 1,
      view_definition => undef,
    },
    'public.posts' => {
      schema_name     => 'public',
      table_name      => 'posts',
      kind            => 'r',
      kind_label      => 'table',
      comment         => 'Blog posts.',
      rls_enabled     => 0,
      rls_forced      => 0,
      view_definition => undef,
    },
    'public.active_users' => {
      schema_name     => 'public',
      table_name      => 'active_users',
      kind            => 'v',
      kind_label      => 'view',
      comment         => 'Only active users.',
      rls_enabled     => 0,
      rls_forced      => 0,
      view_definition => " SELECT u.id, u.email\n FROM auth.users u\n WHERE u.active; ",
    },
  },
  columns => {
    'auth.users' => [
      {
        column_name   => 'id',
        ordinal       => 1,
        data_type     => 'integer',
        not_null      => 1,
        default_value => q{nextval('auth.users_id_seq'::regclass)},
        identity      => '',
        generated     => '',
        comment       => 'Primary key.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'email',
        ordinal       => 2,
        data_type     => 'character varying(255)',
        not_null      => 1,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => 'Login address.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'role',
        ordinal       => 3,
        data_type     => 'auth.role_type',
        not_null      => 1,
        default_value => q{'user'::auth.role_type},
        identity      => '',
        generated     => '',
        comment       => 'Role enum.',
        type_category => 'e',
        enum_type     => 'role_type',
        type_schema   => 'auth',
      },
      {
        column_name   => 'embedding',
        ordinal       => 4,
        data_type     => 'vector(3)',
        not_null      => 0,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => 'Short embedding.',
        type_category => 'b',
        type_schema   => 'public',
      },
      {
        column_name   => 'settings',
        ordinal       => 5,
        data_type     => 'jsonb',
        not_null      => 0,
        default_value => q{'{}'::jsonb},
        identity      => '',
        generated     => '',
        comment       => 'JSON settings.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'active',
        ordinal       => 6,
        data_type     => 'boolean',
        not_null      => 1,
        default_value => 'true',
        identity      => '',
        generated     => '',
        comment       => 'Enabled flag.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'nickname',
        ordinal       => 7,
        data_type     => 'text',
        not_null      => 0,
        default_value => undef,
        identity      => '',
        generated     => 's',
        comment       => 'Generated display name.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'external_id',
        ordinal       => 8,
        data_type     => 'bigint',
        not_null      => 1,
        default_value => undef,
        identity      => 'd',
        generated     => '',
        comment       => 'Identity column.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'availability',
        ordinal       => 9,
        data_type     => 'int4range',
        not_null      => 0,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => 'Availability window.',
        type_category => 'r',
        type_schema   => 'pg_catalog',
      },
    ],
    'public.posts' => [
      {
        column_name   => 'id',
        ordinal       => 1,
        data_type     => 'integer',
        not_null      => 1,
        default_value => q{nextval('public.posts_id_seq'::regclass)},
        identity      => '',
        generated     => '',
        comment       => 'Primary key.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'author_id',
        ordinal       => 2,
        data_type     => 'integer',
        not_null      => 1,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => 'FK to users.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
    ],
    'public.active_users' => [
      {
        column_name   => 'id',
        ordinal       => 1,
        data_type     => 'integer',
        not_null      => 1,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => undef,
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
      {
        column_name   => 'email',
        ordinal       => 2,
        data_type     => 'character varying(255)',
        not_null      => 1,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => undef,
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
    ],
  },
  indexes => {
    'auth.users' => {
      users_pkey => {
        index_name      => 'users_pkey',
        access_method   => 'btree',
        is_unique       => 1,
        is_primary      => 1,
        is_valid        => 1,
        predicate       => undef,
        expressions     => undef,
        columns         => ['id'],
        include_columns => [],
        storage_params  => {},
      },
      users_email_key => {
        index_name      => 'users_email_key',
        access_method   => 'btree',
        is_unique       => 1,
        is_primary      => 0,
        is_valid        => 1,
        predicate       => undef,
        expressions     => undef,
        columns         => ['email'],
        include_columns => [],
        storage_params  => {},
      },
      users_role_partial_idx => {
        index_name      => 'users_role_partial_idx',
        access_method   => 'btree',
        is_unique       => 0,
        is_primary      => 0,
        is_valid        => 1,
        predicate       => q{role <> 'guest'::auth.role_type},
        expressions     => undef,
        columns         => ['role'],
        include_columns => [],
        storage_params  => {},
      },
      users_name_lower_idx => {
        index_name      => 'users_name_lower_idx',
        access_method   => 'btree',
        is_unique       => 1,
        is_primary      => 0,
        is_valid        => 1,
        predicate       => undef,
        expressions     => 'lower(email)',
        columns         => [],
        include_columns => [],
        storage_params  => {},
      },
      users_embedding_idx => {
        index_name      => 'users_embedding_idx',
        access_method   => 'ivfflat',
        is_unique       => 0,
        is_primary      => 0,
        is_valid        => 1,
        predicate       => undef,
        expressions     => undef,
        columns         => ['embedding'],
        include_columns => [],
        storage_params  => { lists => '100' },
      },
      users_email_name_idx => {
        index_name      => 'users_email_name_idx',
        access_method   => 'btree',
        is_unique       => 0,
        is_primary      => 0,
        is_valid        => 1,
        predicate       => undef,
        expressions     => undef,
        columns         => ['email'],
        include_columns => ['nickname'],
        storage_params  => {},
      },
    },
    'public.posts' => {
      posts_pkey => {
        index_name      => 'posts_pkey',
        access_method   => 'btree',
        is_unique       => 1,
        is_primary      => 1,
        is_valid        => 1,
        predicate       => undef,
        expressions     => undef,
        columns         => ['id'],
        include_columns => [],
        storage_params  => {},
      },
    },
  },
  triggers => {
    'auth.users' => {
      users_touch => {
        trigger_name => 'users_touch',
        timing       => 'BEFORE',
        event        => 'UPDATE',
        orientation  => 'ROW',
        enabled      => 'O',
        definition   => 'CREATE TRIGGER users_touch BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION auth.touch_user()',
        execute      => 'auth.touch_user()',
      },
    },
  },
  policies => {
    'auth.users' => {
      users_self => {
        policy_name => 'users_self',
        command     => 'ALL',
        permissive  => 1,
        using_expr  => 'id = current_setting($$app.user_id$$)::integer',
        check_expr  => 'id = current_setting($$app.user_id$$)::integer',
        roles       => ['app_user'],
      },
    },
  },
  foreign_keys => {
    'public.posts' => [
      {
        constraint_name => 'posts_author_id_fkey',
        remote_schema   => 'auth',
        remote_table    => 'users',
        local_columns   => ['author_id'],
        remote_columns  => ['id'],
        on_delete       => 'CASCADE',
        on_update       => 'NO ACTION',
        is_deferrable   => 0,
      },
    ],
  },
  check_constraints => {
    'auth.users' => {
      users_email_check => {
        constraint_name => 'users_email_check',
        definition      => q{CHECK ((email ~~ '%@%'::text))},
        columns         => ['email'],
      },
    },
  },
  types => {
    'auth.role_type' => {
      schema_name => 'auth',
      type_name   => 'role_type',
      type_kind   => 'enum',
      values      => [qw(admin user guest)],
    },
  },
};

my $intro = DBIO::PostgreSQL::Introspect::Mock->new(
  model         => $MODEL_FIXTURE,
  schema_filter => [qw(auth public)],
  preserve_case => 0,
);

is_deeply(
  $intro->table_keys,
  [qw(auth.users public.active_users public.posts)],
  'table keys are schema-qualified and sorted',
);

is_deeply(
  $intro->table_columns('auth.users'),
  [qw(id email role embedding settings active nickname external_id availability)],
  'column order comes from introspection ordinals',
);

my $users = $intro->table_columns_info('auth.users');
is($users->{id}{is_auto_increment}, 1, 'serial defaults become auto increment');
is($users->{id}{sequence}, 'auth.users_id_seq', 'sequence name extracted');
is($users->{email}{data_type}, 'varchar', 'varchar type normalized');
is($users->{email}{size}, 255, 'varchar size retained');
is($users->{role}{data_type}, 'enum', 'enum type normalized');
is_deeply($users->{role}{extra}{list}, [qw(admin user guest)], 'enum values attached');
is($users->{role}{extra}{custom_type_name}, 'auth.role_type', 'enum keeps original custom type');
is($users->{embedding}{data_type}, 'vector', 'pgvector type normalized');
is($users->{embedding}{size}, 3, 'pgvector dimensions extracted');
is($users->{settings}{data_type}, 'jsonb', 'jsonb retained');
is($users->{availability}{data_type}, 'int4range', 'range type retained');
is($users->{nickname}{extra}{generated}, 's', 'generated marker preserved');
is($users->{external_id}{is_auto_increment}, 1, 'identity columns count as auto increment');

is_deeply($intro->table_pk_info('auth.users'), ['id'], 'primary key comes from indexes');
is_deeply(
  $intro->table_uniq_info('auth.users'),
  [[users_email_key => ['email']]],
  'simple unique indexes become loader unique constraints',
);

is_deeply(
  $intro->table_fk_info('public.posts'),
  [{
    constraint_name => 'posts_author_id_fkey',
    local_columns    => ['author_id'],
    remote_columns   => ['id'],
    remote_schema    => 'auth',
    remote_table     => 'users',
    attrs            => {
      is_deferrable => 0,
      on_delete     => 'CASCADE',
      on_update     => 'NO ACTION',
    },
  }],
  'foreign keys are normalized from introspection data',
);

# Test result_class_extra_statements instead of old table_pg_indexes
my @extra = $intro->result_class_extra_statements('auth.users');
my %extra_by_type;
for my $stmt (@extra) {
  push @{$extra_by_type{$stmt->[0]}}, $stmt;
}

is_deeply(
  $extra_by_type{pg_index},
  [
    [pg_index => 'users_email_name_idx' => { columns => ['email'], include => ['nickname'] }],
    [pg_index => 'users_embedding_idx' => { columns => ['embedding'], using => 'ivfflat', with => { lists => '100' } }],
    [pg_index => 'users_name_lower_idx' => { expression => 'lower(email)', unique => 1 }],
    [pg_index => 'users_role_partial_idx' => { columns => ['role'], where => q{role <> 'guest'::auth.role_type} }],
  ],
  'advanced PostgreSQL indexes are kept as pg_index metadata',
);

is_deeply(
  $extra_by_type{pg_trigger},
  [[pg_trigger => 'users_touch' => { when => 'BEFORE', event => 'UPDATE', for_each => 'ROW', execute => 'auth.touch_user()' }]],
  'trigger metadata is converted for PostgreSQL::Result',
);

is_deeply(
  $extra_by_type{pg_rls},
  [[pg_rls => { enable => 1, force => 1, policies => { users_self => { for => 'ALL', roles => ['app_user'], using => 'id = current_setting($$app.user_id$$)::integer', with_check => 'id = current_setting($$app.user_id$$)::integer' } } }]],
  'RLS metadata is converted for PostgreSQL::Result',
);

ok($intro->table_is_view('public.active_users'), 'views are flagged');
is(
  $intro->view_definition('public.active_users'),
  "SELECT u.id, u.email\n FROM auth.users u\n WHERE u.active",
  'view definitions are normalized for Loader view output',
);

is($intro->table_comment('auth.users'), 'Application users.', 'table comment comes from introspection');
is($intro->column_comment('auth.users', 'email'), 'Login address.', 'column comment comes from introspection');

is_deeply(
  $extra_by_type{pg_check_constraint},
  [[pg_check_constraint => 'users_email_check' => { constraint_name => 'users_email_check', definition => q{CHECK ((email ~~ '%@%'::text))}, columns => ['email'] }]],
  'CHECK constraints are exposed via pg_check_constraint in result_class_extra_statements',
);

done_testing;
