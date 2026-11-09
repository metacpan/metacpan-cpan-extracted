use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k57, k48, k63, k39), DBD::Sybase only: the NoBindVars class,
# DBIO::MSSQL::Storage::Sybase::NoBindVars(::FreeTDS). This server takes
# placeholders on every TDS version tried, so the class is reached by telling
# the storage not to use them before its first use (as t/60 part B3 does).
#
#   k57  populate in void context threw core's "Unable to invoke fast-path
#        insert without storage placeholder support" for every data set.
#        Now: row by row in one transaction, the rows are in the table, and a
#        row the server refuses rolls the whole data set back.
#
#   k48  Storage pinned to ::Sybase directly, with a storage layer on the
#        schema: the decision was never taken (the class is a synthesised
#        one). Now it is, and the layer is still on the storage.
#
#   k63  An empty string for an INT column goes into core's literal unquoted:
#        "VALUES ( )", refused by the server (Msg 102). Loud, no row, the
#        connection goes on. Pinned, not changed: core's literal is the one
#        place that knows a number from a string, and "an empty string is no
#        number" is core's to decide for every NoBindVars driver
#        (maint/upstream/core-nobindvars-empty-number.md).
#
#   k39  The key of a new row on this class is the row's own, also on a table
#        whose INSERT trigger writes to a second IDENTITY table (as t/60 part
#        C holds for the placeholder class): SCOPE_IDENTITY() in the batch,
#        not @@IDENTITY. Measured with FreeTDS 1.3.17 only; no other version
#        was tried, and no version limit is assumed. Mutation check, done by
#        hand: SCOPE_IDENTITY() -> @@IDENTITY in _prep_for_execute makes the
#        trigger-table key 1000 instead of 1.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MSSQL_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase');

unless (eval { require DBIO::Sybase::Storage; 1 }) {
  die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
  plan skip_all => 'Test needs DBIO::Sybase (optional, cpanfile recommends)';
}

require DBIO::MSSQL::Storage::Sybase;

local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

{
  package T::K72::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k72_live_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 60, is_nullable => 1 },
    num   => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K72::Result::Trig;
  use base 'DBIO::Core';
  __PACKAGE__->table('k72_live_trig');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 60, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K72::Layer;
  sub t72_layer { 'layered' }
}

{
  package T::K72::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K72::Result::Doc');
  __PACKAGE__->register_class(Trig => 'T::K72::Result::Trig');
}

{
  package T::K72::Pinned;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::MSSQL::Storage::Sybase');
  __PACKAGE__->register_class(Doc => 'T::K72::Result::Doc');
  __PACKAGE__->register_class(Trig => 'T::K72::Result::Trig');
}

{
  package T::K72::PinnedLayered;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::MSSQL::Storage::Sybase');
  __PACKAGE__->register_storage_layer('T::K72::Layer');
  __PACKAGE__->register_class(Doc => 'T::K72::Result::Doc');
  __PACKAGE__->register_class(Trig => 'T::K72::Result::Trig');
}

my $admin = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$admin->do('SET LOCK_TIMEOUT 10000');

sub drop_all {
  $admin->do("IF OBJECT_ID('k72_live_trig_ai', 'TR') IS NOT NULL DROP TRIGGER k72_live_trig_ai");
  $admin->do("IF OBJECT_ID('$_', 'U') IS NOT NULL DROP TABLE $_")
    for qw(k72_live_doc k72_live_trig k72_live_audit);
}

sub fresh_table {
  drop_all();
  $admin->do($_) for (
    'CREATE TABLE k72_live_trig (id INT IDENTITY PRIMARY KEY, name VARCHAR(60) NULL)',
    'CREATE TABLE k72_live_audit (id INT IDENTITY(1000,1) PRIMARY KEY, trig_id INT)',
    'CREATE TRIGGER k72_live_trig_ai ON k72_live_trig AFTER INSERT AS'
  . ' INSERT INTO k72_live_audit (trig_id) SELECT id FROM inserted',
  );
  $admin->do(
    'CREATE TABLE k72_live_doc (id INT IDENTITY PRIMARY KEY, '
  . 'title VARCHAR(60) NULL, num INT NULL)'
  );
}

sub titles {
  return join ',', map { $_->[0] }
    @{ $admin->selectall_arrayref('SELECT title FROM k72_live_doc ORDER BY id') };
}

sub no_placeholders {
  my $class = shift;
  my $schema  = $class->connect($dsn, $user, $pass);
  my $storage = $schema->storage;

  # Set, not read: reading the capability would connect to detect it.
  $storage->_use_typeless_placeholders(0);
  $storage->dbh;

  return $schema;
}

my $NOBINDVARS = 'DBIO::Storage::DBI::NoBindVars';

for my $case (
  [ declared       => 'T::K72::Declared',      0 ],
  [ pinned         => 'T::K72::Pinned',        0 ],
  [ 'pinned+layer' => 'T::K72::PinnedLayered', 1 ],
) {
  my ($way, $class, $layered) = @$case;

  fresh_table();
  my $schema  = no_placeholders($class);
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Doc');

  # ------------------------------------------------------------- k48
  ok $storage->isa($NOBINDVARS),
    "$way: told not to use placeholders, the storage is a NoBindVars class";
  ok $storage->isa('DBIO::Sybase::Storage::FreeTDS'),
    "$way: ... with the FreeTDS class mixed in";
  is +( $storage->can('t72_layer') ? $storage->t72_layer : undef ),
    ( $layered ? 'layered' : undef ),
    "$way: ... the layer of the schema is " . ( $layered ? 'kept' : 'not there' );

  my @traced;
  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(1);
  my $first = $rs->create({ title => q{o'brien} });
  $storage->debug(0);
  $storage->debugcb(undef);

  like $traced[0], qr/VALUES \('o''brien'\)/,
    "$way: the value is in the statement, no placeholder on the wire";
  is titles(), q{o'brien}, "$way: ... and arrives";

  # ------------------------------------------------------------- k39
  is $first->id, 1, "$way: create() returns the row's own key";
  like $traced[0], qr/SCOPE_IDENTITY\(\)/,
    "$way: ... asked for with SCOPE_IDENTITY() in the batch";
  unlike $traced[0], qr/\@\@identity/i, "$way: ... not with \@\@IDENTITY";

  my $trig = $schema->resultset('Trig')->create({ name => 'with trigger' });
  is $trig->id, 1,
    "$way: ... also where an INSERT trigger writes to a second IDENTITY table";
  is_deeply
    $admin->selectall_arrayref('SELECT id, trig_id FROM k72_live_audit'),
    [ [ 1000, 1 ] ],
    "$way: ... (the trigger fired: its row is 1000, the identities differ)";
  is $schema->resultset('Trig')->create({ name => 'second' })->id, 2,
    "$way: ... and the next key is the next";

  # ------------------------------------------------------------- k57
  lives_ok {
    $rs->populate([
      { title => 'p1', num => 1 },
      { title => 'p2', num => 2 },
      { title => 'p3', num => 3 },
    ]);
  } "$way: populate in void context does not throw";
  is titles(), q{o'brien,p1,p2,p3}, "$way: ... all rows are in the table";

  throws_ok {
    $rs->populate([
      { title => 'q1', num => 1 },
      { title => 'q2', num => 2 },
      { title => 'q3', num => 3 },
      { title => 'q4', num => 2147483648 },      # beyond INT: the server refuses
    ]);
  } qr/overflow|arithmetic|Msg 8115|8115|converting/i,
    "$way: a row the server refuses throws";
  is titles(), q{o'brien,p1,p2,p3},
    "$way: ... and none of that data set is in the table (one transaction)";
  is $storage->transaction_depth, 0, "$way: ... the connection is out of it";

  lives_ok { $rs->create({ title => 'after' }) }
    "$way: ... and goes on";
  is $rs->count, 5, "$way: ... counting its rows";

  # ------------------------------------------------------------- k63
  my $before = $rs->count;

  throws_ok { $rs->create({ title => 'empty int', num => '' }) }
    qr/Msg 102|Incorrect syntax|syntax/i,
    "$way: '' for an INT column is refused by the server, loudly (Msg 102)";
  is $rs->count, $before, "$way: ... no row was written";

  lives_ok { $rs->create({ title => 'again' }) }
    "$way: ... and the connection is usable";
}

drop_all();

done_testing;
