use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

BEGIN {
  eval { require DBIO::Generate; 1 }
    or plan skip_all => 'DBIO::Generate not installed';
}

use DBIO::Oracle::Introspect;

# Offline contract test: DBIO::Oracle::Introspect must satisfy the
# DBIO::Generate normalized contract from DBIO::Introspect::Base.
# No live database -- a fixture subclass supplies an in-memory model
# matching the shape that the Introspect::* sub-modules produce.

my $tmpdir = tempdir(CLEANUP => 1);

# --- Mock dbh, only used for view_definition's all_views lookup ---
{
  package Mock::Dbh;
  sub new { bless { %{ $_[1] // {} } }, $_[0] }
  sub selectrow_array {
    my ($self, $sql, $attr, @bind) = @_;
    if ($sql =~ /all_views/i) {
      my $view = $bind[1];
      return 'SELECT id, name FROM artist' if $view eq 'MYVIEW';
    }
    return;
  }
}

{
  package Test::Oracle::Fixture;
  use base 'DBIO::Oracle::Introspect';

  sub _build_model {
    my %tables = (
      ARTIST => { table_name => 'ARTIST', kind => 'table', schema => 'TESTUSER' },
      CD     => { table_name => 'CD',     kind => 'table', schema => 'TESTUSER' },
      MYVIEW => { table_name => 'MYVIEW', kind => 'view',  schema => 'TESTUSER' },
    );
    my %columns = (
      ARTIST => [
        { column_name => 'ID',   data_type => 'integer', not_null => 1,
          is_auto_increment => 1, sequence => 'testuser.artist_seq' },
        { column_name => 'NAME', data_type => 'varchar', size => 128, not_null => 1,
          default_value => 'Unknown' },
      ],
      CD => [
        { column_name => 'ID',        data_type => 'integer', not_null => 1 },
        { column_name => 'ARTIST_ID', data_type => 'integer', not_null => 1 },
        { column_name => 'TITLE',     data_type => 'varchar', size => 256, not_null => 1 },
      ],
      MYVIEW => [
        { column_name => 'ID',   data_type => 'integer', not_null => 1 },
        { column_name => 'NAME', data_type => 'varchar', size => 128, not_null => 0 },
      ],
    );
    my %primary_keys = (
      ARTIST => ['ID'],
      CD     => ['ID'],
      MYVIEW => [],
    );
    my %unique_constraints = (
      ARTIST => [ [ 'ARTIST_NAME_UK' => ['NAME'] ] ],
      CD     => [],
      MYVIEW => [],
    );
    my %foreign_keys = (
      ARTIST => [],
      CD => [
        { fk_name => 'CD_ARTIST_FK', from_columns => ['ARTIST_ID'],
          to_table => 'ARTIST', to_columns => ['ID'],
          on_delete => 'CASCADE', on_update => 'NO ACTION', is_deferrable => 1 },
      ],
      MYVIEW => [],
    );
    return {
      tables             => \%tables,
      columns            => \%columns,
      indexes            => {},
      foreign_keys       => \%foreign_keys,
      primary_keys       => \%primary_keys,
      unique_constraints => \%unique_constraints,
    };
  }
}

# Test 1: the real class advertises every contract method
my @contract_methods = qw(
  table_keys table_columns table_columns_info table_pk_info
  table_uniq_info table_fk_info table_is_view view_definition
);
for my $method (@contract_methods) {
  ok(DBIO::Oracle::Introspect->can($method),
    "DBIO::Oracle::Introspect has $method");
}

my $intro = Test::Oracle::Fixture->new(
  dbh    => Mock::Dbh->new,
  schema => 'TESTUSER',
);

# Test 2: contract method returns
is_deeply($intro->table_keys, [qw/ARTIST CD MYVIEW/], 'table_keys sorted');

is_deeply($intro->table_columns('ARTIST'), [qw/ID NAME/], 'artist column order');
is_deeply($intro->table_columns('CD'), [qw/ID ARTIST_ID TITLE/], 'cd column order');

my $artist_info = $intro->table_columns_info('ARTIST');
is($artist_info->{ID}{data_type}, 'integer', 'artist.id data_type');
is($artist_info->{ID}{is_nullable}, 0, 'artist.id not nullable');
is($artist_info->{ID}{is_auto_increment}, 1, 'artist.id auto_increment');
is($artist_info->{ID}{sequence}, 'testuser.artist_seq', 'artist.id sequence');
is($artist_info->{NAME}{size}, 128, 'artist.name size');
is($artist_info->{NAME}{is_nullable}, 0, 'artist.name not nullable');
is($artist_info->{NAME}{default_value}, 'Unknown', 'artist.name default');
ok(!exists $artist_info->{NAME}{is_auto_increment}, 'artist.name no auto_increment key');

is_deeply($intro->table_pk_info('ARTIST'), ['ID'], 'artist pk');
is_deeply($intro->table_pk_info('CD'), ['ID'], 'cd pk');
is_deeply($intro->table_pk_info('MYVIEW'), [], 'view has no pk');

my $artist_uniq = $intro->table_uniq_info('ARTIST');
is(scalar @$artist_uniq, 1, 'artist one unique constraint');
is($artist_uniq->[0][0], 'ARTIST_NAME_UK', 'unique constraint name');
is_deeply($artist_uniq->[0][1], ['NAME'], 'unique constraint columns');
is_deeply($intro->table_uniq_info('CD'), [], 'cd no unique constraints');

my $cd_fk = $intro->table_fk_info('CD');
is(scalar @$cd_fk, 1, 'cd one FK');
is_deeply($cd_fk->[0]{local_columns}, ['ARTIST_ID'], 'fk local columns');
is($cd_fk->[0]{remote_table}, 'ARTIST', 'fk remote table');
is_deeply($cd_fk->[0]{remote_columns}, ['ID'], 'fk remote columns');
is($cd_fk->[0]{attrs}{on_delete}, 'CASCADE', 'fk on_delete');
is($cd_fk->[0]{attrs}{is_deferrable}, 1, 'fk deferrable');
is_deeply($intro->table_fk_info('ARTIST'), [], 'artist no FKs');

is($intro->table_is_view('ARTIST'), 0, 'artist not a view');
is($intro->table_is_view('MYVIEW'), 1, 'myview is a view');

is($intro->view_definition('ARTIST'), undef, 'no view_definition for table');
like($intro->view_definition('MYVIEW'), qr/SELECT.*FROM\s+artist/i,
  'myview view_definition');

# Test 3: DBIO::Generate->dump consumes the contract end to end
my $gen = DBIO::Generate->new(
  schema_class   => 'TestOracle::Schema',
  dump_directory => $tmpdir,
  style          => 'vanilla',
  use_namespaces => 1,
  generate_pod   => 0,
  quiet          => 1,
);
$gen->dump($intro);

for my $name (qw/Artist Cd Myview/) {
  ok(-f "$tmpdir/TestOracle/Schema/Result/$name.pm", "$name.pm generated");
}

done_testing;
