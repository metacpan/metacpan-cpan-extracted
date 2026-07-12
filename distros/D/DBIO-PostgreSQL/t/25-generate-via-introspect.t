use strict;
use warnings;

use Test::More;
use File::Temp ();
use DBIO::Util ();

# Needs DBIO core (not installed): prove -I/path/to/dbio/lib -l t/...

use DBIO::Generate;

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

# Same fixture as t/24-introspect-contract.t
my $MODEL_FIXTURE = {
  tables => {
    'public.users' => {
      schema_name     => 'public',
      table_name      => 'users',
      kind            => 'r',
      kind_label      => 'table',
      comment         => 'Application users.',
      rls_enabled     => 0,
      rls_forced      => 0,
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
  },
  columns => {
    'public.users' => [
      {
        column_name   => 'id',
        ordinal       => 1,
        data_type     => 'integer',
        not_null      => 1,
        default_value => q{nextval('public.users_id_seq'::regclass)},
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
      {
        column_name   => 'title',
        ordinal       => 3,
        data_type     => 'text',
        not_null      => 1,
        default_value => undef,
        identity      => '',
        generated     => '',
        comment       => 'Post title.',
        type_category => 'b',
        type_schema   => 'pg_catalog',
      },
    ],
  },
  indexes => {
    'public.users' => {
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
  triggers => {},
  policies => {},
  foreign_keys => {
    'public.posts' => [
      {
        constraint_name => 'posts_author_id_fkey',
        remote_schema   => 'public',
        remote_table    => 'users',
        local_columns   => ['author_id'],
        remote_columns  => ['id'],
        on_delete       => 'CASCADE',
        on_update       => 'NO ACTION',
        is_deferrable   => 0,
      },
    ],
  },
  check_constraints => {},
  types => {},
};

my $intro = DBIO::PostgreSQL::Introspect::Mock->new(
  model         => $MODEL_FIXTURE,
  schema_filter => ['public'],
  preserve_case => 0,
);

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $gen = DBIO::Generate->new(
  dump_directory => $tmpdir,
  schema_class   => 'Test::Schema',
  style          => 'vanilla',
  use_namespaces => 1,
  quiet          => 1,
);

$gen->dump($intro);

# Check that files were generated
ok(-e "$tmpdir/Test/Schema/Result/User.pm", 'User.pm generated');
ok(-e "$tmpdir/Test/Schema/Result/Post.pm", 'Post.pm generated');

# Read and verify the User class
my $user_src = DBIO::Util::slurp_file_utf8("$tmpdir/Test/Schema/Result/User.pm");
like($user_src, qr/__PACKAGE__->table\(['"]users['"]\)/, 'table name set');
like($user_src, qr/__PACKAGE__->set_primary_key\(['"]id['"]\)/, 'primary key set');
like($user_src, qr/data_type => ['"]integer['"]/, 'id column type');
like($user_src, qr/data_type => ['"]varchar['"]/, 'email column type');
like($user_src, qr/size => 255/, 'varchar size');

# Read and verify the Post class
my $post_src = DBIO::Util::slurp_file_utf8("$tmpdir/Test/Schema/Result/Post.pm");
like($post_src, qr/__PACKAGE__->table\(['"]posts['"]\)/, 'posts table name set');
like($post_src, qr/__PACKAGE__->set_primary_key\(['"]id['"]\)/, 'posts primary key');

# Verify relationship inference (belongs_to on Post, has_many on User)
like($post_src, qr/belongs_to/, 'Post has belongs_to relationship');
like($user_src, qr/has_many/, 'User has has_many relationship');

# Verify pg_schema is emitted for the schema qualification
like($post_src, qr/__PACKAGE__->pg_schema\(['"]public['"]\)/, 'pg_schema emitted for table');

done_testing;