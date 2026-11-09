use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k45, ADR 0011). What the introspection holds of the keys of a
# table, on tables of its own (dbio_k45k_<pid>_*):
#
#   1. a foreign key onto a UNIQUE constraint of its parent has the columns of
#      that constraint as to_columns -- SYSCAT.REFERENCES.REFKEYNAME names the
#      key, the primary key of the parent is not it. A foreign key onto the
#      primary key keeps the primary key's columns.
#   2. the index Db2 keeps behind a primary key (schema SYSIBM, UNIQUERULE 'P')
#      is in the model with origin 'pk' and the primary key's columns, and the
#      one behind a UNIQUE constraint is not.
#   3. the diff over such tables stays empty after install (the name of the
#      SYSIBM index differs per schema, so the diff must not look at it).

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

my $PARENT = "dbio_k45k_${$}_p";
my $BY_UQ  = "dbio_k45k_${$}_u";
my $BY_PK  = "dbio_k45k_${$}_k";

{
  package DBIO::Test::K45K::Parent;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k45k_${$}_p");
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'integer' },
    b  => { data_type => 'varchar', size => 10 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(ab_uq => [qw(a b)]);
}
{
  package DBIO::Test::K45K::ByUq;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k45k_${$}_u");
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    pa => { data_type => 'integer' },
    pb => { data_type => 'varchar', size => 10 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'DBIO::Test::K45K::Parent',
    { 'foreign.a' => 'self.pa', 'foreign.b' => 'self.pb' });
}
{
  package DBIO::Test::K45K::ByPk;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table("dbio_k45k_${$}_k");
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'DBIO::Test::K45K::Parent', 'parent_id');
}
{
  package DBIO::Test::K45K::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Parent => 'DBIO::Test::K45K::Parent');
  __PACKAGE__->register_class(ByUq   => 'DBIO::Test::K45K::ByUq');
  __PACKAGE__->register_class(ByPk   => 'DBIO::Test::K45K::ByPk');
}

use DBIO::DB2::Deploy;
use DBIO::DB2::Introspect;

my $schema = DBIO::Test::K45K::Schema->connect($dsn, $user, $pass);
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);
my $COMPARE_SCHEMA = "DBIO_TEST_$$";

sub drop_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for $BY_UQ, $BY_PK, $PARENT;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_tables();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_tables();
lives_ok { $deploy->install } 'install deploys parent and both children';

my ($cur) = $dbh->selectrow_array('SELECT RTRIM(CURRENT SCHEMA) FROM sysibm.sysdummy1');
my $intro = DBIO::DB2::Introspect->new(dbh => $dbh, schema => $cur);
my $model = $intro->model;

# --- 1. to_columns follow REFKEYNAME ----------------------------------------
{
  my ($fk) = @{ $model->{foreign_keys}{$BY_UQ} || [] };
  ok $fk, 'the FK onto the UNIQUE constraint is in the model';
  is_deeply $fk && $fk->{from_columns}, [qw(pa pb)], '... from_columns';
  is_deeply $fk && $fk->{to_columns}, [qw(a b)],
    '... to_columns are the columns of the UNIQUE constraint, not the parent primary key';
}
{
  my ($fk) = @{ $model->{foreign_keys}{$BY_PK} || [] };
  ok $fk, 'the FK onto the primary key is in the model';
  is_deeply $fk && $fk->{to_columns}, ['id'], '... to_columns are the primary key columns';
}

# --- 2. the primary key's index is in the model, with origin pk -------------
{
  my $idx = $model->{indexes}{$PARENT} || {};
  my @pk = grep { ($_->{origin} // '') eq 'pk' } values %$idx;
  is scalar(@pk), 1, 'the parent has one index with origin pk';
  is_deeply $pk[0] && $pk[0]{columns}, ['id'], '... over the primary key columns';
  ok $pk[0] && $pk[0]{is_unique}, '... unique';
  is scalar(grep { ($_->{origin} // '') ne 'pk' } values %$idx), 0,
    'the index behind the UNIQUE constraint is not an index of the model';
  is_deeply [ map { $_->[0] } @{ $model->{unique_constraints}{$PARENT} || [] } ], ['ab_uq'],
    '... it is the constraint';
  is_deeply $intro->table_uniq_info($PARENT), [ [ ab_uq => [qw(a b)] ] ],
    'table_uniq_info holds the constraint and not the primary key index';
}

# --- 3. nothing to do after install -----------------------------------------
{
  my $diff = eval { $deploy->diff };
  ok $diff, 'diff after install' or diag $@;
  my @ops = $diff ? @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'follow-up diff is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

done_testing;
