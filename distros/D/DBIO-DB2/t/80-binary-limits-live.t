use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k55), the counterpart of the limits block of t/39. Db2 12.1.5:
# BINARY(n) takes n <= 255, VARBINARY(n) n <= 32672. A class column
# `binary` of 300 is written as VARBINARY(300), the catalog reads VARBINARY, the
# model says `varbinary` with size 300 (what DBIO::Generate writes back), and the
# follow-up diff is empty. The VARBINARY limit installs, a column beyond it is
# refused at render time naming table and column, with nothing created.
#
# Own tables: dbio_k55v_<pid> (installed), dbio_k55w_<pid> (refused).

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $T = "dbio_k55v_$$";
my $W = "dbio_k55w_$$";

sub make_schema {
  my ($name, $table, %cols) = @_;
  my $schema_class = "DBIO::Test::K55V::${name}::Schema";
  my $class        = "DBIO::Test::K55V::${name}::T";
  no strict 'refs';
  @{"${schema_class}::ISA"} = ('DBIO::Schema');
  @{"${class}::ISA"}        = ('DBIO::Core');
  $schema_class->load_components('DB2');
  $class->table($table);
  $class->add_columns(id => { data_type => 'integer', is_auto_increment => 1 }, %cols);
  $class->set_primary_key('id');
  $schema_class->register_class(T => $class);
  return $schema_class;
}

require DBIO::Core;
require DBIO::Schema;
my $good = make_schema('Good', $T,
  b300 => { data_type => 'binary',    size => 300,   is_nullable => 1 },
  b255 => { data_type => 'binary',    size => 255,   is_nullable => 1 },
  vmax => { data_type => 'varbinary', size => 32672, is_nullable => 1 },
);
my $bad = make_schema('Bad', $W,
  big => { data_type => 'binary', size => 32673, is_nullable => 1 },
);

use DBIO::DB2::Deploy;

my $schema = $good->connect($dsn, $user, $pass);
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";
my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub drop_tables { local $dbh->{PrintError} = 0; eval { $dbh->do(qq{DROP TABLE "$_"}) } for $T, $W }
END {
  if ($dbh && $dbh->{Active}) {
    drop_tables();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_tables();

my $ddl = DBIO::DB2::DDL->install_ddl($good);
like $ddl, qr/"b300" VARBINARY\(300\)/,   'a binary of 300 is written as VARBINARY(300)';
like $ddl, qr/"b255" BINARY\(255\)/,      '... a binary of 255 stays BINARY(255)';
like $ddl, qr/"vmax" VARBINARY\(32672\)/, '... a varbinary at its limit stays';

lives_ok { $dbh->do($_) for DBIO::SQL::Util::_split_statements($ddl) } 'the server accepts the DDL';

my $model = $deploy->_introspect_current;
my %col = map { $_->{column_name} => $_ } @{ $model->{columns}{$T} };
is_deeply [ @{ $col{b300} }{qw(catalog_type catalog_size)} ], [ 'VARBINARY', 300 ], 'the catalog holds VARBINARY(300)';
is_deeply [ @{ $col{b300} }{qw(data_type size)} ], [ 'varbinary', 300 ],
  '... and the model says varbinary 300, what a generated class writes back';
is_deeply [ @{ $col{b255} }{qw(data_type size)} ], [ 'binary', 255 ], 'BINARY(255) stays binary 255';

{
  my $diff = $deploy->diff;
  is scalar(@{ $diff->operations }), 0, 'the follow-up diff is empty' or diag $diff->as_sql;
}

{
  my $bytes = join '', map { chr($_ % 256) } 0 .. 299;
  my $sth = $dbh->prepare(qq{INSERT INTO "$T" ("b300") VALUES (?)});
  $sth->bind_param(1, $bytes, DBI::SQL_VARBINARY());
  lives_ok { $sth->execute } 'a row of 300 bytes is stored';
  my ($back) = $dbh->selectrow_array(qq{SELECT "b300" FROM "$T"});
  is length($back), 300, '... and reads back whole';
}

# the class generated from that model installs to the same table
{
  my $regen = make_schema('Regen', "${T}_regen",
    map { $_->{column_name} => { data_type => $_->{data_type}, size => $_->{size}, is_nullable => 1 } }
    grep { $_->{column_name} ne 'id' } @{ $model->{columns}{$T} });
  my $d2 = DBIO::DB2::DDL->install_ddl($regen);
  like $d2, qr/"b300" VARBINARY\(300\)/, 'the class written from the model renders the same type';
}

# beyond the limit: refused naming the column, nothing created
throws_ok { DBIO::DB2::DDL->install_ddl($bad) } qr/binary.*column \Q$W\E\.big.*32673.*32672/s,
  'a binary of 32673 is refused at render time, naming table.column, size and limit';
{
  my ($n) = $dbh->selectrow_array(
    q{SELECT COUNT(*) FROM syscat.tables WHERE tabschema = CURRENT SCHEMA AND tabname = ?}, undef, $W);
  is $n, 0, '... and no table was made';
}

drop_tables();
done_testing;
