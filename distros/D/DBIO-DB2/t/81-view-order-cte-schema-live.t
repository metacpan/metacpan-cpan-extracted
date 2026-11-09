use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k55), the counterpart of the CTE and schema-qualifier blocks of
# t/74-diff-view-order.t, through the public DBIO::DB2::Deploy API, on objects of
# their own (dbio_k55x_<pid>_*). The names are chosen so that the name order is the
# wrong one where a dependency is real and the right one where it is not:
#
#   a  reads  <CURRENT SCHEMA>.z     the own schema, qualified: a dependency, a after z
#   c  WITH z AS (...) SELECT ... FROM z   z is the CTE here, though a view z exists: none
#   z  reads  the table t
#   w  reads  SYSIBM.SYSDUMMY1       another schema: none
#
# install creates them in the order z, then the others by name (a, c, w); a wrongly
# counted CTE would put c after z too, a wrongly kept foreign qualifier would not
# change that, so the order of the DDL is also asserted offline in t/74. Here: the
# server accepts the install, every view answers its row, and the follow-up diff is
# empty.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::ResultSource::View ();
use DBIO::DB2::Deploy;

my $T = "dbio_k55x_${$}_t";
my %V = map { $_ => "dbio_k55x_${$}_$_" } qw(a c z w);

my $probe = DBIO::Schema->can('connect') && do {
  package DBIO::Test::K55X::Probe;
  our @ISA = ('DBIO::Schema');
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->connect($dsn, $user, $pass);
};
my $dbh = eval { $probe->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";
my ($CS) = $dbh->selectrow_array('VALUES CURRENT SCHEMA');
$CS =~ s/\s+$//;

my %DEF = (
  a => qq{SELECT "id" FROM "$CS"."$V{z}"},
  c => qq{WITH "$V{z}" AS (SELECT "id" FROM "$T") SELECT "id" FROM "$V{z}"},
  z => qq{SELECT "id" FROM "$T"},
  w => qq{SELECT 1 AS "id" FROM SYSIBM.SYSDUMMY1},
);

sub make_view_class {
  my ($class, $name, $def) = @_;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table_class('DBIO::ResultSource::View');
  $class->table($name);
  $class->add_columns(id => { data_type => 'integer' });
  $class->result_source_instance->view_definition($def);
}
{
  my $class = 'DBIO::Test::K55X::T';
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table($T);
  $class->add_columns(id => { data_type => 'integer' });
  $class->set_primary_key('id');
}
make_view_class("DBIO::Test::K55X::V\U$_", $V{$_}, $DEF{$_}) for qw(a c z w);

{
  no strict 'refs';
  @{'DBIO::Test::K55X::Schema::ISA'} = ('DBIO::Schema');
  DBIO::Test::K55X::Schema->load_components('DB2');
  DBIO::Test::K55X::Schema->register_class(T => 'DBIO::Test::K55X::T');
  DBIO::Test::K55X::Schema->register_class("V\U$_" => "DBIO::Test::K55X::V\U$_") for qw(a c z w);
}

my $schema = DBIO::Test::K55X::Schema->connect($dsn, $user, $pass);
my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_all {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP VIEW "$V{$_}"}) } for qw(a c w z);
  eval { $dbh->do(qq{DROP TABLE "$T"}) };
}
END {
  if ($dbh && $dbh->{Active}) {
    drop_all();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_all();

# the order as install_ddl writes it, with the schema Deploy hands it
{
  my $ddl = DBIO::DB2::DDL->install_ddl($schema, $CS);
  my @v = $ddl =~ /^CREATE VIEW "dbio_k55x_\d+_(\w)"/mg;
  is_deeply \@v, [qw(c w z a)], 'install_ddl: the CTE c and the foreign-schema w are free (name order), a waits for z'
    or diag $ddl;
}

{
  # by hand, without the schema: the connection's CURRENT SCHEMA is the target schema
  my $ddl = DBIO::DB2::DDL->install_ddl($schema);
  my @v = $ddl =~ /^CREATE VIEW "dbio_k55x_\d+_(\w)"/mg;
  is_deeply \@v, [qw(c w z a)], 'install_ddl without the schema: found from the connection, the same order'
    or diag $ddl;
}

lives_ok { $deploy->install } 'install: the server accepts the views in that order';
$dbh->do(qq{INSERT INTO "$T" ("id") VALUES (1)});
for my $v (qw(a c z w)) {
  my $rows = eval { $dbh->selectall_arrayref(qq{SELECT "id" FROM "$V{$v}"}) };
  is_deeply $rows, [ [1] ], "view $v answers its row" or diag $@;
}
{
  my $diff = eval { $deploy->diff } or diag $@;
  is scalar(@{ $diff ? $diff->operations : [1] }), 0, 'the follow-up diff is empty' or diag $diff && $diff->as_sql;
}

drop_all();
done_testing;
