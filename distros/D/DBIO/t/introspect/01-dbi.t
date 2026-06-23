use strict;
use warnings;
use Test::More;
use lib 't/lib';

use DBIO::Introspect::DBI;

# --- Fake DBI handles (no real database, per core testing rules) ---

{
  package Fake::Sth;
  sub new { my ($class, %args) = @_; bless { rows => $args{rows} || [], i => 0 }, $class }
  sub fetchrow_hashref { my $self = shift; $self->{rows}[$self->{i}++] }
  sub fetch            { my $self = shift; $self->{rows}[$self->{i}++] }
  sub execute { 1 }
  sub finish  { 1 }
}

{
  package Fake::Dbh;
  sub new {
    my ($class, %args) = @_;
    my $self = bless { calls => [], %args }, $class;
    $self->{Driver} = { Name => $args{driver_name} || 'Pg' };
    return $self;
  }
  sub _rows { my ($self, $key) = @_; Fake::Sth->new(rows => $self->{$key} || []) }
  sub table_info       { my $self = shift; push @{$self->{calls}}, [table_info => @_]; $self->_rows('table_info_rows') }
  sub column_info      { my $self = shift; push @{$self->{calls}}, [column_info => @_]; $self->_rows('column_info_rows') }
  sub primary_key_info { my $self = shift; push @{$self->{calls}}, [primary_key_info => @_]; $self->_rows('pk_info_rows') }
  sub foreign_key_info { my $self = shift; push @{$self->{calls}}, [foreign_key_info => @_]; $self->_rows('fk_info_rows') }
  sub statistics_info  { my $self = shift; push @{$self->{calls}}, [statistics_info => @_]; $self->_rows('stats_info_rows') }
  sub prepare          { my $self = shift; push @{$self->{calls}}, [prepare => @_]; $self->_rows('prepare_rows') }
}

# --- dbms_name auto-detection ---

{
  my $intro = DBIO::Introspect::DBI->new(dbh => Fake::Dbh->new(driver_name => 'SQLite'));
  is $intro->dbms_name, 'SQLite', 'dbms_name auto-detected from dbh Driver';
}

# --- table_keys ---

{
  my $dbh = Fake::Dbh->new(
    table_info_rows => [
      { TABLE_SCHEM => 'public', TABLE_NAME => 'artists' },
      { TABLE_SCHEM => 'public', TABLE_NAME => 'cds' },
      { TABLE_SCHEM => '',       TABLE_NAME => 'bare' },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  is_deeply $intro->table_keys, [qw/public.artists public.cds bare/],
    'table_keys returns schema-qualified keys';
}

# --- table_columns_info ---

{
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'id', DATA_TYPE => 4, TYPE_NAME => 'integer',
        COLUMN_SIZE => undef, NULLABLE => 0, COLUMN_DEF => q{nextval('artists_id_seq')} },
      { COLUMN_NAME => 'name', DATA_TYPE => 12, TYPE_NAME => 'character varying',
        COLUMN_SIZE => 100, NULLABLE => 1, COLUMN_DEF => q{'unknown'} },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('public.artists');

  is_deeply [sort keys %$info], [qw/id name/], 'both columns present';
  ok !$info->{id}{is_nullable},        'pk column not nullable';
  ok $info->{id}{is_auto_increment},   'nextval default detected as auto_increment';
  ok $info->{name}{is_nullable},       'name column nullable';
  is $info->{name}{size}, 100,         'size carried through';
  is $info->{name}{default_value}, 'unknown', 'quoted default stripped';
  is_deeply \@warnings, [], 'no undef warnings on column with undef size';
}

# --- table_pk_info (composite, ordered by KEY_SEQ) ---

{
  my $dbh = Fake::Dbh->new(
    pk_info_rows => [
      { COLUMN_NAME => 'cd_id',     KEY_SEQ => 2 },
      { COLUMN_NAME => 'artist_id', KEY_SEQ => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  is_deeply $intro->table_pk_info('artist_cd'), [qw/artist_id cd_id/],
    'composite pk ordered by KEY_SEQ';
}

# --- table_fk_info (hashref rows, composite fk grouped by FK_NAME) ---

{
  my $dbh = Fake::Dbh->new(
    fk_info_rows => [
      { FK_NAME => 'fk_artist', FK_COLUMN_NAME => 'artist_id',
        UK_TABLE_NAME => 'artists', UK_TABLE_SCHEM => 'public',
        UK_COLUMN_NAME => 'id', ORDINAL_POSITION => 1 },
      { FK_NAME => 'fk_pair', FK_COLUMN_NAME => 'b',
        UK_TABLE_NAME => 'pairs', UK_TABLE_SCHEM => 'public',
        UK_COLUMN_NAME => 'pb', ORDINAL_POSITION => 2 },
      { FK_NAME => 'fk_pair', FK_COLUMN_NAME => 'a',
        UK_TABLE_NAME => 'pairs', UK_TABLE_SCHEM => 'public',
        UK_COLUMN_NAME => 'pa', ORDINAL_POSITION => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  my $fks = $intro->table_fk_info('public.cds');

  is scalar @$fks, 2, 'rows grouped into two fks';
  my ($artist) = grep { $_->{remote_table} eq 'artists' } @$fks;
  my ($pair)   = grep { $_->{remote_table} eq 'pairs' } @$fks;

  is_deeply $artist->{local_columns},  [qw/artist_id/], 'single-col fk local columns';
  is_deeply $artist->{remote_columns}, [qw/id/],        'single-col fk remote columns';
  is $artist->{remote_schema}, 'public',                'remote schema carried';

  is_deeply $pair->{local_columns},  [qw/a b/],   'composite fk ordered by ORDINAL_POSITION';
  is_deeply $pair->{remote_columns}, [qw/pa pb/], 'composite fk remote columns aligned';
}

# --- table_fk_info with ODBC-style column names ---

{
  my $dbh = Fake::Dbh->new(
    fk_info_rows => [
      { FK_NAME => 'fk_artist', FKCOLUMN_NAME => 'artist_id',
        PKTABLE_NAME => 'artists', PKTABLE_SCHEM => undef,
        PKCOLUMN_NAME => 'id', KEY_SEQ => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  my $fks = $intro->table_fk_info('cds');

  is scalar @$fks, 1, 'odbc-style row produces one fk';
  is $fks->[0]{remote_table}, 'artists', 'odbc remote table';
  is_deeply $fks->[0]{local_columns},  [qw/artist_id/], 'odbc local columns';
  is_deeply $fks->[0]{remote_columns}, [qw/id/],        'odbc remote columns';
}

# --- table_uniq_info (per-index columns, ordered, non-unique skipped) ---

{
  my $dbh = Fake::Dbh->new(
    stats_info_rows => [
      { INDEX_NAME => 'uniq_email', NON_UNIQUE => 0, COLUMN_NAME => 'email', ORDINAL_POSITION => 1 },
      { INDEX_NAME => 'uniq_pair',  NON_UNIQUE => 0, COLUMN_NAME => 'b', ORDINAL_POSITION => 2 },
      { INDEX_NAME => 'uniq_pair',  NON_UNIQUE => 0, COLUMN_NAME => 'a', ORDINAL_POSITION => 1 },
      { INDEX_NAME => 'idx_plain',  NON_UNIQUE => 1, COLUMN_NAME => 'c', ORDINAL_POSITION => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  my $uniqs = $intro->table_uniq_info('users');

  is_deeply $uniqs,
    [ [ uniq_email => [qw/email/] ], [ uniq_pair => [qw/a b/] ] ],
    'uniq constraints use only their own columns, ordered';
}

# --- table_is_view ---

{
  my $dbh = Fake::Dbh->new(table_info_rows => [ { TABLE_NAME => 'v_foo', TABLE_TYPE => 'VIEW' } ]);
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  ok $intro->table_is_view('v_foo'), 'view detected';
}

{
  my $dbh = Fake::Dbh->new(table_info_rows => []);
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  ok !$intro->table_is_view('plain'), 'base table is not a view';
}

done_testing;
