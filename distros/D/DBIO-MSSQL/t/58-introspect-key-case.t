use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Introspect::Tables;
use DBIO::MSSQL::Introspect::Columns;
use DBIO::MSSQL::Introspect::Indexes;
use DBIO::MSSQL::Introspect::ForeignKeys;

# Offline test that pins the key-casing form of the introspect queries
# (karr k32).
#
# INFORMATION_SCHEMA reports its columns UPPERCASE (TABLE_NAME, COLUMN_NAME,
# ...). Whether the row hash carries the upper- or lowercase name is decided
# by the transport / FetchHashKeyName, not by the server -- so the introspect
# modules must not rely on either. The chosen form: every column is aliased
# explicitly and in lower case, which echoes the alias case verbatim into the
# result metadata on every transport.
#
# The mock dbh below simulates the worst case: an unaliased column comes back
# UPPERCASE. If a query ever drops an alias, the module's lowercase
# $row->{...} read turns undef and the model comes out wrong -- the test
# fails. That is the pin: the next query cannot silently fall back to relying
# on the transport.

# --- mock dbh / sth -------------------------------------------------------

# Result column names as the server would report them: an alias is echoed
# verbatim, an unaliased column comes back UPPERCASE (worst case).
sub _result_columns {
  my ($sql) = @_;
  my ($list) = $sql =~ /SELECT\s+(.*?)\s+FROM\s/is
    or die "cannot parse SELECT list from: $sql";
  my @cols;
  for my $item (split /\s*,\s*/, $list) {
    if ($item =~ /\b(\w+)\s+AS\s+(\w+)\s*$/i) {
      push @cols, $2;            # alias echoed verbatim
    } else {
      $item =~ /(\w+)\s*$/ or die "cannot parse column: $item";
      push @cols, uc $1;         # unaliased: worst case UPPERCASE
    }
  }
  return @cols;
}

{
  package MockSTH;
  sub new {
    my ($class, $sql, $rows) = @_;
    my @cols = main::_result_columns($sql);
    return bless { cols => \@cols, rows => $rows, idx => 0 }, $class;
  }
  sub execute { my ($self) = @_; $self->{idx} = 0; 1 }
  sub fetchrow_hashref {
    my ($self) = @_;
    my $row = $self->{rows}[ $self->{idx}++ ] or return undef;
    my %h;
    @h{ @{ $self->{cols} } } = @$row;
    return \%h;
  }
}

{
  package MockDBH;
  sub new {
    my ($class, $queries) = @_;
    return bless { queries => $queries }, $class;
  }
  sub prepare {
    my ($self, $sql) = @_;
    for my $pair (@{ $self->{queries} }) {
      my ($pattern, $rows) = @$pair;
      return MockSTH->new($sql, $rows) if $sql =~ $pattern;
    }
    die "unexpected SQL: $sql";
  }
}

# --- test data (positional, in SELECT-list order) --------------------------

my @TABLES_ROWS = (
  [ 'artist',      'BASE TABLE' ],
  [ 'cd',          'BASE TABLE' ],
  [ 'artist_list', 'VIEW' ],
);

my @COLUMNS_ROWS = (
  [ 'artist', 'artistid', 'int',      'NO',  undef,       1, undef ],
  [ 'artist', 'name',     'nvarchar', 'NO',  "'Unknown'", 2, 128 ],
  [ 'cd',     'cdid',     'int',      'NO',  undef,       1, undef ],
  [ 'cd',     'artistid', 'int',      'NO',  undef,       2, undef ],
  [ 'cd',     'title',    'nvarchar', 'YES', undef,       3, 256 ],
  [ 'artist_list', 'artistid', 'int', 'NO', undef, 1, undef ],
);

my @PK_ROWS = (
  [ 'artist', 'artistid', 1, 'PK_artist' ],
  [ 'cd',     'cdid',     1, 'PK_cd' ],
);

my @IDENTITY_ROWS = (
  [ 'artist', 'artistid' ],
  [ 'cd',     'cdid' ],
);

my @DEFAULT_ROWS = (
  [ 'artist', 'name', 'DF_artist_name' ],
);

my @INDEX_ROWS = (
  [ 'uq_artist_name', 'artist', 1, 1, 2, 'NONCLUSTERED', 0, undef, 'name', 1 ],
  [ 'ix_artist_name', 'artist', 0, 0, 2, 'NONCLUSTERED', 1, '([name] IS NOT NULL)', 'name', 1 ],
);

my @FK_ROWS = (
  [ 'FK_cd_artist', 'cd', 'artist', 'dbo', 'artistid', 'artistid', 'CASCADE', 'NO ACTION' ],
);

my $dbh = MockDBH->new([
  [ qr/sys\.default_constraints/, \@DEFAULT_ROWS ],
  [ qr/sys\.indexes/,              \@INDEX_ROWS ],
  [ qr/REFERENTIAL_CONSTRAINTS/,   \@FK_ROWS ],
  [ qr/is_identity/,               \@IDENTITY_ROWS ],
  [ qr/PRIMARY KEY/,               \@PK_ROWS ],
  [ qr/character_maximum_length/,   \@COLUMNS_ROWS ],
  [ qr/INFORMATION_SCHEMA\.TABLES/,\@TABLES_ROWS ],
]);

# --- expected models -------------------------------------------------------

my $expected_tables = {
  artist      => { table_name => 'artist',      kind => 'table', schema => 'dbo' },
  cd          => { table_name => 'cd',          kind => 'table', schema => 'dbo' },
  artist_list => { table_name => 'artist_list', kind => 'view',  schema => 'dbo' },
};

my $expected_columns = {
  artist => [
    { column_name => 'artistid', data_type => 'int', not_null => 1,
      default_value => undef, is_pk => 1, pk_position => 1,
      is_identity => 1, is_auto_increment => 1, size => undef,
      pk_constraint_name => 'PK_artist' },
    { column_name => 'name', data_type => 'nvarchar', not_null => 1,
      default_value => "'Unknown'", is_pk => 0, pk_position => 0,
      is_identity => 0, is_auto_increment => 0, size => 128,
      default_constraint_name => 'DF_artist_name' },
  ],
  cd => [
    { column_name => 'cdid', data_type => 'int', not_null => 1,
      default_value => undef, is_pk => 1, pk_position => 1,
      is_identity => 1, is_auto_increment => 1, size => undef,
      pk_constraint_name => 'PK_cd' },
    { column_name => 'artistid', data_type => 'int', not_null => 1,
      default_value => undef, is_pk => 0, pk_position => 0,
      is_identity => 0, is_auto_increment => 0, size => undef },
    { column_name => 'title', data_type => 'nvarchar', not_null => 0,
      default_value => undef, is_pk => 0, pk_position => 0,
      is_identity => 0, is_auto_increment => 0, size => 256 },
  ],
  artist_list => [
    { column_name => 'artistid', data_type => 'int', not_null => 1,
      default_value => undef, is_pk => 0, pk_position => 0,
      is_identity => 0, is_auto_increment => 0, size => undef },
  ],
};

my $expected_indexes = {
  artist => {
    uq_artist_name => { index_name => 'uq_artist_name', columns => ['name'],
                        is_unique => 1, is_unique_constraint => 1, kind => 'nonclustered', filter => undef },
    ix_artist_name => { index_name => 'ix_artist_name', columns => ['name'],
                        is_unique => 0, is_unique_constraint => 0, kind => 'nonclustered', filter => '([name] IS NOT NULL)' },
  },
};

my $expected_fks = {
  cd => [
    { constraint_name => 'FK_cd_artist', from_table => 'cd',
      from_columns => ['artistid'], to_table => 'artist', to_schema => 'dbo',
      to_columns => ['artistid'], on_delete => 'CASCADE',
      on_update => 'NO ACTION', is_deferrable => 1 },
  ],
};

# --- run the modules against the worst-case mock ---------------------------

my $tables = DBIO::MSSQL::Introspect::Tables->fetch($dbh, 'dbo');
is_deeply($tables, $expected_tables, 'Tables: model built from UPPERCASE result metadata');

my $columns = DBIO::MSSQL::Introspect::Columns->fetch($dbh, 'dbo', $tables);
is_deeply($columns, $expected_columns, 'Columns: model built from UPPERCASE result metadata');

my $indexes = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, 'dbo', $tables);
is_deeply($indexes, $expected_indexes, 'Indexes: model built from UPPERCASE result metadata');

my $fks = DBIO::MSSQL::Introspect::ForeignKeys->fetch($dbh, 'dbo', $tables);
is_deeply($fks, $expected_fks, 'ForeignKeys: model built from UPPERCASE result metadata');

done_testing;
