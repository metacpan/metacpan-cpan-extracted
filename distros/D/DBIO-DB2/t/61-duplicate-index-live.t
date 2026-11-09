use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k47, ADR 0010). The counterpart of t/62-duplicate-index.t and
# t/63-sqlstate-605.t. CREATE INDEX over a column sequence that the primary key,
# a UNIQUE constraint or an earlier index already has answers SQL0605W (err 605,
# state 42S11, rv undef) and makes nothing, which killed install halfway and
# brought the index back on every upgrade diff.
#
# Part 1 measures the rule on a raw handle (what is a duplicate, what is not);
# parts 2 and 3 run a result class through the public DBIO::DB2::Deploy API:
# db2_indexes entries on the PK columns and two with the same column sequence,
# through install and through upgrade, each ending on an empty diff; part 4 the
# raw 605 through the storage handle (a warning, not an exception).
#
# Tables carry the pid (dbio_k47_<pid>), only they are touched.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $TABLE = "dbio_k47_$$";
my $RAW   = "dbio_k47r_$$";

{
  package DBIO::Test::K47::Plain;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k47_$$");
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'integer' },
    b  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package DBIO::Test::K47::Indexed;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k47_$$");
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'integer' },
    b  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  sub db2_indexes {
    return {
      k47_pk    => { columns => ['id'] },                    # the PK columns
      k47_pku   => { columns => ['id'], unique => 1 },       # the PK columns, unique
      k47_ab    => { columns => [qw(a b)] },
      k47_ab2   => { columns => [qw(a b)] },                 # same sequence
      k47_ba    => { columns => [qw(b a)] },                 # other order: no duplicate
    };
  }
}
for my $n (qw(Plain Indexed)) {
  eval qq{
    package DBIO::Test::K47::${n}Schema;
    use strict; use warnings;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('DB2');
    __PACKAGE__->register_class(Item => 'DBIO::Test::K47::$n');
    1;
  } or die $@;
}

use DBIO::DB2::Deploy;

my $plain   = DBIO::Test::K47::PlainSchema->connect($dsn, $user, $pass);
my $indexed = DBIO::Test::K47::IndexedSchema->connect($dsn, $user, $pass);

my $dbh = eval { $indexed->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $d_plain   = DBIO::DB2::Deploy->new(schema => $plain);
my $d_indexed = DBIO::DB2::Deploy->new(schema => $indexed);

sub drop_test_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for $TABLE, $RAW;
}

sub index_rows {
  my ($table) = @_;
  my $rows = $dbh->selectall_arrayref(q{
    SELECT TRIM(indname), uniquerule, TRIM(colnames) FROM syscat.indexes
    WHERE tabschema = CURRENT SCHEMA AND tabname = ? AND indschema = CURRENT SCHEMA
    ORDER BY indname
  }, undef, $table);
  return [ map { join ' ', @$_ } @$rows ];
}

sub ops_of {
  my ($deploy) = @_;
  my $diff = eval { $deploy->diff } or return [ "diff died: $@" ];
  return [ map { $_->as_sql } @{ $diff->operations } ];
}

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
END {
  if ($dbh && $dbh->{Active}) {
    drop_test_tables();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $d_indexed->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_test_tables();

# ============================================================================
# 1. the rule, on a raw handle: what the server answers with 605
# ============================================================================
{
  local $dbh->{PrintError} = 0;
  local $dbh->{RaiseError} = 0;
  local $dbh->{HandleError};     # the raw answer, not the storage's handling
  $dbh->do(qq{CREATE TABLE "$RAW" ("id" INTEGER NOT NULL, "a" INTEGER NOT NULL, "b" INTEGER NOT NULL, }
         . qq{PRIMARY KEY ("id"), CONSTRAINT "k47_uq" UNIQUE ("a"))});

  my $try = sub {
    my ($sql) = @_;
    my $rv = $dbh->do($sql);
    return defined $rv ? 'made' : ($dbh->err // 0) . '/' . ($dbh->state // '');
  };
  my %t = (
    'non-unique over the PK'              => [ qq{CREATE INDEX "k47_1" ON "$RAW" ("id")}, '605/42S11' ],
    'unique over the PK'                  => [ qq{CREATE UNIQUE INDEX "k47_2" ON "$RAW" ("id")}, '605/42S11' ],
    'non-unique over a UNIQUE constraint' => [ qq{CREATE INDEX "k47_3" ON "$RAW" ("a")}, '605/42S11' ],
    'non-unique'                          => [ qq{CREATE INDEX "k47_4" ON "$RAW" ("a", "b")}, 'made' ],
    'same columns, other order'           => [ qq{CREATE INDEX "k47_5" ON "$RAW" ("b", "a")}, 'made' ],
    'non-unique over a non-unique'        => [ qq{CREATE INDEX "k47_6" ON "$RAW" ("a", "b")}, '605/42S11' ],
    'unique over a non-unique'            => [ qq{CREATE UNIQUE INDEX "k47_7" ON "$RAW" ("a", "b")}, 'made' ],
    'non-unique over a unique index'      => [ qq{CREATE INDEX "k47_8" ON "$RAW" ("a", "b")}, '605/42S11' ],
    'unique over a unique index'          => [ qq{CREATE UNIQUE INDEX "k47_9" ON "$RAW" ("a", "b")}, '605/42S11' ],
    'longer than the PK'                  => [ qq{CREATE INDEX "k47_10" ON "$RAW" ("id", "b")}, 'made' ],
  );
  for my $label ('non-unique over the PK', 'unique over the PK', 'non-unique over a UNIQUE constraint',
                 'non-unique', 'same columns, other order', 'non-unique over a non-unique',
                 'unique over a non-unique', 'non-unique over a unique index',
                 'unique over a unique index', 'longer than the PK') {
    is $try->($t{$label}[0]), $t{$label}[1], "server: $label";
  }
  eval { $dbh->do(qq{DROP TABLE "$RAW"}) };
}

# ============================================================================
# 2. install: no entry that duplicates is written, the rest is
# ============================================================================
lives_ok { $d_indexed->install } 'install survives db2_indexes entries on the PK columns and a repeated sequence';
is_deeply index_rows($TABLE),
  [ "k47_ab D +a+b", "k47_ba D +b+a" ],
  'only the indexes that are not duplicates exist (k47_pk, k47_pku, k47_ab2 left out)';
is_deeply ops_of($d_indexed), [], 'the follow-up diff is empty';
drop_test_tables();

# ============================================================================
# 3. upgrade: the same, onto an existing table
# ============================================================================
lives_ok { $d_plain->install } 'a plain table is installed';
my $ops = ops_of($d_indexed);
is_deeply [ grep { /INDEX/ } @$ops ],
  [ qq{CREATE INDEX "k47_ab" ON "$TABLE" ("a", "b");}, qq{CREATE INDEX "k47_ba" ON "$TABLE" ("b", "a");} ],
  'the diff holds two CREATE INDEX, none for the PK columns or the repeated sequence';
lives_ok { $d_indexed->upgrade } 'upgrade runs through';
is_deeply index_rows($TABLE), [ "k47_ab D +a+b", "k47_ba D +b+a" ], 'the same two indexes exist';
is_deeply ops_of($d_indexed), [], 'the diff after the upgrade is empty';
drop_test_tables();

# ============================================================================
# 4. a 605 that reaches the server anyway is a warning, not an exception
# ============================================================================
$d_plain->install;
{
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  lives_ok { $dbh->do(qq{CREATE INDEX "k47_dup" ON "$TABLE" ("id")}) }
    'CREATE INDEX over the PK columns does not throw through the storage handle';
  is scalar @w, 1, '... one warning';
  like $w[0], qr/index "k47_dup" on table "\Q$TABLE\E"/, '... naming index and table';
  is_deeply index_rows($TABLE), [], '... and no index was made';
}

done_testing;
