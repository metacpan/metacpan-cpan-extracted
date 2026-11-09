use strict;
use warnings;

use Test::More;

use lib 'lib';
use DBIO::PostgreSQL::DDL;

{
  package DBIO::Test::PgDDL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('auth');
}

{
  package DBIO::Test::PgDDL::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id => {
      data_type         => 'integer',
      is_auto_increment => 1,
      is_nullable       => 0,
    },
    email => {
      data_type   => 'varchar',
      size        => 255,
      is_nullable => 0,
    },
    tenant_key => {
      data_type   => 'varchar',
      size        => 64,
      is_nullable => 0,
    },
    nickname => {
      data_type => 'varchar',
      size      => 64,
      # no is_nullable key: missing means NOT NULL (ADR 0043, core k147)
    },
    embedding => {
      data_type   => 'vector',
      size        => 1536,
      is_nullable => 1,
    },
    half_embedding => {
      data_type   => 'halfvec',
      size        => 1536,
      is_nullable => 1,
    },
    sparse_embedding => {
      data_type   => 'sparsevec',
      size        => 1024,
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(users_email => ['email']);
  __PACKAGE__->add_unique_constraint(['tenant_key']);
  __PACKAGE__->pg_index('users_name_lower_idx' => {
    expression => 'lower(email)',
    unique     => 1,
  });
  __PACKAGE__->pg_index('users_email_gin_idx' => {
    using   => 'gin',
    columns => ['email'],
  });
  __PACKAGE__->pg_trigger('users_touch' => {
    when     => 'AFTER',
    event    => 'UPDATE',
    for_each => 'STATEMENT',
    execute  => 'auth.touch_user()',
  });
  __PACKAGE__->pg_rls({
    enable   => 1,
    force    => 1,
    policies => {
      users_self => {
        for        => 'ALL',
        roles      => [qw(app_user admin)],
        using      => 'id > 0',
        with_check => 'id > 0',
      },
    },
  });
}

DBIO::Test::PgDDL::Schema->register_class(
  User => 'DBIO::Test::PgDDL::Schema::Result::User',
);

my $sql = DBIO::PostgreSQL::DDL->install_ddl('DBIO::Test::PgDDL::Schema');

like($sql, qr/CREATE TABLE auth\.users/s, 'qualified table created');
like($sql, qr/email character varying\(255\) NOT NULL/s, 'varchar size honored (email)');
like($sql, qr/tenant_key character varying\(64\) NOT NULL/s, 'varchar size honored (tenant_key)');
like($sql, qr/nickname character varying\(64\) NOT NULL/s, 'missing is_nullable deploys as NOT NULL (ADR 0043)');
like($sql, qr/embedding vector\(1536\)/s, 'pgvector size honored (data_type vector, size 1536 -> vector(1536))');
unlike($sql, qr/embedding\s+vector\s+(?!\()/si, 'embedding does not deploy as bare vector (karr k56)');
like($sql, qr/half_embedding halfvec\(1536\)/s, 'halfvec size honored (data_type halfvec, size 1536 -> halfvec(1536))');
unlike($sql, qr/half_embedding\s+halfvec\s+(?!\()/si, 'half_embedding does not deploy as bare halfvec (karr k58)');
like($sql, qr/sparse_embedding sparsevec\(1024\)/s, 'sparsevec size honored (data_type sparsevec, size 1024 -> sparsevec(1024))');
unlike($sql, qr/sparse_embedding\s+sparsevec\s+(?!\()/si, 'sparse_embedding does not deploy as bare sparsevec (karr k58)');
like($sql, qr/CONSTRAINT users_email UNIQUE \(email\)/s, 'named unique constraint emitted');
like($sql, qr/CONSTRAINT users_tenant_key UNIQUE \(tenant_key\)/s, 'auto-named unique constraint emitted');
unlike($sql, qr/CONSTRAINT primary UNIQUE/s, 'primary unique constraint not duplicated');
like($sql, qr/CREATE UNIQUE INDEX users_name_lower_idx ON auth\.users \(lower\(email\)\);/s, 'unique expression index emitted');
like($sql, qr/CREATE INDEX users_email_gin_idx ON auth\.users USING gin \(email\);/s, 'access-method index form emitted (USING gin)');
like($sql, qr/CREATE TRIGGER users_touch AFTER UPDATE ON auth\.users FOR EACH STATEMENT EXECUTE FUNCTION auth\.touch_user\(\);/s, 'trigger orientation emitted');
like($sql, qr/CREATE POLICY users_self ON auth\.users TO app_user, admin USING \(id > 0\) WITH CHECK \(id > 0\);/s, 'RLS roles emitted');

done_testing;
