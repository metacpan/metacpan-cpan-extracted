use strict;
use warnings;
use Test::More;

# LIVE half of karr k50 / k52 (karr k25): a schema whose Result declares a
# FULLTEXT and a SPATIAL index through mysql_index deploys against a real
# server, and the server has the indexes it was asked for.
#
# WHY IT MATTERS. `using` used to be rendered as a trailing USING clause
# whatever its value, and CREATE INDEX ... USING FULLTEXT is not SQL any MySQL
# or MariaDB server accepts: FULLTEXT and SPATIAL are index classes, written in
# front of INDEX. A documented option produced a statement that failed at
# deploy time. t/31 pins the corrected text of the statements, t/40 the same
# for the migration diff; neither sends anything to a server. Whether a server
# takes the statements, builds the index class that was declared and answers
# through it is what this file shows.
#
# What this file claims, for one table with a BTREE, a FULLTEXT and two
# SPATIAL indexes (over a POINT and over a GEOMETRY column):
#   1. DBIO::MySQL::Deploy->install runs install_ddl against the server
#      without an error;
#   2. the server lists every index with the type that was declared, over the
#      column that was declared, and the two geometry columns with the type
#      the Result gave them;
#   3. they work: MATCH ... AGAINST finds its row -- which the server refuses
#      outright without a FULLTEXT index over that column -- and MBRContains
#      finds its row over each geometry column. All of it is literal SQL
#      through the ResultSet: there is no feature layer for either;
#   4. the diff knows them: after the deploy a diff of the schema against the
#      database has nothing to say about this table; with the FULLTEXT and the
#      SPATIAL indexes dropped by hand it proposes CREATE FULLTEXT INDEX and
#      CREATE SPATIAL INDEX, and applying that puts back indexes of those
#      classes;
#   5. the refusals of t/31 are the server's too: UNIQUE together with
#      FULLTEXT or SPATIAL is a syntax error on the server.
#
# NOT claimed: that the optimizer USES a spatial index. On MySQL 8 it does not
# for a column without an SRID attribute, and says so in a warning when the
# index is created; the driver renders no SRID. What the server said is noted.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Creates and drops a table of its own. The diff deploys the schema into a
# temporary database (CREATE DATABASE), which it drops again.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::DDL;
use DBIO::MySQL::Deploy;

my $T = "dbio_k25_place_$$";

{
  package K25Live::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package K25Live::Schema::Result::Place;
  use DBIO 'Core', -mysql;

  __PACKAGE__->table($T);
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
    body => { data_type => 'text' },
    loc  => { data_type => 'point' },      # NOT NULL, as a SPATIAL index demands
    area => { data_type => 'geometry' },
  );
  __PACKAGE__->set_primary_key('id');

  # Named so that the SPATIAL ones are created last: what the server says
  # about the last statement is read back below.
  __PACKAGE__->mysql_index(idx_k25_a_name => { using => 'BTREE',    columns => ['name'] });
  __PACKAGE__->mysql_index(idx_k25_b_body => { using => 'FULLTEXT', columns => ['body'] });
  __PACKAGE__->mysql_index(idx_k25_c_loc  => { using => 'SPATIAL',  columns => ['loc'] });
  __PACKAGE__->mysql_index(idx_k25_d_area => { using => 'SPATIAL',  columns => ['area'] });
}
K25Live::Schema->register_class(Place => 'K25Live::Schema::Result::Place');

# What was declared: index => [ type, column ].
my %DECLARED = (
  PRIMARY        => [ 'BTREE',    'id'   ],
  idx_k25_a_name => [ 'BTREE',    'name' ],
  idx_k25_b_body => [ 'FULLTEXT', 'body' ],
  idx_k25_c_loc  => [ 'SPATIAL',  'loc'  ],
  idx_k25_d_area => [ 'SPATIAL',  'area' ],
);

# Another session: reads what the server has, and cleans up.
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
note sprintf 'server %s, DBD::%s %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION;

sub drop_table { local $raw->{Warn} = 0; $raw->do("DROP TABLE IF EXISTS `$T`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_table() };
  }
}
drop_table();

# The indexes of the table as the server lists them: name => [ type, columns ].
sub server_indexes {
  my %got;
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT INDEX_NAME, INDEX_TYPE, COLUMN_NAME FROM information_schema.STATISTICS '
  . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? ORDER BY INDEX_NAME, SEQ_IN_INDEX', undef, $T,
  ) }) {
    my ($name, $type, $column) = @$row;
    $got{$name} //= [$type];
    push @{ $got{$name} }, $column;
  }
  return \%got;
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $schema = K25Live::Schema->connect($dsn, $user, $pass);
my $deploy = DBIO::MySQL::Deploy->new(schema => $schema);

note "the DDL:\n" . join "\n", grep { /INDEX/ } split /\n\n/, DBIO::MySQL::DDL->install_ddl($schema);

# ---------------------------------------------------------------------------
# 1. install
# ---------------------------------------------------------------------------
unless (ok eval { $deploy->install; 1 }, 'install: install_ddl runs against the server without an error') {
  diag "the deploy failed, and nothing below can be asked: $@";
  done_testing;
  exit;   # END drops what was created
}

# What the server had to say about the last statement, the SPATIAL index over
# the GEOMETRY column. Noted: MySQL 8 warns that it will not use the index.
my $said = $schema->storage->dbh_do(sub { $_[1]->selectall_arrayref('SHOW WARNINGS') });
note 'creating the last SPATIAL index, the server warned: '
  . (@$said ? join(' | ', map { "$_->[1] $_->[2]" } @$said) : 'nothing');

# ---------------------------------------------------------------------------
# 2. what the server has
# ---------------------------------------------------------------------------
is_deeply server_indexes(), \%DECLARED,
  'the server lists each index with the type and the column that were declared'
  or diag explain server_indexes();
note join ', ', map { "$_: " . server_indexes()->{$_}[0] } sort keys %{ server_indexes() };

my %column_type = map { @$_ } @{ $raw->selectall_arrayref(
  'SELECT COLUMN_NAME, CONCAT(DATA_TYPE, IF(IS_NULLABLE = \'NO\', \' not null\', \'\')) '
. 'FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', undef, $T,
) };
is lc $column_type{loc},  'point not null',    q{data_type => 'point' is a POINT NOT NULL column on the server};
is lc $column_type{area}, 'geometry not null', q{data_type => 'geometry' is a GEOMETRY NOT NULL column};

# ---------------------------------------------------------------------------
# 3. they work. Literal SQL through the ResultSet, for the values going in and
#    for the conditions.
# ---------------------------------------------------------------------------
my $places = $schema->resultset('Place');
for my $place (
  [ harbour  => 'salt water, ropes and a rusting crane',   'POINT(1 1)',    'POLYGON((0 0, 0 2, 2 2, 2 0, 0 0))' ],
  [ mountain => 'granite ridges under late snow',          'POINT(50 50)',  'POLYGON((49 49, 49 51, 51 51, 51 49, 49 49))' ],
  [ desert   => 'dunes, a dry well and a lot of silence',  'POINT(-30 10)', 'POLYGON((-31 9, -31 11, -29 11, -29 9, -31 9))' ],
) {
  my ($name, $body, $loc, $area) = @$place;
  $places->create({
    name => $name,
    body => $body,
    loc  => \[ 'ST_GeomFromText(?)', $loc ],
    area => \[ 'ST_GeomFromText(?)', $area ],
  });
}
is $places->count, 3, 'three rows are in, their geometries given as literal SQL';

sub names { [ sort $places->search($_[0], { columns => ['name'] })->get_column('name')->all ] }

is_deeply names(\[ 'MATCH(body) AGAINST (?)', 'granite' ]), ['mountain'],
  'MATCH ... AGAINST over the FULLTEXT index finds its row';
is_deeply names(\[ 'MBRContains(ST_GeomFromText(?), loc)', 'POLYGON((0 0, 0 2, 2 2, 2 0, 0 0))' ]), ['harbour'],
  'MBRContains over the POINT column finds its row';
is_deeply names(\[ 'MBRContains(area, ST_GeomFromText(?))', 'POINT(50 50)' ]), ['mountain'],
  'MBRContains over the GEOMETRY column finds its row';

# The control for the first of them: without a FULLTEXT index over the column
# the server does not answer a MATCH at all, so the answer above is the index.
ok !eval { names(\[ 'MATCH(name) AGAINST (?)', 'harbour' ]); 1 },
  'a MATCH over a column without a FULLTEXT index is refused by the server';
like "$@", qr/FULLTEXT/, '... for want of a FULLTEXT index';

# Whether the optimizer goes through the spatial index, when told to: noted.
for my $spatial ([ idx_k25_c_loc => 'MBRContains(ST_GeomFromText(\'POLYGON((0 0, 0 2, 2 2, 2 0, 0 0))\'), loc)' ]) {
  my ($index, $where) = @$spatial;
  my $plan = eval { $raw->selectall_arrayref("EXPLAIN SELECT name FROM `$T` FORCE INDEX ($index) WHERE $where", { Slice => {} }) };
  my ($key) = $plan ? map { $_->{key} // $_->{KEY} } @$plan : ();
  note "EXPLAIN with FORCE INDEX ($index): key = " . ($key // 'none -- the index is not used')
    . ($plan ? '' : " (EXPLAIN failed: $@)");
}

# ---------------------------------------------------------------------------
# 4. the diff
# ---------------------------------------------------------------------------
# A diff is of the whole database, which is shared: only what it says about
# this table is looked at, and nothing is applied unless that is all it says.
sub diff_for_table {
  my $diff = $deploy->diff;
  my @all  = map { $_->as_sql } @{ $diff->operations };
  return ($diff, [ grep { /\Q$T\E/ } @all ], scalar(@all));
}

SKIP: {
  my ($diff, $mine, $all) = eval { diff_for_table() };
  skip "no diff here -- it deploys into a temporary database, which this account may not create: $@", 10
    unless $diff;

  is_deeply $mine, [], 'after the deploy a diff of the schema against the database says nothing about this table'
    or diag explain $mine;

  # The control, and the diff's own rendering (karr k52): take the two index
  # classes away and see what it proposes.
  $raw->do("DROP INDEX idx_k25_b_body ON `$T`");
  $raw->do("DROP INDEX idx_k25_c_loc ON `$T`");
  ($diff, $mine, $all) = diff_for_table();
  is scalar(@$mine), 2, 'with the FULLTEXT and one SPATIAL index dropped by hand, the diff proposes two statements'
    or diag explain $mine;
  ok scalar( grep { /\ACREATE FULLTEXT INDEX `idx_k25_b_body` / } @$mine ), '... CREATE FULLTEXT INDEX for the one';
  ok scalar( grep { /\ACREATE SPATIAL INDEX `idx_k25_c_loc` / } @$mine ),   '... CREATE SPATIAL INDEX for the other';
  ok !( grep { /USING/ } @$mine ), '... neither with a USING clause';

  SKIP: {
    skip 'the diff also proposes changes to other tables of this shared database -- not applied', 4
      unless $all == @$mine;
    ok eval { $deploy->apply($diff); 1 }, 'applying that diff runs against the server without an error'
      or diag $@;
    is_deeply server_indexes(), \%DECLARED, '... and the indexes are back, of the classes that were declared'
      or diag explain server_indexes();

    # Asked with a row written AFTER the index was created again. MariaDB
    # 11.8.8 does not find the earlier rows through a FULLTEXT index that was
    # dropped and created again while they were there -- with plain SQL as
    # well, until the table is rebuilt; MySQL 8.0.30 does. The server's, and
    # noted: the index this driver asked for is there and takes new rows.
    $places->create({
      name => 'quarry',
      body => 'basalt columns, cut and stacked',
      loc  => \[ 'ST_GeomFromText(?)', 'POINT(9 9)' ],
      area => \[ 'ST_GeomFromText(?)', 'POLYGON((8 8, 8 10, 10 10, 10 8, 8 8))' ],
    });
    my $asked = sub { eval { names(@_) } // [ "refused: $@" ] };
    is_deeply $asked->(\[ 'MATCH(body) AGAINST (?)', 'basalt' ]), ['quarry'],
      '... the FULLTEXT one answering again, for a row written since';
    note 'rows written before the FULLTEXT index was dropped are '
      . (@{ $asked->(\[ 'MATCH(body) AGAINST (?)', 'granite' ]) } ? 'found' : 'NOT found')
      . ' through the index created again';
    is_deeply $asked->(\[ 'MBRContains(ST_GeomFromText(?), loc)', 'POLYGON((0 0, 0 2, 2 2, 2 0, 0 0))' ]), ['harbour'],
      '... and the SPATIAL one';
  }

  is_deeply $raw->selectcol_arrayref(q{SHOW DATABASES LIKE '\_dbio\_tmp\_%'}), [],
    'the diff left no temporary database behind';
}

# ---------------------------------------------------------------------------
# 5. What t/31 has the DDL refuse before it is sent, the server refuses too.
# ---------------------------------------------------------------------------
for my $class ([ FULLTEXT => 'body' ], [ SPATIAL => 'loc' ]) {
  my ($kw, $column) = @$class;
  ok !eval { $raw->do("CREATE UNIQUE $kw INDEX idx_k25_refused ON `$T` ($column)"); 1 },
    "CREATE UNIQUE $kw INDEX is refused by the server";
  is $raw->err, 1064, '... as a syntax error';
}

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

$schema->storage->disconnect;
drop_table();
$raw->disconnect;
undef $raw;

done_testing;
