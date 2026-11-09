use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;

# LIVE (karr k67). The counterpart of t/86-populate-first-action.t. A schema
# whose storage is pinned to DBIO::Sybase::Storage::ASE ran populate() in void
# context as its first action (no dbh yet) into "Can't call method
# "txn_scope_guard" on an undefined value": the writer storage is made at the
# first connect.
#
# CLAIMED, on a fresh schema of each kind, populate() being the first thing it
# does: it lives, the rows are in the table (the non-LOB column as given, the
# LOB column NULL for undef and not NULL for ''), and create() with a LOB
# column and update of one as first action live as well.
#
# Content of a LOB is not written here (FreeTDS cannot, t/68).
#
# Makes one table in the database of the DSN, named after this process, and
# drops it.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $TABLE = "dbio_k67_lob_$$";

{
  package T::K67L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    c_text => { data_type => 'text', is_nullable => 1 },
    name   => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K67L::Pinned;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
  __PACKAGE__->register_class(Lob => 'T::K67L::Result::Lob');
}

{
  package T::K67L::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K67L::Result::Lob');
}

my $raw = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$raw->do('set lock wait 10');

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id     INT IDENTITY PRIMARY KEY,
  c_text TEXT NULL,
  name   VARCHAR(40) NULL
)
SQL

sub rows_of {
  return $raw->selectall_arrayref(
    "select name, case when c_text is null then 'NULL' else 'SET' end "
  . "from $TABLE where name like ? order by id", undef, "$_[0]%"
  );
}

for my $kind (qw(Pinned Declared)) {
  my $class  = "T::K67L::$kind";
  my $schema = $class->connect($dsn, $user, $pass);
  my $rs     = $schema->resultset('Lob');

  ok eval {
    $rs->populate([
      [qw(name c_text)],
      [ "$kind-a", undef ],
      [ "$kind-b", ''    ],
      [ "$kind-c", undef ],
    ]);
    1;
  }, "$kind: populate() as the first action lives" or diag $@;

  is_deeply rows_of("$kind-"),
    [ [ "$kind-a", 'NULL' ], [ "$kind-b", 'SET' ], [ "$kind-c", 'NULL' ] ],
    '... the rows are in the table, the LOB column NULL for undef';

  my $schema2 = $class->connect($dsn, $user, $pass);
  my $row;
  ok eval { $row = $schema2->resultset('Lob')->create({ name => "$kind-d", c_text => undef }); 1 },
    "$kind: create() with a LOB column as the first action lives" or diag $@;

  my $schema3 = $class->connect($dsn, $user, $pass);
  ok eval {
    $schema3->resultset('Lob')->search({ name => "$kind-a" })->update({ c_text => '' });
    1;
  }, "$kind: update of a LOB column as the first action lives" or diag $@;

  is_deeply rows_of("$kind-"),
    [ [ "$kind-a", 'SET' ], [ "$kind-b", 'SET' ], [ "$kind-c", 'NULL' ],
      [ "$kind-d", 'NULL' ] ],
    '... and the table holds what was written';

  $_->storage->disconnect for $schema, $schema2, $schema3;
}

ok eval { $raw->do("DROP TABLE $TABLE"); 1 }, 'the table of this test is dropped';

done_testing;

END {
  if ($raw) {
    local $?;
    eval { $raw->do("DROP TABLE $TABLE") };
    $raw->disconnect;
  }
}
