use strict;
use warnings;

use Test::More;

use lib 'lib';
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Introspect;

# karr k54 -- two fidelity holes on the introspect -> generate -> deploy path.
#
# WHY this test exists: introspection already reported both facts, but the
# generate/deploy end of the path threw them away, so re-deploying an
# introspected database silently produced a *different* database.
#
#   1. A covering index (CREATE INDEX ... INCLUDE (nickname)) came back from
#      introspection as { include => ['nickname'] }, but DBIO::PostgreSQL::DDL
#      did not know the key at all and dropped it. The redeployed index no
#      longer covers the queries it was built for -- index-only scans turn
#      back into heap fetches, with nothing failing to say so.
#
#   2. A UNIQUE btree index carrying a non-default operator class was demoted
#      to a plain UNIQUE constraint, because "unique + btree + no predicate +
#      no expression" was taken to mean "this is really a constraint". The
#      operator class is not expressible on a constraint, so text_pattern_ops
#      was lost and the object changed kind (constraint, not index).
#
# So the point below is not "a key called include is interpolated" -- it is
# "what PostgreSQL reported can be deployed again and gives back the same
# objects".

# -----------------------------------------------------------------------
# 1. DDL rendering: INCLUDE, and its position relative to WITH / WHERE
# -----------------------------------------------------------------------

{
  package IncludeDDL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package IncludeDDL::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_nullable => 0 },
    email    => { data_type => 'text',    is_nullable => 1 },
    name     => { data_type => 'text',    is_nullable => 1 },
    nickname => { data_type => 'text',    is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->pg_index('idx_covering' => {
    columns => ['email'],
    include => ['nickname'],
  });

  __PACKAGE__->pg_index('idx_covering_multi' => {
    columns => ['email', 'name'],
    include => ['nickname', 'id'],
  });

  # INCLUDE must precede WITH ...
  __PACKAGE__->pg_index('idx_covering_with' => {
    columns => ['email'],
    include => ['nickname'],
    with    => { fillfactor => 90 },
  });

  # ... and WHERE ...
  __PACKAGE__->pg_index('idx_covering_where' => {
    columns => ['email'],
    include => ['nickname'],
    where   => 'email IS NOT NULL',
  });

  # ... and both, in that order. Any other order is a syntax error.
  __PACKAGE__->pg_index('idx_covering_all' => {
    columns => ['email'],
    include => ['nickname'],
    with    => { fillfactor => 90 },
    where   => 'email IS NOT NULL',
  });

  __PACKAGE__->pg_index('idx_covering_unique' => {
    columns => ['email'],
    include => ['nickname'],
    unique  => 1,
  });

  # The operator class belongs to the key column, so it stays inside the key
  # list and INCLUDE follows it.
  __PACKAGE__->pg_index('idx_covering_opclass' => {
    columns   => ['name'],
    opclasses => { name => 'text_pattern_ops' },
    include   => ['nickname'],
  });

  # An empty list is not a covering index -- no empty INCLUDE ().
  __PACKAGE__->pg_index('idx_covering_empty' => {
    columns => ['email'],
    include => [],
  });

  # No include key at all -- rendering must be untouched.
  __PACKAGE__->pg_index('idx_plain' => {
    columns => ['email'],
  });
}

IncludeDDL::Schema->register_class(
  User => 'IncludeDDL::Schema::Result::User',
);

my $sql = DBIO::PostgreSQL::DDL->install_ddl('IncludeDDL::Schema');

like(
  $sql,
  qr/\QCREATE INDEX idx_covering ON auth.users (email) INCLUDE (nickname);\E/,
  'covering index renders its non-key columns',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_multi ON auth.users (email, name) INCLUDE (nickname, id);\E/,
  'INCLUDE keeps the declared column order',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_with ON auth.users (email) INCLUDE (nickname) WITH (fillfactor = 90);\E/,
  'INCLUDE is rendered before WITH',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_where ON auth.users (email) INCLUDE (nickname) WHERE email IS NOT NULL;\E/,
  'INCLUDE is rendered before WHERE',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_all ON auth.users (email) INCLUDE (nickname) WITH (fillfactor = 90) WHERE email IS NOT NULL;\E/,
  'INCLUDE, WITH and WHERE keep the order PostgreSQL accepts',
);

like(
  $sql,
  qr/\QCREATE UNIQUE INDEX idx_covering_unique ON auth.users (email) INCLUDE (nickname);\E/,
  'a unique covering index keeps its payload columns',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_opclass ON auth.users (name text_pattern_ops) INCLUDE (nickname);\E/,
  'the operator class stays in the key list, INCLUDE follows it',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_covering_empty ON auth.users (email);\E/,
  'an empty include list emits no INCLUDE clause',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_plain ON auth.users (email);\E/,
  'an index without include renders exactly as before',
);

unlike($sql, qr/INCLUDE \(\)/, 'no empty INCLUDE () is ever emitted');

# -----------------------------------------------------------------------
# 2. introspect -> generate: a unique btree index with an operator class
#    stays an index, and is claimed by exactly one of the two paths
# -----------------------------------------------------------------------

# DBIO::Generate feeds a result class from two independent Introspect
# methods: table_uniq_info becomes add_unique_constraint, and
# result_class_extra_statements becomes pg_index. They must partition the
# unique indexes between them -- an index claimed by both is emitted twice
# under one name, and PostgreSQL rejects the second one.

{
  package IncludeIntrospect::Mock;
  use base 'DBIO::PostgreSQL::Introspect';

  sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
  }
  sub _build_model { die 'model is injected' }
}

my $intro = IncludeIntrospect::Mock->new(
  model => {
    tables  => { 'auth.users' => { schema_name => 'auth', table_name => 'users', kind => 'r' } },
    columns => { 'auth.users' => [] },
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
        # Plain unique index: really is a constraint, and must stay one.
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
          opclasses       => {},
        },
        # Same shape, but with an operator class a constraint cannot carry.
        users_name_pat_key => {
          index_name      => 'users_name_pat_key',
          access_method   => 'btree',
          is_unique       => 1,
          is_primary      => 0,
          is_valid        => 1,
          definition      => q{CREATE UNIQUE INDEX users_name_pat_key ON auth.users USING btree (name text_pattern_ops)},
          predicate       => undef,
          expressions     => undef,
          columns         => ['name'],
          include_columns => [],
          storage_params  => {},
          opclasses       => { name => 'text_pattern_ops' },
        },
        # Covering index, as pinned by t/24-introspect-contract.t.
        users_email_name_idx => {
          index_name      => 'users_email_name_idx',
          access_method   => 'btree',
          is_unique       => 0,
          is_primary      => 0,
          is_valid        => 1,
          definition      => q{CREATE INDEX users_email_name_idx ON auth.users USING btree (email) INCLUDE (nickname)},
          predicate       => undef,
          expressions     => undef,
          columns         => ['email'],
          include_columns => ['nickname'],
          storage_params  => {},
        },
      },
    },
    triggers          => {},
    policies          => {},
    foreign_keys      => {},
    check_constraints => {},
    types             => {},
  },
  schema_filter => ['auth'],
  preserve_case => 0,
);

is_deeply(
  $intro->table_uniq_info('auth.users'),
  [ [ users_email_key => ['email'] ] ],
  'only the operator-class-free unique index is handed over as a constraint',
);

my @pg_index_stmts = grep { $_->[0] eq 'pg_index' }
  $intro->result_class_extra_statements('auth.users');

is_deeply(
  \@pg_index_stmts,
  [
    [ pg_index => 'users_email_name_idx' => { columns => ['email'], include => ['nickname'] } ],
    [ pg_index => 'users_name_pat_key' => {
        columns   => ['name'],
        unique    => 1,
        opclasses => { name => 'text_pattern_ops' },
      } ],
  ],
  'the unique index with an operator class stays an index, the plain one does not reappear here',
);

# -----------------------------------------------------------------------
# 3. Close the loop: both generate outputs applied to one result class
# -----------------------------------------------------------------------

{
  package IncludeRoundtrip::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package IncludeRoundtrip::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_nullable => 0 },
    email    => { data_type => 'text',    is_nullable => 1 },
    name     => { data_type => 'text',    is_nullable => 1 },
    nickname => { data_type => 'text',    is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key(@{ $intro->table_pk_info('auth.users') });
}

# Exactly what DBIO::Generate emits: uniq -> add_unique_constraint,
# extra_statements -> pg_index.
IncludeRoundtrip::Schema::Result::User->add_unique_constraint(@$_)
  for @{ $intro->table_uniq_info('auth.users') };
IncludeRoundtrip::Schema::Result::User->pg_index(@{$_}[1, 2])
  for @pg_index_stmts;

IncludeRoundtrip::Schema->register_class(
  User => 'IncludeRoundtrip::Schema::Result::User',
);

my $round_sql = DBIO::PostgreSQL::DDL->install_ddl('IncludeRoundtrip::Schema');

like(
  $round_sql,
  qr/\QCREATE UNIQUE INDEX users_name_pat_key ON auth.users (name text_pattern_ops);\E/,
  'introspect -> generate -> deploy keeps the unique index and its operator class',
);

like(
  $round_sql,
  qr/\QCONSTRAINT users_email_key UNIQUE (email)\E/,
  'the plain unique index still deploys as a constraint',
);

like(
  $round_sql,
  qr/\QCREATE INDEX users_email_name_idx ON auth.users (email) INCLUDE (nickname);\E/,
  'introspect -> generate -> deploy keeps the covering columns',
);

# The double-emission guard: table_uniq_info and result_class_extra_statements
# must never both claim the same index. If they do, the DDL names it twice --
# once as a table constraint, once as a CREATE UNIQUE INDEX -- and the second
# statement fails, because the constraint already owns that index name.
for my $name (qw( users_email_key users_name_pat_key users_email_name_idx )) {
  my $count = () = $round_sql =~ /\b\Q$name\E\b/g;
  is($count, 1, "$name is emitted exactly once across constraints and indexes");
}

done_testing;
