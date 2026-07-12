use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use DBIO::Generate;

# Test that DBIO::MySQL::Introspect fulfills the DBIO::Generate contract.
# We verify (a) every contract method is present, and (b) the methods
# produce the expected shape when fed a canned model that mirrors what
# the live information_schema readers would produce.

my $tmpdir = tempdir(CLEANUP => 1);

# Test 1: DBIO::MySQL::Introspect has all required contract methods
my @contract_methods = qw(
  table_keys table_columns table_columns_info table_pk_info
  table_uniq_info table_fk_info table_is_view view_definition
  result_class_extra_statements
);

for my $method (@contract_methods) {
  ok(DBIO::MySQL::Introspect->can($method), "DBIO::MySQL::Introspect has $method");
}

# Test 2: A fixture introspect implementing the same data model as MySQL::Introspect
# uses the DBIO::Generate contract correctly
{
  package Test::MySQL::Gen::Fixture;
  use base 'DBIO::MySQL::Introspect';

  # Mirror the model structure that Tables/Columns/Indexes/ForeignKeys produce
  sub _build_model {
    my ($self) = @_;
    my %tables = (
      artist => {
        table_name => 'artist', kind => 'table', engine => 'InnoDB',
        table_collation => 'utf8mb4_general_ci',
        row_format => 'Dynamic', comment => 'Artist table',
      },
      cd => {
        table_name => 'cd', kind => 'table', engine => 'InnoDB',
        table_collation => 'utf8mb4_general_ci',
        row_format => 'Dynamic', comment => 'CD table',
      },
      myview => {
        table_name => 'myview', kind => 'view', engine => undef,
        table_collation => undef, row_format => undef, comment => '',
      },
    );
    my %columns = (
      artist => [
        { column_name => 'id', data_type => 'int', column_type => 'int(11)',
          not_null => 1, default_value => undef, is_auto_increment => 1,
          is_pk => 1, character_set => undef, collation => undef,
          comment => 'PK', extra => 'auto_increment' },
        { column_name => 'name', data_type => 'varchar', column_type => 'varchar(128)',
          not_null => 1, default_value => "'Unknown'", is_auto_increment => 0,
          is_pk => 0, character_set => 'utf8mb4', collation => 'utf8mb4_general_ci',
          comment => 'Artist name', extra => '' },
      ],
      cd => [
        { column_name => 'id', data_type => 'int', column_type => 'int(11)',
          not_null => 1, default_value => undef, is_auto_increment => 1,
          is_pk => 1, character_set => undef, collation => undef,
          comment => '', extra => 'auto_increment' },
        { column_name => 'artist_id', data_type => 'int', column_type => 'int(11)',
          not_null => 1, default_value => undef, is_auto_increment => 0,
          is_pk => 0, character_set => undef, collation => undef,
          comment => '', extra => '' },
        { column_name => 'title', data_type => 'varchar', column_type => 'varchar(256)',
          not_null => 1, default_value => undef, is_auto_increment => 0,
          is_pk => 0, character_set => 'utf8mb4', collation => 'utf8mb4_general_ci',
          comment => '', extra => '' },
      ],
      myview => [
        { column_name => 'id', data_type => 'int', column_type => 'int(11)',
          not_null => 1, default_value => undef, is_auto_increment => 0,
          is_pk => 0, character_set => undef, collation => undef,
          comment => '', extra => '' },
      ],
    );
    my %indexes = (
      artist => {
        PRIMARY => { index_name => 'PRIMARY', is_unique => 1, columns => ['id'],
                     index_type => 'BTREE', origin => 'pk' },
        idx_name => { index_name => 'idx_name', is_unique => 1, columns => ['name'],
                      index_type => 'BTREE', origin => 'u' },
      },
      cd => {
        PRIMARY => { index_name => 'PRIMARY', is_unique => 1, columns => ['id'],
                     index_type => 'BTREE', origin => 'pk' },
        idx_artist => { index_name => 'idx_artist', is_unique => 0, columns => ['artist_id'],
                        index_type => 'BTREE', origin => 'c' },
      },
    );
    my %fks = (
      cd => [
        { table_name => 'cd', constraint_name => 'cd_artist_fk',
          from_columns => ['artist_id'], to_table => 'artist',
          to_columns => ['id'], on_update => 'CASCADE', on_delete => 'RESTRICT' },
      ],
    );
    return { tables => \%tables, columns => \%columns, indexes => \%indexes,
             foreign_keys => \%fks };
  }

  # Override view_definition to return a fixed view SQL
  sub view_definition {
    my ($self, $key) = @_;
    return "SELECT id FROM artist" if $key eq 'myview';
    return undef;
  }

  # Override dbh for view_definition (not otherwise used in contract methods)
  sub dbh { $_[0]->{dbh} //= {} }
}

my $gen = DBIO::Generate->new(
  schema_class    => 'TestMySQL::Schema',
  dump_directory  => $tmpdir,
  style           => 'vanilla',
  use_namespaces  => 1,
  generate_pod    => 0,
  quiet           => 1,
);

my $fixture = Test::MySQL::Gen::Fixture->new(dbh => {});

# Test contract method returns
my $keys = $fixture->table_keys;
is_deeply([sort @$keys], [qw/artist cd myview/], 'table_keys returns tables+views');

my $artist_cols = $fixture->table_columns('artist');
is_deeply($artist_cols, [qw/id name/], 'artist column order');

my $cd_cols = $fixture->table_columns('cd');
is_deeply($cd_cols, [qw/id artist_id title/], 'cd column order');

my $artist_cols_info = $fixture->table_columns_info('artist');
ok(exists $artist_cols_info->{id}, 'artist.id in columns_info');
ok(exists $artist_cols_info->{name}, 'artist.name in columns_info');
is($artist_cols_info->{id}{is_auto_increment}, 1, 'artist.id is_auto_increment');
is($artist_cols_info->{name}{is_nullable}, 0, 'artist.name is not nullable');

my $cd_pk = $fixture->table_pk_info('cd');
is_deeply($cd_pk, [qw/id/], 'cd pk');

my $cd_uniq = $fixture->table_uniq_info('cd');
is(scalar(@$cd_uniq), 0, 'cd has no unique constraints (only pk)');

my $artist_uniq = $fixture->table_uniq_info('artist');
is(scalar(@$artist_uniq), 1, 'artist has one unique constraint');
is($artist_uniq->[0][0], 'idx_name', 'artist unique constraint name');
is_deeply($artist_uniq->[0][1], ['name'], 'artist unique constraint columns');

my $cd_fk = $fixture->table_fk_info('cd');
is(scalar(@$cd_fk), 1, 'cd has one FK');
is($cd_fk->[0]{local_columns}[0], 'artist_id', 'cd FK local column');
is($cd_fk->[0]{remote_table}, 'artist', 'cd FK remote table');
is_deeply($cd_fk->[0]{remote_columns}, ['id'], 'cd FK remote columns');
is($cd_fk->[0]{attrs}{on_delete}, 'RESTRICT', 'cd FK on_delete');

my $is_view_artist = $fixture->table_is_view('artist');
is($is_view_artist, 0, 'artist is not a view');

my $is_view_myview = $fixture->table_is_view('myview');
is($is_view_myview, 1, 'myview is a view');

my $view_def = $fixture->view_definition('myview');
like($view_def, qr/SELECT.*FROM.*artist/i, 'myview view_definition');

my @extra_stmts = $fixture->result_class_extra_statements('artist');
# source_info is a plain setter, so engine + collation must be combined
# into ONE statement -- a second call would replace the first
is(scalar @extra_stmts, 1, 'artist has one combined source_info statement');
is_deeply($extra_stmts[0],
  [ source_info => {
      mysql_engine    => 'InnoDB',
      mysql_collation => 'utf8mb4_general_ci',
  } ],
  'source_info combines engine and collation');

# Test DBIO::Generate::dump with the fixture
$gen->dump($fixture);

my $artist_pm = "$tmpdir/TestMySQL/Schema/Result/Artist.pm";
my $cd_pm     = "$tmpdir/TestMySQL/Schema/Result/Cd.pm";
my $view_pm   = "$tmpdir/TestMySQL/Schema/Result/Myview.pm";

ok(-f $artist_pm, 'Artist.pm generated');
ok(-f $cd_pm,     'Cd.pm generated');
ok(-f $view_pm,   'Myview.pm generated');

my $artist_src = do { open my $fh, '<', $artist_pm; local $/; <$fh> };
like($artist_src, qr/table\(["']artist["']\)/,   'Artist uses correct table name');
like($artist_src, qr/has_many/,             'Artist has_many relationship');
like($artist_src, qr/source_info/,          'Artist has source_info');

my $cd_src = do { open my $fh, '<', $cd_pm; local $/; <$fh> };
like($cd_src, qr/table\(["']cd["']\)/,          'Cd uses correct table name');
like($cd_src, qr/belongs_to/,              'Cd belongs_to relationship');
like($cd_src, qr/TestMySQL::Schema::Result::Artist/, 'Cd references Artist class');

my $view_src = do { open my $fh, '<', $view_pm; local $/; <$fh> };
like($view_src, qr/table\(["']myview["']\)/,    'Myview uses correct table name');

done_testing;
