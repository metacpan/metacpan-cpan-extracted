use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();

# LIVE (karr k34). DBIO::Oracle::Storage::WhereJoins is never chosen by the
# server version; it is reached only by declaring it as storage_type. This
# file takes that one way: connect with the class declared, and run an inner
# and a left join through the (+) dialect against a real Oracle. Oracle 23ai
# still understands (+), so the dialect is measurable even though the class
# is meant for servers older than 9.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;   # no handler: an OCI call that hangs ends the run instead of never

{
  package T::K34::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('K34_WJ_PARENT');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 30 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(kids => 'T::K34::Result::Kid', 'parent_id');
}

{
  package T::K34::Result::Kid;
  use base 'DBIO::Core';
  __PACKAGE__->table('K34_WJ_KID');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
    label     => { data_type => 'varchar', size => 30 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'T::K34::Result::Parent', 'parent_id');
}

{
  package T::K34::Schema;
  use base 'DBIO::Schema';
  # The declaration under test: the explicit storage_type, no component.
  __PACKAGE__->storage_type('+DBIO::Oracle::Storage::WhereJoins');
  __PACKAGE__->register_class(Parent => 'T::K34::Result::Parent');
  __PACKAGE__->register_class(Kid    => 'T::K34::Result::Kid');
}

my $admin = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});

sub wipe {
  for my $t (qw(K34_WJ_KID K34_WJ_PARENT)) {
    my ($n) = $admin->selectrow_array(
      'SELECT COUNT(*) FROM user_tables WHERE table_name = ?', undef, $t);
    $admin->do(qq{DROP TABLE "$t" PURGE}) if $n;
  }
}

wipe();
END { wipe() if $admin }

$admin->do('CREATE TABLE "K34_WJ_PARENT" ("id" NUMBER(10) PRIMARY KEY, "name" VARCHAR2(30) NOT NULL)');
$admin->do('CREATE TABLE "K34_WJ_KID" ("id" NUMBER(10) PRIMARY KEY, "parent_id" NUMBER(10) NOT NULL, "label" VARCHAR2(30) NOT NULL)');

my $schema = T::K34::Schema->connect($dsn, $user, $pass);

$schema->resultset('Parent')->create({ id => $_->[0], name => $_->[1] })
  for [1 => 'with_kids'], [2 => 'childless'];
$schema->resultset('Kid')->create({ id => $_->[0], parent_id => 1, label => $_->[1] })
  for [10 => 'a'], [11 => 'b'];

isa_ok $schema->storage, 'DBIO::Oracle::Storage::WhereJoins',
  'explicit storage_type is the storage after connecting';
is $schema->storage->sql_maker_class, 'DBIO::Oracle::SQLMaker::Joins',
  'with the (+) SQL maker';

sub pairs {
  my ($rs) = @_;
  return [ $rs->cursor->all ];
}

# Inner join (belongs_to on a NOT NULL column): a kid and its parent.
{
  my $rs = $schema->resultset('Kid')->search({}, {
    join     => 'parent',
    columns  => ['parent.name', 'me.label'],
    order_by => 'me.label',
  });
  my ($sql) = @${ $rs->as_query };
  unlike $sql, qr/\bJOIN\b/i, 'inner join: no ANSI JOIN in the SQL';
  unlike $sql, qr/\(\+\)/, 'inner join: no (+)';
  like $sql, qr/WHERE \( "parent"."id" = "me"."parent_id" \)/, 'inner join: condition in WHERE';
  is_deeply pairs($rs), [ [with_kids => 'a'], [with_kids => 'b'] ],
    'inner join returns the matching rows';
}

# Left join: the childless parent is kept, with NULL label.
{
  my $rs = $schema->resultset('Parent')->search({}, {
    join     => 'kids',
    columns  => ['me.name', 'kids.label'],
    order_by => ['me.id', 'kids.label'],
  });
  my ($sql) = @${ $rs->as_query };
  like $sql, qr/\(\+\)/, 'left join: (+) in the SQL';
  unlike $sql, qr/\bJOIN\b/i, 'left join: no ANSI JOIN in the SQL';
  is_deeply pairs($rs), [ [with_kids => 'a'], [with_kids => 'b'], [childless => undef] ],
    'left join keeps the parent without kids';
}

done_testing;
