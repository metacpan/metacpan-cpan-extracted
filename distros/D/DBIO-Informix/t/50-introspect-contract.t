use strict;
use warnings;
use Test::More;

# Offline introspect-contract test — no live DB. Verifies that
# DBIO::Informix::Introspect implements the normalized generation contract
# from DBIO::Introspect::Base on top of the native model. A fixture subclass
# supplies a fixed model (the shape Tables/Columns/Indexes/ForeignKeys
# produce) so the contract methods can be exercised without a database.
# See dbio-mysql/t/50-introspect-contract.t for the sibling pattern.

use_ok 'DBIO::Informix::Introspect';

my @contract_methods = qw(
  table_keys table_columns table_columns_info table_pk_info
  table_uniq_info table_fk_info table_is_view
);

for my $method (@contract_methods) {
  ok(DBIO::Informix::Introspect->can($method),
    "DBIO::Informix::Introspect implements $method");
}

# --- Fixture mirroring the native Informix model shape ---
{
  package Test::Informix::Introspect::Fixture;
  use base 'DBIO::Informix::Introspect';

  sub _build_model {
    return {
      tables => {
        author => { table_name => 'author', owner => 'me', kind => 'table' },
        book   => { table_name => 'book',   owner => 'me', kind => 'table' },
        myview => { table_name => 'myview', owner => 'me', kind => 'view'  },
      },
      columns => {
        author => [
          { column_name => 'id',   data_type => 'serial',        not_null => 1,
            default_value => undef, is_pk => 1, pk_position => 1,
            is_auto_increment => 1 },
          { column_name => 'name', data_type => 'varchar',       not_null => 1,
            default_value => undef, is_pk => 0, pk_position => 0,
            size => 128, is_auto_increment => 0 },
        ],
        book => [
          { column_name => 'id',        data_type => 'serial',   not_null => 1,
            default_value => undef, is_pk => 1, pk_position => 1,
            is_auto_increment => 1 },
          { column_name => 'author_id', data_type => 'integer',  not_null => 1,
            default_value => undef, is_pk => 0, pk_position => 0,
            is_auto_increment => 0 },
          { column_name => 'title',     data_type => 'varchar',  not_null => 1,
            default_value => \'today', is_pk => 0, pk_position => 0,
            size => 255, is_auto_increment => 0 },
        ],
        myview => [
          { column_name => 'id', data_type => 'integer', not_null => 1,
            default_value => undef, is_pk => 0, pk_position => 0,
            is_auto_increment => 0 },
        ],
      },
      indexes => {
        author => {
          # PK-backing unique index — must be excluded from table_uniq_info
          pk_author   => { index_name => 'pk_author',   unique => 1, columns => ['id'] },
          uniq_name   => { index_name => 'uniq_name',   unique => 1, columns => ['name'] },
        },
        book => {
          pk_book     => { index_name => 'pk_book',     unique => 1, columns => ['id'] },
          idx_author  => { index_name => 'idx_author',  unique => 0, columns => ['author_id'] },
        },
      },
      foreign_keys => {
        book => [
          { fk_name => 'book_author_fk', from_columns => ['author_id'],
            to_table => 'author', to_columns => ['id'],
            match => 'simple', upd_rule => 'R', del_rule => 'C' },
        ],
      },
    };
  }
}

my $intro = Test::Informix::Introspect::Fixture->new(dbh => {});

# table_keys
is_deeply($intro->table_keys, [qw/author book myview/],
  'table_keys returns sorted table + view names');

# table_columns
is_deeply($intro->table_columns('author'), [qw/id name/],
  'author column order preserved');
is_deeply($intro->table_columns('book'), [qw/id author_id title/],
  'book column order preserved');

# table_columns_info
my $author_info = $intro->table_columns_info('author');
is($author_info->{id}{is_auto_increment}, 1, 'author.id is_auto_increment');
is($author_info->{id}{is_nullable},       0, 'author.id not nullable');
is($author_info->{name}{is_nullable},     0, 'author.name not nullable');
is($author_info->{name}{size},          128, 'author.name size carried through');
is($author_info->{name}{data_type}, 'varchar', 'author.name data_type');
ok(!exists $author_info->{id}{size}, 'sizeless column omits size key (no undef key)');
ok(!exists $author_info->{id}{default_value}, 'defaultless column omits default_value key');

my $book_info = $intro->table_columns_info('book');
is_deeply($book_info->{title}{default_value}, \'today',
  'book.title literal default preserved as scalar ref');

# table_pk_info
is_deeply($intro->table_pk_info('author'), [qw/id/], 'author pk');
is_deeply($intro->table_pk_info('book'),   [qw/id/], 'book pk');
is_deeply($intro->table_pk_info('myview'), [],       'view has no pk');

# table_uniq_info — PK-backing index excluded, real unique kept
my $author_uniq = $intro->table_uniq_info('author');
is(scalar @$author_uniq, 1, 'author has one unique (pk index excluded)');
is($author_uniq->[0][0], 'uniq_name', 'author unique constraint name');
is_deeply($author_uniq->[0][1], ['name'], 'author unique columns');

my $book_uniq = $intro->table_uniq_info('book');
is(scalar @$book_uniq, 0, 'book has no unique (only pk + non-unique index)');

# table_fk_info
my $book_fk = $intro->table_fk_info('book');
is(scalar @$book_fk, 1, 'book has one FK');
is_deeply($book_fk->[0]{local_columns}, ['author_id'], 'fk local columns');
is($book_fk->[0]{remote_table}, 'author', 'fk remote table');
is_deeply($book_fk->[0]{remote_columns}, ['id'], 'fk remote columns');
is($book_fk->[0]{attrs}{on_update}, 'R', 'fk on_update rule');
is($book_fk->[0]{attrs}{on_delete}, 'C', 'fk on_delete rule');
is($book_fk->[0]{constraint_name}, "book_author_fk", "fk carries the canonical constraint_name key");
ok(!exists $book_fk->[0]{_constraint_name}, "fk no longer carries the legacy _constraint_name key");

# table_is_view
is($intro->table_is_view('author'), 0, 'author is not a view');
is($intro->table_is_view('myview'), 1, 'myview is a view');

# --- Optional: full generate-via-introspect, only if DBIO::Generate present ---
SKIP: {
  eval { require DBIO::Generate; 1 }
    or skip 'DBIO::Generate not installed', 4;
  require File::Temp;

  my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
  my $gen = DBIO::Generate->new(
    schema_class   => 'TestInformix::Schema',
    dump_directory => $tmpdir,
    style          => 'vanilla',
    use_namespaces => 1,
    generate_pod   => 0,
    quiet          => 1,
  );

  my @warnings;
  do {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $gen->dump($intro);
  };
  is_deeply(\@warnings, [], 'dump emits no warnings')
    or diag "warnings:\n@warnings";

  ok(-f "$tmpdir/TestInformix/Schema/Result/Author.pm", 'Author.pm generated');
  ok(-f "$tmpdir/TestInformix/Schema/Result/Book.pm",   'Book.pm generated');

  open my $fh, '<', "$tmpdir/TestInformix/Schema/Result/Book.pm" or die $!;
  my $book_src = do { local $/; <$fh> };
  like($book_src, qr/belongs_to/, 'Book has belongs_to relationship');
}

done_testing;
