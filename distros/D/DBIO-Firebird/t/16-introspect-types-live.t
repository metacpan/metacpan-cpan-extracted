use strict;
use warnings;
use Test::More;

# Live type-map test: one column per Firebird type, asserted against what
# DBIO::Firebird::Introspect reports, then a round trip -- a CREATE TABLE
# rendered by Diff::Table from the introspected model must be accepted by the
# server and introspect back to the same columns. The offline fixtures cannot
# catch a wrong rdb$field_type map. Skipped unless a DSN is provided.
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run live type tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Firebird::Introspect;
use DBIO::Firebird::Diff::Table;

my $dbh = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, AutoCommit => 1, PrintError => 0, ib_dialect => 3 })
  or plan skip_all => 'Cannot connect: ' . DBI->errstr;

my $ver = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
my ($major) = ($ver // '0') =~ /^(\d+)/;

# column => [ DDL, data_type, size ]
my @cols = (
  [ c_int    => 'INTEGER',                     'integer',          undef ],
  [ c_small  => 'SMALLINT',                    'smallint',         undef ],
  [ c_big    => 'BIGINT',                      'bigint',           undef ],
  [ c_char   => 'CHAR(3)',                     'char',             3 ],
  [ c_vchar  => 'VARCHAR(20)',                 'varchar',          20 ],
  [ c_num92  => 'NUMERIC(9,2)',                'numeric',          [9, 2] ],
  [ c_num41  => 'NUMERIC(4,1)',                'numeric',          [4, 1] ],
  [ c_dec184 => 'DECIMAL(18,4)',               'decimal',          [18, 4] ],
  [ c_float  => 'FLOAT',                       'float',            undef ],
  [ c_dbl    => 'DOUBLE PRECISION',            'double precision', undef ],
  [ c_time   => 'TIME',                        'time',             undef ],
  [ c_ts     => 'TIMESTAMP',                   'timestamp',        undef ],
  [ c_date   => 'DATE',                        'date',             undef ],
  [ c_btext  => 'BLOB SUB_TYPE TEXT',          'blob sub_type text', undef ],
  [ c_blob   => 'BLOB',                        'blob',             undef ],
  [ c_dflt   => q{VARCHAR(20) DEFAULT 'foo bar'}, 'varchar',       20 ],
  [ c_nn     => 'INTEGER NOT NULL',            'integer',          undef ],
  # both at once: the round trip below has to render them in the one order
  # the server parses, DEFAULT before NOT NULL (karr k32)
  [ c_dnn    => 'INTEGER DEFAULT 7 NOT NULL',  'integer',          undef ],
);
if ($major >= 3) {
  push @cols, [ c_bool => 'BOOLEAN', 'boolean', undef ];
}
if ($major >= 4) {
  push @cols,
    [ c_num302 => 'NUMERIC(30,2)',             'numeric',          [30, 2] ],
    [ c_i128   => 'INT128',                    'int128',           undef ],
    [ c_dfl16  => 'DECFLOAT(16)',              'decfloat',         16 ],
    [ c_timetz => 'TIME WITH TIME ZONE',       'time with time zone', undef ],
    [ c_tstz   => 'TIMESTAMP WITH TIME ZONE',  'timestamp with time zone', undef ],
    [ c_vbin   => 'VARBINARY(8)',              'varbinary',        8 ],
    [ c_bin    => 'BINARY(4)',                 'binary',           4 ];
}

my @tables = qw(DBIO_T31_RT DBIO_T31_TYPES);
my $cleanup = sub { for my $t (@tables) { eval { $dbh->do("DROP TABLE $t") } } };
$cleanup->();

$dbh->do('CREATE TABLE DBIO_T31_TYPES (' . join(', ', map {"$_->[0] $_->[1]"} @cols) . ')');

my $model = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;
my %got = map { $_->{column_name} => $_ } @{ $model->{columns}{DBIO_T31_TYPES} };

for my $c (@cols) {
  my ($name, $ddl, $type, $size) = @$c;
  my $g = $got{uc $name} or do { fail("$name ($ddl) introspected"); next };
  is($g->{data_type}, $type, "$ddl -> data_type $type");
  is_deeply($g->{size}, $size, "$ddl -> size " . (ref $size ? "[@$size]" : $size // 'undef'));
}
is($got{C_DFLT}{default_value}, q{'foo bar'}, 'quoted default with a space is kept whole');
is($got{C_NN}{not_null}, 1, 'NOT NULL carried');

# --- round trip: Diff::Table CREATE TABLE -> server -> introspect same -------
my $op = DBIO::Firebird::Diff::Table->new(
  action       => 'create',
  table_name   => 'DBIO_T31_RT',
  table_info   => $model->{tables}{DBIO_T31_TYPES},
  columns      => $model->{columns}{DBIO_T31_TYPES},
  foreign_keys => [],
);
my $sql = $op->as_sql;
my $ok = eval { $dbh->do($sql); 1 };
ok($ok, 'server accepts CREATE TABLE rendered from the introspected model')
  or diag("$@\n$sql");

if ($ok) {
  my $m2 = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;
  my @keys = qw(column_name data_type size not_null default_value);
  my $strip = sub { [ map { my $c = $_; +{ map { $_ => $c->{$_} } @keys } } @{ $_[0] } ] };
  is_deeply($strip->($m2->{columns}{DBIO_T31_RT}), $strip->($model->{columns}{DBIO_T31_TYPES}),
    'round trip introspects back to the same columns');
}

$cleanup->();
$dbh->disconnect;
done_testing;
