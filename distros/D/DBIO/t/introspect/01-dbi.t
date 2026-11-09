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

  # data_type is the type NAME. DATA_TYPE is the numeric SQL type
  # code (SQL_INTEGER == 4), which is what the generated result class used to
  # get -- add_columns( data_type => 4 ).
  is $info->{id}{data_type}, 'integer', 'data_type is TYPE_NAME, not the numeric code';
  is $info->{name}{data_type}, 'character varying', 'data_type is TYPE_NAME for varchar too';
}

# --- a driver that reports no DATA_TYPE (DBD::SQLite) ---------------------
# DBD::SQLite fills TYPE_NAME and leaves DATA_TYPE undef for every column.
# Keying off DATA_TYPE therefore made every column in the schema 'varchar'.

{
  my $dbh = Fake::Dbh->new(
    driver_name => 'SQLite',
    column_info_rows => [
      { COLUMN_NAME => 'id',   DATA_TYPE => undef, TYPE_NAME => 'INTEGER',
        COLUMN_SIZE => undef, NULLABLE => 1 },
      { COLUMN_NAME => 'name', DATA_TYPE => undef, TYPE_NAME => 'VARCHAR',
        COLUMN_SIZE => 100, NULLABLE => 0 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('artists');

  is $info->{id}{data_type}, 'INTEGER', 'TYPE_NAME used when DATA_TYPE is absent';
  is $info->{name}{data_type}, 'VARCHAR', 'no varchar-for-everything guess';
  is_deeply \@warnings, [], 'a complete TYPE_NAME is not worth warning about';
}

# --- no type information at all -------------------------------------------
# The guess stays -- aborting mid-generation is worse than a generated class
# with one wrong column -- but it is announced, and it names what to fix.

{
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'mystery', DATA_TYPE => undef, TYPE_NAME => undef,
        COLUMN_SIZE => undef, NULLABLE => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('public.puzzles');

  is $info->{mystery}{data_type}, 'varchar', 'still guesses rather than dying';
  is scalar @warnings, 1, 'the guess warns exactly once';
  like $warnings[0], qr/puzzles/,  'warning names the table';
  like $warnings[0], qr/mystery/,  'warning names the column';
  like $warnings[0], qr/varchar/,  'warning names the guess it made';
}

# --- the MySQL TEXT rewrite now reaches data_type -------------------------
# MySQL reports TEXT as varchar(65535). The rewrite existed before, but only
# touched the unused 'type' key, so the generated class never saw it.

{
  my $dbh = Fake::Dbh->new(
    driver_name => 'mysql',
    column_info_rows => [
      { COLUMN_NAME => 'body', DATA_TYPE => 12, TYPE_NAME => 'varchar',
        COLUMN_SIZE => 65535, NULLABLE => 1 },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);
  my $info = $intro->table_columns_info('posts');

  is $info->{body}{data_type}, 'text', 'varchar(65535) reported as text';
}

# --- is_nullable consults the primary key ---------------------------------
# NULLABLE answers "does the column carry a NOT NULL attribute", which is not
# the same question. DBD::SQLite reports NULLABLE=1 for "id INTEGER PRIMARY KEY
# AUTOINCREMENT" (PRAGMA table_info agrees, notnull=0) because in SQLite the PK
# constraint is separate from the attribute -- so the faithful reading produced
# a generated result class whose primary key was declared nullable.

{
  my $dbh = Fake::Dbh->new(
    driver_name => 'SQLite',
    column_info_rows => [
      { COLUMN_NAME => 'id',   TYPE_NAME => 'INTEGER', NULLABLE => 1 },
      { COLUMN_NAME => 'name', TYPE_NAME => 'VARCHAR', NULLABLE => 1 },
      { COLUMN_NAME => 'slug', TYPE_NAME => 'VARCHAR', NULLABLE => 0 },
    ],
    pk_info_rows => [ { COLUMN_NAME => 'id', KEY_SEQ => 1 } ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('artists');

  is $info->{id}{is_nullable}, 0,
    'a pk column the DBD reports as nullable is not nullable';
  is $info->{name}{is_nullable}, 1,
    'a plain nullable column stays nullable';
  is $info->{slug}{is_nullable}, 0,
    'a plain NOT NULL column stays not-nullable';
  is_deeply \@warnings, [],
    'the pk answers the question, so nothing was guessed and nothing warns';
}

{
  # Composite key: every member column is non-nullable, not just the first.
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'artist_id', TYPE_NAME => 'integer', NULLABLE => 1 },
      { COLUMN_NAME => 'cd_id',     TYPE_NAME => 'integer', NULLABLE => 1 },
      { COLUMN_NAME => 'note',      TYPE_NAME => 'text',    NULLABLE => 1 },
    ],
    pk_info_rows => [
      { COLUMN_NAME => 'cd_id',     KEY_SEQ => 2 },
      { COLUMN_NAME => 'artist_id', KEY_SEQ => 1 },
    ],
  );
  my $info = DBIO::Introspect::DBI->new(dbh => $dbh)
    ->table_columns_info('artist_cd');

  is $info->{artist_id}{is_nullable}, 0, 'first composite pk column not nullable';
  is $info->{cd_id}{is_nullable},     0, 'second composite pk column not nullable';
  is $info->{note}{is_nullable},      1, 'non-key column unaffected by the pk';
}

{
  # A table with no primary key at all must not be disturbed by the lookup.
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'a', TYPE_NAME => 'integer', NULLABLE => 1 },
      { COLUMN_NAME => 'b', TYPE_NAME => 'integer', NULLABLE => 0 },
    ],
    pk_info_rows => [],
  );
  my $info = DBIO::Introspect::DBI->new(dbh => $dbh)->table_columns_info('keyless');

  is $info->{a}{is_nullable}, 1, 'keyless table: nullable column nullable';
  is $info->{b}{is_nullable}, 0, 'keyless table: NOT NULL column not nullable';
}

# --- NULLABLE = 2 means "unknown", and unknown rounds permissive ----------
# It used to fall through to not-null, which is the one answer that can reject
# an INSERT the database would have accepted. undef (the DBD reports no
# NULLABLE at all) is the same epistemic state and now gets the same answer --
# it used to be the opposite one -- and either way it says so.

{
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'unknown_flag', TYPE_NAME => 'integer', NULLABLE => 2 },
      { COLUMN_NAME => 'absent_flag',  TYPE_NAME => 'integer' },
    ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('public.mystery');

  is $info->{unknown_flag}{is_nullable}, 1,
    'NULLABLE=2 (unknown) assumes nullable, not NOT NULL';
  is $info->{absent_flag}{is_nullable}, 1,
    'an absent NULLABLE is the same unknown and gets the same answer';

  is scalar @warnings, 2, 'each unknown column says so exactly once';
  like $warnings[0], qr/mystery/,      'warning names the table';
  like $warnings[0], qr/unknown_flag/, 'warning names the column';
  like $warnings[0], qr/is_nullable/,  'warning names what it assumed';
  like $warnings[1], qr/absent_flag/,  'the absent case warns too';
}

{
  # The primary key settles the question before the guess is reached, so an
  # unknown NULLABLE on a pk column is neither nullable nor a warning.
  my $dbh = Fake::Dbh->new(
    column_info_rows => [
      { COLUMN_NAME => 'id', TYPE_NAME => 'integer', NULLABLE => 2 },
    ],
    pk_info_rows => [ { COLUMN_NAME => 'id', KEY_SEQ => 1 } ],
  );
  my $intro = DBIO::Introspect::DBI->new(dbh => $dbh);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $info = $intro->table_columns_info('things');

  is $info->{id}{is_nullable}, 0, 'pk beats an unknown NULLABLE';
  is_deeply \@warnings, [], 'and nothing was guessed, so nothing warns';
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

# --- the DBI $type argument (Codeberg #15) ---
#
# $type is a comma-separated STRING per the DBI spec. Passing \@types instead
# looks harmless -- nothing dies, no driver complains -- but every DBD
# stringifies the ref to "ARRAY(0x...)" and then quietly matches zero rows,
# which is how dbiogen came to print "Done." without writing a file.
#
# So asserting the literal string would be too weak: it would not say why the
# arrayref was wrong. Instead the captured argument is run through the actual
# filter logic of the shipped drivers. These helpers mirror them line for line.

# DBD::MariaDB / DBD::mysql: $want_tables = ($type =~ m/table/i)
sub mariadb_wants {
  my ($type) = @_;
  return (scalar($type =~ m/table/i), scalar($type =~ m/view/i));
}

# DBD::SQLite (and DBD::Oracle): trim, split on /\s*,\s*/, quote every element
# that is not quoted yet, and uppercase the resulting IN-list.
sub sqlite_type_list {
  my ($type) = @_;
  $type =~ s/^\s+//;
  $type =~ s/\s+$//;
  my @list = split /\s*,\s*/, $type;
  for my $t (@list) { $t = "'$t'" unless $t =~ /^'.*'$/ }
  return uc join(', ', @list);
}

# DBD::Pg: split on ',' *without* trimming, then quote anything not already
# quoted -- so a stray space would yield ' VIEW' and match no row at all.
sub pg_type_list {
  my ($type) = @_;
  return join(', ', map { m/^'/ ? $_ : "'$_'" } grep { length } split(/,/, $type));
}

{
  my $dbh = Fake::Dbh->new(table_info_rows => [ { TABLE_NAME => 'foo' } ]);
  DBIO::Introspect::DBI->new(dbh => $dbh)->table_keys;

  my ($call) = grep { $_->[0] eq 'table_info' } @{ $dbh->{calls} };
  my $type = $call->[4];  # (table_info => $catalog, $schema, $table, $type)

  ok !ref $type, 'table_keys hands DBI a plain string as $type, not a ref'
    or diag 'got a ' . ref($type) . ' ref';

  my ($want_tables, $want_views) = mariadb_wants($type);
  ok $want_tables, 'DBD::MariaDB reads it as "caller wants tables"';
  ok $want_views,  'DBD::MariaDB reads it as "caller wants views"';

  is sqlite_type_list($type), q{'TABLE', 'VIEW'},
    'DBD::SQLite turns it into an IN-list selecting tables and views';
  is pg_type_list($type), q{'TABLE', 'VIEW'},
    'DBD::Pg (which does not trim) turns it into the same IN-list';
}

{
  # Negative control: what the pre-fix arrayref actually looked like to a DBD.
  my $stringified_ref = '' . ['TABLE', 'VIEW'];

  my ($want_tables, $want_views) = mariadb_wants($stringified_ref);
  ok !$want_tables, 'an arrayref leaves DBD::MariaDB wanting no tables';
  ok !$want_views,  'an arrayref leaves DBD::MariaDB wanting no views';
  unlike sqlite_type_list($stringified_ref), qr/'TABLE'/,
    'an arrayref leaves DBD::SQLite with an IN-list that no table can match';
}

{
  my $dbh = Fake::Dbh->new(table_info_rows => [ { TABLE_NAME => 'v_foo', TABLE_TYPE => 'VIEW' } ]);
  DBIO::Introspect::DBI->new(dbh => $dbh)->table_is_view('v_foo');

  my ($call) = grep { $_->[0] eq 'table_info' } @{ $dbh->{calls} };
  my $type = $call->[4];

  ok !ref $type, 'table_is_view hands DBI a plain string as $type, not a ref'
    or diag 'got a ' . ref($type) . ' ref';

  my ($want_tables, $want_views) = mariadb_wants($type);
  ok $want_views,  'DBD::MariaDB reads it as "caller wants views"';
  ok !$want_tables, 'and not as "caller wants tables" -- base tables must not match';
  is pg_type_list($type), q{'VIEW'},
    'DBD::Pg turns it into a VIEW-only IN-list';
}

done_testing;
