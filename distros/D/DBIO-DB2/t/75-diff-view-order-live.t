use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k54, ADR 0011 addendum), the counterpart of t/74-diff-view-order.t.
# Views that read views, through the public DBIO::DB2::Deploy API, on objects of
# their own (dbio_k54v_<pid>_*). The names are chosen so that the name order is
# the wrong one: a reads b, b reads c, c reads the table t.
#
#   1. install from a schema with the three views: the server accepts the order
#      (c, b, a) and the follow-up diff is empty
#   2. upgrade from a database with only t to that schema: the diff creates in
#      the order of what the views read, the views answer rows
#   3. the base view c is replaced (a new column), a and b unchanged: the diff
#      drops a, b, c and creates c, b, a; upgrade applies it, a and b answer rows
#      again, the follow-up diff is empty
#   4. the schema without the views: the diff drops a, b, c; upgrade applies it

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ResultSource::View ();
use DBIO::DB2::Deploy;

my $T = "dbio_k54v_${$}_t";
my %V = map { $_ => "dbio_k54v_${$}_$_" } qw(a b c);

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

# a reads b, b reads c, c reads t; "c2" is c with a second column
my %DEF = (
  a  => qq{SELECT "id" FROM "$V{b}"},
  b  => qq{SELECT "id" FROM "$V{c}"},
  c  => qq{SELECT "id" FROM "$T"},
  c2 => qq{SELECT "id", "name" FROM "$T"},
);

make_table_class('DBIO::Test::K54V::T');
make_view_class('DBIO::Test::K54V::A',  $V{a}, $DEF{a},  'id');
make_view_class('DBIO::Test::K54V::B',  $V{b}, $DEF{b},  'id');
make_view_class('DBIO::Test::K54V::C',  $V{c}, $DEF{c},  'id');
make_view_class('DBIO::Test::K54V::C2', $V{c}, $DEF{c2}, qw(id name));

make_schema('DBIO::Test::K54V::Bare', T => 'DBIO::Test::K54V::T');
make_schema('DBIO::Test::K54V::Full',
  T => 'DBIO::Test::K54V::T', A => 'DBIO::Test::K54V::A',
  B => 'DBIO::Test::K54V::B', C => 'DBIO::Test::K54V::C');
make_schema('DBIO::Test::K54V::Changed',
  T => 'DBIO::Test::K54V::T', A => 'DBIO::Test::K54V::A',
  B => 'DBIO::Test::K54V::B', C => 'DBIO::Test::K54V::C2');

my %schema = map { $_ => "DBIO::Test::K54V::$_"->connect($dsn, $user, $pass) } qw(Bare Full Changed);

my $dbh = eval { $schema{Full}->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my %deploy = map { $_ => DBIO::DB2::Deploy->new(schema => $schema{$_}) } keys %schema;

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_all {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP VIEW "$V{$_}"}) } for qw(a b c);
  eval { $dbh->do(qq{DROP TABLE "$T"}) };
}
END {
  if ($dbh && $dbh->{Active}) {
    drop_all();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy{Full}->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

sub ops_of {
  my ($deploy) = @_;
  my $diff = eval { $deploy->diff } or return [ "diff died: $@" ];
  return [ map { $_->as_sql } @{ $diff->operations } ];
}
sub view_names {
  my $r = $dbh->selectcol_arrayref(q{SELECT viewname FROM syscat.views WHERE viewschema = CURRENT SCHEMA AND viewname LIKE ? ORDER BY viewname},
    undef, "dbio_k54v_${$}_%");
  return [ map { s/\s+$//r } @$r ];
}
sub rows_ok {
  my ($what, @views) = @_;
  for my $v (@views) {
    my $rows = eval { $dbh->selectall_arrayref(qq{SELECT "id" FROM "$V{$v}"}) };
    is_deeply $rows, [ [ 1 ] ], "$what: view $v answers its row" or diag $@;
  }
}

drop_all();

# ============================================================================
# 1. install, in the order of what the views read
# ============================================================================
lives_ok { $deploy{Full}->install } 'install creates views that read views, though the name order is the wrong one';
is_deeply view_names(), [ sort @V{qw(a b c)} ], 'the database holds the three views';
is_deeply ops_of($deploy{Full}), [], 'diff right after install is empty';

drop_all();

# ============================================================================
# 2. upgrade from a database with only the table
# ============================================================================
lives_ok { $deploy{Bare}->install } 'a database with only the table';
$dbh->do(qq{INSERT INTO "$T" ("name") VALUES ('x')});
is_deeply ops_of($deploy{Full}), [
  qq{CREATE VIEW "$V{c}" AS $DEF{c};},
  qq{CREATE VIEW "$V{b}" AS $DEF{b};},
  qq{CREATE VIEW "$V{a}" AS $DEF{a};},
], 'the diff creates the views in the order of what they read';
lives_ok { $deploy{Full}->upgrade } 'upgrade creates them';
rows_ok('after upgrade', qw(a b c));
is_deeply ops_of($deploy{Full}), [], 'the follow-up diff is empty';

# ============================================================================
# 3. the base view is replaced, its readers with it
# ============================================================================
is_deeply ops_of($deploy{Changed}), [
  qq{DROP VIEW "$V{a}";},
  qq{DROP VIEW "$V{b}";},
  qq{DROP VIEW "$V{c}";},
  qq{CREATE VIEW "$V{c}" AS $DEF{c2};},
  qq{CREATE VIEW "$V{b}" AS $DEF{b};},
  qq{CREATE VIEW "$V{a}" AS $DEF{a};},
], 'a replaced base view: its readers are dropped before it and created after it';
lives_ok { $deploy{Changed}->upgrade } 'upgrade replaces the base view and its readers';
rows_ok('after replace', qw(a b c));
{
  my $sth = $dbh->prepare(qq{SELECT * FROM "$V{c}"});
  $sth->execute;
  is_deeply [ map { lc } @{ $sth->{NAME} } ], [qw(id name)], 'the base view has its new definition';
}
is_deeply ops_of($deploy{Changed}), [], 'the follow-up diff is empty';

# ============================================================================
# 4. the views go away, readers first
# ============================================================================
is_deeply ops_of($deploy{Bare}), [
  qq{DROP VIEW "$V{a}";}, qq{DROP VIEW "$V{b}";}, qq{DROP VIEW "$V{c}";},
], 'the diff drops a view before the views it reads';
lives_ok { $deploy{Bare}->upgrade(allow_destructive => 1) } 'upgrade drops them';
is_deeply view_names(), [], 'no view is left';
is_deeply ops_of($deploy{Bare}), [], 'the follow-up diff is empty';

done_testing;
