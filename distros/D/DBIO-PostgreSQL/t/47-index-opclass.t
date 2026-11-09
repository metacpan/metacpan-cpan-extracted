use strict;
use warnings;

use Test::More;

use lib 'lib';
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Introspect;

# karr k39 -- per-column operator classes on pg_index.
#
# WHY this test exists: pgvector's hnsw access method has NO default operator
# class for vector. An index declared without one renders
#
#   CREATE INDEX ... USING hnsw (embedding)
#
# which PostgreSQL rejects outright ("data type vector has no default operator
# class for access method hnsw"), and pg_index had no way to name one. ivfflat
# does have a default for vector, vector_l2_ops (pg_opclass.opcdefault, see
# t/48-index-opclass-live.t), so the ivfflat example DBIO::PostgreSQL::Result
# used to show without an operator class did deploy -- but only ever with that
# one distance (karr k85). So the point here is not
# "opclasses are appended to column names" -- it is "a vector index declared
# the way the POD shows it produces SQL PostgreSQL will accept", and
# "introspecting such an index and generating a result class from it does not
# throw the opclass away".

# -----------------------------------------------------------------------
# 1. DDL rendering
# -----------------------------------------------------------------------

{
  package OpclassDDL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package OpclassDDL::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer',    is_nullable => 0 },
    name      => { data_type => 'text',       is_nullable => 1 },
    embedding => { data_type => 'vector(3)',  is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  # The two examples from the DBIO::PostgreSQL::Result POD, verbatim.
  __PACKAGE__->pg_index('idx_users_embedding' => {
    using     => 'ivfflat',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_l2_ops' },
    with      => { lists => 100 },
  });
  __PACKAGE__->pg_index('idx_users_embedding_cos' => {
    using     => 'hnsw',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_cosine_ops' },
    with      => { m => 16, ef_construction => 64 },
  });

  # opclass without WITH, and with UNIQUE
  __PACKAGE__->pg_index('idx_users_name_pat' => {
    using     => 'btree',
    columns   => ['name'],
    opclasses => { name => 'text_pattern_ops' },
    unique    => 1,
  });

  # opclass together with a partial-index predicate
  __PACKAGE__->pg_index('idx_users_name_partial' => {
    columns   => ['name'],
    opclasses => { name => 'text_pattern_ops' },
    where     => 'name IS NOT NULL',
  });

  # multi-column: only the column that names an opclass gets one
  __PACKAGE__->pg_index('idx_users_multi' => {
    columns   => ['id', 'name'],
    opclasses => { name => 'text_pattern_ops' },
  });

  # no opclasses at all -- rendering must be untouched
  __PACKAGE__->pg_index('idx_users_plain' => {
    columns => ['name'],
  });
}

OpclassDDL::Schema->register_class(
  User => 'OpclassDDL::Schema::Result::User',
);

my $sql = DBIO::PostgreSQL::DDL->install_ddl('OpclassDDL::Schema');

like(
  $sql,
  qr/\QCREATE INDEX idx_users_embedding ON auth.users USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);\E/,
  'documented ivfflat example now renders SQL PostgreSQL accepts',
);
unlike(
  $sql,
  qr/USING ivfflat \(embedding\)/,
  'ivfflat index is never emitted without an operator class',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_users_embedding_cos ON auth.users USING hnsw (embedding vector_cosine_ops) WITH (ef_construction = 64, m = 16);\E/,
  'hnsw index renders opclass and storage parameters',
);

like(
  $sql,
  qr/\QCREATE UNIQUE INDEX idx_users_name_pat ON auth.users USING btree (name text_pattern_ops);\E/,
  'opclass renders with UNIQUE and without WITH',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_users_name_partial ON auth.users (name text_pattern_ops) WHERE name IS NOT NULL;\E/,
  'opclass renders ahead of a WHERE predicate',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_users_multi ON auth.users (id, name text_pattern_ops);\E/,
  'columns without an opclass stay bare',
);

like(
  $sql,
  qr/\QCREATE INDEX idx_users_plain ON auth.users (name);\E/,
  'an index with no opclasses renders exactly as before',
);

# -----------------------------------------------------------------------
# 2. introspect -> generate -> deploy keeps the operator class
# -----------------------------------------------------------------------

{
  package OpclassIntrospect::Mock;
  use base 'DBIO::PostgreSQL::Introspect';

  sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
  }
  sub _build_model { die 'model is injected' }
}

my $intro = OpclassIntrospect::Mock->new(
  model => {
    tables  => { 'auth.users' => { schema_name => 'auth', table_name => 'users', kind => 'r' } },
    columns => { 'auth.users' => [] },
    indexes => {
      'auth.users' => {
        users_embedding_idx => {
          index_name      => 'users_embedding_idx',
          access_method   => 'hnsw',
          is_unique       => 0,
          is_primary      => 0,
          is_valid        => 1,
          definition      => q{CREATE INDEX users_embedding_idx ON auth.users USING hnsw (embedding vector_cosine_ops) WITH (m='16', ef_construction='64')},
          predicate       => undef,
          expressions     => undef,
          columns         => ['embedding'],
          include_columns => [],
          storage_params  => { m => '16', ef_construction => '64' },
          opclasses       => { embedding => 'vector_cosine_ops' },
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

my ($pg_index_stmt) = grep { $_->[0] eq 'pg_index' }
  $intro->result_class_extra_statements('auth.users');

is_deeply(
  $pg_index_stmt,
  [
    pg_index => 'users_embedding_idx' => {
      columns   => ['embedding'],
      using     => 'hnsw',
      opclasses => { embedding => 'vector_cosine_ops' },
      with      => { m => '16', ef_construction => '64' },
    },
  ],
  'introspected hnsw index reaches the generate path with its operator class',
);

# Close the loop: feed the reconstructed metadata back into a result class and
# check the DDL is the deployable statement we started from. Without the
# opclass this round-trip produces SQL PostgreSQL refuses.
{
  package OpclassRoundtrip::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package OpclassRoundtrip::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    embedding => { data_type => 'vector(3)', is_nullable => 1 },
  );
}

OpclassRoundtrip::Schema::Result::User->pg_index(
  @{$pg_index_stmt}[1, 2]
);
OpclassRoundtrip::Schema->register_class(
  User => 'OpclassRoundtrip::Schema::Result::User',
);

like(
  DBIO::PostgreSQL::DDL->install_ddl('OpclassRoundtrip::Schema'),
  qr/\QCREATE INDEX users_embedding_idx ON auth.users USING hnsw (embedding vector_cosine_ops) WITH (ef_construction = 64, m = 16);\E/,
  'introspect -> generate -> deploy round-trip stays deployable',
);

done_testing;
