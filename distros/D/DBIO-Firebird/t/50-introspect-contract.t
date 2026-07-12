use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use DBIO::Generate;

# Offline test: DBIO::Firebird::Introspect fulfills the DBIO::Generate
# normalized contract from DBIO::Introspect::Base. No live Firebird DB --
# a fixture subclass supplies a hand-built native model matching the shape
# produced by Introspect::{Tables,Columns,Indexes,ForeignKeys}.

use_ok 'DBIO::Firebird::Introspect';

# --- All required contract methods exist -------------------------------------

my @contract_methods = qw(
  table_keys table_columns table_columns_info table_pk_info
  table_uniq_info table_fk_info table_is_view
);

for my $method (@contract_methods) {
  ok(DBIO::Firebird::Introspect->can($method),
    "DBIO::Firebird::Introspect implements $method");
}

# --- Fixture mirroring the native Firebird model -----------------------------
{
  package Test::Firebird::Gen::Fixture;
  use base 'DBIO::Firebird::Introspect';

  sub _build_model {
    my %tables = (
      AUTHOR     => { table_name => 'AUTHOR',     kind => 'table' },
      BOOK       => { table_name => 'BOOK',       kind => 'table' },
      AUTHORVIEW => { table_name => 'AUTHORVIEW', kind => 'view'  },
    );

    my %columns = (
      AUTHOR => [
        { column_name => 'ID',   data_type => 'integer', not_null => 1,
          default_value => undef, is_pk => 1, pk_position => 1, size => undef },
        { column_name => 'NAME', data_type => 'varchar', not_null => 1,
          default_value => undef, is_pk => 0, pk_position => 0, size => 128 },
      ],
      BOOK => [
        { column_name => 'ID',        data_type => 'integer', not_null => 1,
          default_value => undef, is_pk => 1, pk_position => 1, size => undef },
        { column_name => 'AUTHOR_ID', data_type => 'integer', not_null => 1,
          default_value => undef, is_pk => 0, pk_position => 0, size => undef },
        { column_name => 'PRICE',     data_type => 'decimal', not_null => 0,
          default_value => undef, is_pk => 0, pk_position => 0, size => [10, 2] },
        { column_name => 'TITLE',     data_type => 'varchar', not_null => 0,
          default_value => undef, is_pk => 0, pk_position => 0, size => 256 },
      ],
      AUTHORVIEW => [
        { column_name => 'ID',   data_type => 'integer', not_null => 0,
          default_value => undef, is_pk => 0, pk_position => 0, size => undef },
      ],
    );

    my %indexes = (
      BOOK => {
        IDX_BOOK_AUTHOR => { index_name => 'IDX_BOOK_AUTHOR',
                             is_unique => 0, columns => ['AUTHOR_ID'] },
      },
    );

    my %unique_constraints = (
      AUTHOR => [ [ 'UQ_AUTHOR_NAME', ['NAME'] ] ],
    );

    my %fks = (
      BOOK => [
        { fk_id => 'FK_BOOK_AUTHOR', from_table => 'BOOK',
          from_columns => ['AUTHOR_ID'], to_table => 'AUTHOR',
          to_columns => ['ID'], on_update => 'CASCADE', on_delete => 'RESTRICT',
          match => 'FULL' },
      ],
    );

    return { tables => \%tables, columns => \%columns,
             indexes => \%indexes, unique_constraints => \%unique_constraints,
             foreign_keys => \%fks };
  }
}

my $fixture = Test::Firebird::Gen::Fixture->new(dbh => {});

# --- table_keys --------------------------------------------------------------
is_deeply($fixture->table_keys, [qw/AUTHOR AUTHORVIEW BOOK/],
  'table_keys returns sorted tables + views');

# --- table_columns (ordered) -------------------------------------------------
is_deeply($fixture->table_columns('AUTHOR'), [qw/ID NAME/], 'AUTHOR column order');
is_deeply($fixture->table_columns('BOOK'),
  [qw/ID AUTHOR_ID PRICE TITLE/], 'BOOK column order');

# --- table_columns_info ------------------------------------------------------
my $book_info = $fixture->table_columns_info('BOOK');
is($book_info->{ID}{data_type}, 'integer', 'BOOK.ID data_type');
is($book_info->{ID}{is_nullable}, 0, 'BOOK.ID not nullable (PK, not_null)');
is($book_info->{TITLE}{is_nullable}, 1, 'BOOK.TITLE nullable');
is($book_info->{NAME}{size}, undef, 'BOOK has no NAME column');
is($book_info->{TITLE}{size}, 256, 'BOOK.TITLE scalar size');
is_deeply($book_info->{PRICE}{size}, [10, 2], 'BOOK.PRICE composite size');

# --- table_pk_info -----------------------------------------------------------
is_deeply($fixture->table_pk_info('BOOK'), ['ID'], 'BOOK pk');
is_deeply($fixture->table_pk_info('AUTHOR'), ['ID'], 'AUTHOR pk');

# --- table_uniq_info ---------------------------------------------------------
my $author_uniq = $fixture->table_uniq_info('AUTHOR');
is(scalar(@$author_uniq), 1, 'AUTHOR has one unique constraint');
is($author_uniq->[0][0], 'UQ_AUTHOR_NAME', 'unique constraint name');
is_deeply($author_uniq->[0][1], ['NAME'], 'unique constraint columns');

my $book_uniq = $fixture->table_uniq_info('BOOK');
is(scalar(@$book_uniq), 0, 'BOOK has no unique constraint');

# --- table_fk_info -----------------------------------------------------------
my $book_fk = $fixture->table_fk_info('BOOK');
is(scalar(@$book_fk), 1, 'BOOK has one FK');
is_deeply($book_fk->[0]{local_columns}, ['AUTHOR_ID'], 'FK local columns');
is($book_fk->[0]{remote_table}, 'AUTHOR', 'FK remote table');
is($book_fk->[0]{remote_schema}, undef, 'FK remote schema undef (Firebird has none)');
is_deeply($book_fk->[0]{remote_columns}, ['ID'], 'FK remote columns');
is($book_fk->[0]{attrs}{on_update}, 'CASCADE',  'FK on_update from model');
is($book_fk->[0]{attrs}{on_delete}, 'RESTRICT', 'FK on_delete from model');

# --- table_is_view -----------------------------------------------------------
is($fixture->table_is_view('AUTHOR'), 0, 'AUTHOR is not a view');
is($fixture->table_is_view('AUTHORVIEW'), 1, 'AUTHORVIEW is a view');

# --- generate-via-introspect: DBIO::Generate->dump ---------------------------
{
  my $tmpdir = tempdir(CLEANUP => 1);
  my $gen = DBIO::Generate->new(
    schema_class   => 'TestFirebird::Schema',
    dump_directory => $tmpdir,
    style          => 'vanilla',
    use_namespaces => 1,
    generate_pod   => 0,
    quiet          => 1,
  );

  $gen->dump($fixture);

  my $author_pm = "$tmpdir/TestFirebird/Schema/Result/Author.pm";
  my $book_pm   = "$tmpdir/TestFirebird/Schema/Result/Book.pm";
  my $view_pm   = "$tmpdir/TestFirebird/Schema/Result/Authorview.pm";

  ok(-f $author_pm, 'Author.pm generated');
  ok(-f $book_pm,   'Book.pm generated');
  ok(-f $view_pm,   'Authorview.pm generated');

  my $author_src = do { open my $fh, '<', $author_pm; local $/; <$fh> };
  like($author_src, qr/table\(['"]AUTHOR['"]\)/i, 'Author uses correct table name');
  like($author_src, qr/has_many/,           'Author has_many relationship');

  my $book_src = do { open my $fh, '<', $book_pm; local $/; <$fh> };
  like($book_src, qr/table\(['"]BOOK['"]\)/i, 'Book uses correct table name');
  like($book_src, qr/belongs_to/,        'Book belongs_to relationship');
  like($book_src, qr/TestFirebird::Schema::Result::Author/,
    'Book references Author class');
}

done_testing;
