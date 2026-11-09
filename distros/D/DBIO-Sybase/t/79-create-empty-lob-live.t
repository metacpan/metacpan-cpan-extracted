use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;

# LIVE (karr k80, k84). The counterpart of t/78-create-empty-lob.t.
#
# CLAIMED, against a table with TEXT and IMAGE columns that have a DEFAULT:
#
#   1. create({}) lives (under FreeTDS it died in _insert_blobs, because the
#      DEFAULT literal was taken for LOB content) and the columns hold their
#      DEFAULT on the server.
#   2. The row object holds the primary key and no other column: no SCALAR
#      ref, has_column_loaded false for each, nothing dirty.
#   3. discard_changes reads the defaults.
#
# Writing a LOB's content is not asked here (FreeTDS cannot).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $TABLE = "dbio_k80_lob_$$";

{
  package T::K80L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K80L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K80L::Result::Lob');
}

my $raw = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$raw->do('set lock wait 10');

my $live = 1;

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id      INT IDENTITY PRIMARY KEY,
  c_image IMAGE DEFAULT 0x0102 NULL,
  c_text  TEXT DEFAULT 'dflt' NULL,
  name    VARCHAR(40) DEFAULT 'nm' NULL
)
SQL

sub held {
  my $id = shift;
  return $raw->selectall_arrayref(
    "select convert(varchar(30), c_text), bintostr(convert(varbinary(30), c_image)), name "
  . "from $TABLE where id = $id"
  )->[0];
}

my $schema = T::K80L::Schema->connect($dsn, $user, $pass);
my $rs     = $schema->resultset('Lob');

for my $how ('outside a transaction', 'in a transaction') {
  $schema->txn_begin if $how eq 'in a transaction';

  my $row;
  my $ok = eval { $row = $rs->create({}); 1 };
  ok $ok, "create({}) $how lives" or diag $@;

 SKIP: {
    skip 'no row', 6 unless $ok;

    my $id = $row->id;
    ok $id, '... and the row has its identity';

    is_deeply { $row->get_columns }, { id => $id },
      '... the object holds the primary key and nothing else';
    ok !$row->has_column_loaded($_), "... $_ is not loaded"
      for qw(c_image c_text name);
    ok !$row->is_changed, '... nothing is dirty';

    $schema->txn_commit if $how eq 'in a transaction';

    is_deeply held($id), [ 'dflt', '0102', 'nm' ],
      '... the server holds the DEFAULT of every column, the LOB columns too';

    $row->discard_changes;
    is_deeply [ map { $row->get_column($_) } qw(c_text name) ], [ 'dflt', 'nm' ],
      '... and discard_changes reads them';
  }
  $schema->txn_rollback if $how eq 'in a transaction' and $schema->storage->transaction_depth;
}

$schema->storage->disconnect;

ok eval { $raw->do("DROP TABLE $TABLE"); 1 }, 'the table of this test is dropped';

done_testing;

END {
  if ($live && $raw) {
    local $?;
    eval { $raw->do("DROP TABLE $TABLE") };
    $raw->disconnect;
  }
}
