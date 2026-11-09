use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k45, ADR 0011), the counterpart of t/68-diff-view.t. Views
# through the public DBIO::DB2::Deploy API, on objects of their own
# (dbio_k45v_<pid>_*):
#
#   - the database holds t, v_keep, v_chg (definition 1) and v_extra (installed
#     from a schema that declares them)
#   - the schema in hand declares t, v_keep (same), v_chg (definition 2) and
#     v_new
#
# The diff over a schema whose views are all there, as declared, is empty: the
# view of the compare schema (DBIO_TEST_<pid>, ADR 0006) has the definition of
# the live one. The diff then holds exactly DROP VIEW v_extra / DROP VIEW v_chg
# first and CREATE VIEW v_chg / CREATE VIEW v_new last, no table operation; it dies
# no more (karr k36). upgrade makes the database the schema, a missing view is
# there and answers rows, the surplus one is gone, the changed one has its new
# columns, the follow-up diff is empty.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ResultSource::View ();

my $T      = "dbio_k45v_${$}_t";
my %V      = map { $_ => "dbio_k45v_${$}_$_" } qw(keep chg extra new);

sub make_view_class {
  my ($class, $name, $def, @cols) = @_;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table_class('DBIO::ResultSource::View');
  $class->table($name);
  $class->add_columns(map { $_ => { data_type => 'integer' } } @cols);
  $class->result_source_instance->view_definition($def);
  return $class;
}
sub make_table_class {
  my ($class) = @_;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table($T);
  $class->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20 },
  );
  $class->set_primary_key('id');
  return $class;
}
sub make_schema {
  my ($schema_class, %sources) = @_;
  no strict 'refs';
  @{"${schema_class}::ISA"} = ('DBIO::Schema');
  $schema_class->load_components('DB2');
  $schema_class->register_class($_ => $sources{$_}) for sort keys %sources;
  return $schema_class;
}

my $sel = sub { my ($cols) = @_; return qq{SELECT $cols FROM "$T"} };

# what the database holds
make_table_class('DBIO::Test::K45V::T1');
make_view_class('DBIO::Test::K45V::Keep1',  $V{keep},  $sel->('"id"'),         'id');
make_view_class('DBIO::Test::K45V::Chg1',   $V{chg},   $sel->('"id"'),         'id');
make_view_class('DBIO::Test::K45V::Extra1', $V{extra}, $sel->('"id", "name"'), qw(id name));
make_schema('DBIO::Test::K45V::Old',
  T => 'DBIO::Test::K45V::T1', Keep => 'DBIO::Test::K45V::Keep1',
  Chg => 'DBIO::Test::K45V::Chg1', Extra => 'DBIO::Test::K45V::Extra1');

# what the schema in hand declares
make_table_class('DBIO::Test::K45V::T2');
make_view_class('DBIO::Test::K45V::Keep2', $V{keep}, $sel->('"id"'),         'id');
make_view_class('DBIO::Test::K45V::Chg2',  $V{chg},  $sel->('"id", "name"'), qw(id name));
make_view_class('DBIO::Test::K45V::New2',  $V{new},  $sel->('"name"'),       'name');
make_schema('DBIO::Test::K45V::Want',
  T => 'DBIO::Test::K45V::T2', Keep => 'DBIO::Test::K45V::Keep2',
  Chg => 'DBIO::Test::K45V::Chg2', New => 'DBIO::Test::K45V::New2');

use DBIO::DB2::Deploy;

# a View source needs a column declared as in the model: the views above take
# integer columns for brevity, only the definitions matter to the server.
my $old = DBIO::Test::K45V::Old->connect($dsn, $user, $pass);
my $want = DBIO::Test::K45V::Want->connect($dsn, $user, $pass);

my $dbh = eval { $old->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $d_old  = DBIO::DB2::Deploy->new(schema => $old);
my $d_want = DBIO::DB2::Deploy->new(schema => $want);

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_all {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP VIEW "$_"}) } for values %V;
  eval { $dbh->do(qq{DROP TABLE "$T"}) };
}
END {
  if ($dbh && $dbh->{Active}) {
    drop_all();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $d_old->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

sub ops_of {
  my ($deploy) = @_;
  my $diff = eval { $deploy->diff } or return ([ "diff died: $@" ], undef);
  return ([ map { $_->as_sql } @{ $diff->operations } ], $diff);
}
sub view_names {
  my $r = $dbh->selectcol_arrayref(q{SELECT viewname FROM syscat.views WHERE viewschema = CURRENT SCHEMA AND viewname LIKE ? ORDER BY viewname},
    undef, "dbio_k45v_${$}_%");
  return [ map { s/\s+$//r } @$r ];
}

drop_all();

# ============================================================================
# 1. install; a database that has its views, as declared, has nothing to do.
# ============================================================================
lives_ok { $d_old->install } 'install deploys the table and its three views';
is_deeply view_names(), [ sort @V{qw(keep chg extra)} ], 'the database holds the views';
{
  my ($sql, $diff) = ops_of($d_old);
  is_deeply $sql, [], 'diff right after install is empty (a view of the compare schema has the live definition)'
    or diag join "\n", @$sql;
}

$dbh->do(qq{INSERT INTO "$T" ("name") VALUES ('a')});

# ============================================================================
# 2. the schema declares other views: the diff is the view operations.
# ============================================================================
{
  my ($sql, $diff) = ops_of($d_want);
  ok $diff, 'diff with a missing, a surplus and a changed view does not die' or diag $sql->[0];
  is_deeply $sql, [
    qq{DROP VIEW "$V{extra}";},
    qq{DROP VIEW "$V{chg}";},
    qq{CREATE VIEW "$V{chg}" AS SELECT "id", "name" FROM "$T";},
    qq{CREATE VIEW "$V{new}" AS SELECT "name" FROM "$T";},
  ], 'drops at the head, creates at the end, no table operation, the unchanged view left alone'
    or diag join "\n", @$sql;
}

# ============================================================================
# 3. upgrade makes the database the schema.
# ============================================================================
lives_ok { $d_want->upgrade(allow_destructive => 1) } 'upgrade applies the view operations';
is_deeply view_names(), [ sort @V{qw(keep chg new)} ], 'missing view created, surplus view dropped';
is_deeply $dbh->selectall_arrayref(qq{SELECT "name" FROM "$V{new}"}), [ ['a'] ], 'the created view answers rows';
{
  my $sth = $dbh->prepare(qq{SELECT * FROM "$V{chg}"});
  $sth->execute;
  is_deeply [ map { lc } @{ $sth->{NAME} } ], [qw(id name)], 'the changed view has its new definition';
}
{
  my ($sql) = ops_of($d_want);
  is_deeply $sql, [], 'the follow-up diff is empty' or diag join "\n", @$sql;
}

# ============================================================================
# 4. the other way: the old schema now finds its views missing / surplus.
# ============================================================================
{
  my ($sql, $diff) = ops_of($d_old);
  ok $diff, 'the diff the other way does not die either';
  is_deeply $sql, [
    qq{DROP VIEW "$V{new}";},
    qq{DROP VIEW "$V{chg}";},
    qq{CREATE VIEW "$V{chg}" AS SELECT "id" FROM "$T";},
    qq{CREATE VIEW "$V{extra}" AS SELECT "id", "name" FROM "$T";},
  ], 'drops first, creates last' or diag join "\n", @$sql;
}
lives_ok { $d_old->upgrade(allow_destructive => 1) } '... and upgrade goes back';
{
  my ($sql) = ops_of($d_old);
  is_deeply $sql, [], 'the follow-up diff is empty' or diag join "\n", @$sql;
}

done_testing;
