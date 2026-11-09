use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;

# LIVE (karr k82). The counterpart of t/82-lob-only-update-rowcount.t.
#
# CLAIMED, against a table with TEXT and IMAGE columns:
#
#   1. $row->update of the LOB columns to the empty string or to undef, and
#      nothing else, lives (it is one UPDATE; the row count comes through),
#      and the server holds a space / 0x20, or NULL.
#   2. $rs->update of the same returns the number of rows hit: 2 for two
#      rows, a count of 0 (DBI's "0E0") for none.
#   3. $row->update of a row that is gone dies "row not found".
#
# NOT claimed: LOB content alone. FreeTDS cannot write it (ct_data_info), so
# that case is only offline (t/82). Not run against Open Client.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $TABLE = "dbio_k82_lob_$$";

{
  package T::K82L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    tag     => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K82L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K82L::Result::Lob');
}

my $raw = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$raw->do('set lock wait 10');

my $live = 1;

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id      INT IDENTITY PRIMARY KEY,
  c_image IMAGE NULL,
  c_text  TEXT NULL,
  tag     VARCHAR(40) NULL
)
SQL

sub add_row {
  my $tag = shift;
  $raw->do("INSERT INTO $TABLE (c_image, c_text, tag) VALUES (0x010203, 'before', '$tag')");
  return ( $raw->selectrow_array("select max(id) from $TABLE") )[0];
}

sub held {
  my $where = shift;
  return $raw->selectall_arrayref(
    "select convert(varchar(30), c_text), bintostr(convert(varbinary(30), c_image)) "
  . "from $TABLE where $where order by id"
  );
}

my $schema = T::K82L::Schema->connect($dsn, $user, $pass, {
  on_connect_do => [ 'set lock wait 10' ],
});
my $rs = $schema->resultset('Lob');

for my $case (
  [ 'empty', 'the empty string', '',    [ ' ', '20' ] ],
  [ 'undef', 'undef',            undef, [ undef, undef ] ],
) {
  my ($key, $what, $value, $expected) = @$case;

  my $id  = add_row("row$key");
  my $row = $rs->find($id);
  my $ok  = eval { $row->update({ c_text => $value, c_image => $value }); 1 };
  ok $ok, "\$row->update of both LOB columns to $what, nothing else, lives"
    or diag $@;
  is_deeply held("id = $id"), [ $expected ], '... and the server holds the new value';
  ok !$row->get_dirty_columns, '... and the object is clean';

  add_row("rs$key") for 1, 2;
  is $rs->search({ tag => "rs$key" })->update({ c_text => $value, c_image => $value }), 2,
    "\$rs->update of both LOB columns to $what returns the 2 rows it hit";
  is_deeply held("tag = 'rs$key'"), [ $expected, $expected ], '... and both hold it';

  is 0 + $rs->search({ tag => 'nobody' })->update({ c_text => $value }), 0,
    "\$rs->update to $what that hits no row returns a count of 0";

  my $gone = $rs->find(add_row("gone$key"));
  $raw->do("DELETE FROM $TABLE WHERE id = " . $gone->id);
  ok !eval { $gone->update({ c_text => $value }); 1 } && $@ =~ /not found/,
    "\$row->update to $what of a row that is gone: row not found";
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
