use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k62), over each access path that has a server to talk to:
#
#   DBD::Sybase   $ENV{DBIO_TEST_MSSQL_DSN}, _USER, _PASS
#   DBD::ODBC     $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER, _PASS
#
# The card said: after a populate in void context whose statement the server
# refuses, the storage stayed in "deferred rollback" and every further
# operation on the connection threw. Measured 2026-10-17 (MSSQL 2022
# 16.0.4295.3, DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 / tdsodbc
# 1.3.17), one failing statement on one connection, plain DBI first:
#
#   * The server rolls the WHOLE transaction back on Msg 8114 (a bound value
#     that cannot be converted: 'abc' for a DECIMAL): @@TRANCOUNT goes from 1
#     to 0 on the failing statement, over both DBDs, and the rows inserted
#     before it in that transaction are gone. A ROLLBACK after it is refused
#     (Msg 3903, no corresponding BEGIN) -- the transaction DBIO believes it
#     holds (transaction_depth 1) is already gone. That mismatch is what the
#     card saw as a connection that could not be used; core's discard of a
#     handle whose rollback failed (core k303, 2026-10-13) makes the
#     connection usable again, which is pinned below as the second half.
#
#   * What was NOT fine, and is the driver's: core's fast path executes the
#     rows with execute_for_fetch, which DBI runs to the END of the data
#     after a failing tuple. The tuples after the failing one therefore ran
#     with no transaction, in autocommit, and were COMMITTED, while the ones
#     before it were rolled back with the transaction: populate([ good, bad,
#     good ]) threw and left the third row. The storage now stops the
#     fast path at the first failing tuple
#     (DBIO::MSSQL::Storage::StopAtFirstError); nothing of the data set is
#     left.

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %WAY;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $WAY{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or '
  . '$ENV{DBIO_TEST_MSSQL_ODBC_DSN}, with _USER and _PASS, to run this test'
  unless %WAY;

if ($WAY{'DBD::Sybase'}) {
  if (not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase')) {
    delete $WAY{'DBD::Sybase'};
  }
  elsif (not eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
    delete $WAY{'DBD::Sybase'};
  }
}

delete $WAY{'DBD::ODBC'}
  if $WAY{'DBD::ODBC'}
    and not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc');

plan skip_all => 'Neither access path has what it needs installed' unless %WAY;

my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

{
  package T::K74::Result::Price;
  use base 'DBIO::Core';
  __PACKAGE__->table('k74_live_price');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    label  => { data_type => 'varchar', size => 20, is_nullable => 1 },
    amount => { data_type => 'decimal', size => [10, 2], is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K74::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Price => 'T::K74::Result::Price');
}

my %ADMIN;
sub admin {
  my $way = shift;
  return $ADMIN{$way} ||= do {
    my $dbh = DBI->connect(@{ $WAY{$way} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

sub fresh_table {
  my $way = shift;
  admin($way)->do("IF OBJECT_ID('k74_live_price', 'U') IS NOT NULL DROP TABLE k74_live_price");
  admin($way)->do(
    'CREATE TABLE k74_live_price (id INT IDENTITY PRIMARY KEY, '
  . 'label VARCHAR(20) NULL, amount DECIMAL(10,2) NULL)'
  );
}

sub labels {
  my $way = shift;
  return join ',', map { $_->[0] }
    @{ admin($way)->selectall_arrayref('SELECT label FROM k74_live_price ORDER BY id') };
}

for my $way (sort keys %WAY) {
  fresh_table($way);

  my $schema  = T::K74::Schema->connect(@{ $WAY{$way} });
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Price');

  $storage->ensure_connected;

  # A control, on a connection of its own and plain DBI: the server really
  # does roll the transaction back (what the rest of this file rests on).
  {
    my $dbh = DBI->connect(@{ $WAY{$way} }, {
      RaiseError => 0, PrintError => 0, AutoCommit => 1,
    });
    my $trancount = sub { ($dbh->selectrow_array('SELECT @@TRANCOUNT'))[0] };

    $dbh->do('BEGIN TRAN');
    $dbh->do(q{INSERT INTO k74_live_price (label, amount) VALUES ('ctl', 1)});
    is $trancount->(), 1, "$way: (control) a transaction is open";

    $dbh->prepare('INSERT INTO k74_live_price (amount) VALUES (?)')->execute('abc');
    is $trancount->(), 0,
      "$way: (control) the server has rolled the whole transaction back on "
    . 'Msg 8114: DBIO would still say depth 1 in such a transaction';

    ok !$dbh->do('ROLLBACK'),
      "$way: (control) ... and a ROLLBACK after it is refused (Msg 3903)";
    is labels($way), '', "$way: (control) the row before it is gone";
    $dbh->disconnect;
  }

  # ---------------------------------------------- the fast path is atomic
  throws_ok {
    $rs->populate([
      { label => 'good1', amount => '1.00' },
      { label => 'bad',   amount => 'abc'  },
      { label => 'good2', amount => '3.00' },
    ]);
  } qr/8114|converting/i,
    "$way: populate in void context with a value the server refuses throws";

  is labels($way), '',
    "$way: ... and NOTHING of the data set is in the table: the rows after "
  . 'the failing one did not run on their own, outside the transaction';

  # ----------------------------------------- the connection goes on (core k303)
  is $storage->transaction_depth, 0, "$way: ... the storage is out of the transaction";
  ok !$storage->deferred_rollback, "$way: ... not in deferred rollback";

  lives_ok { $rs->create({ label => 'after', amount => '2.50' }) }
    "$way: ... a statement on the same storage works";
  lives_ok { $rs->populate([ { label => 'p1' }, { label => 'p2' } ]) }
    "$way: ... so does a populate";
  lives_ok { $schema->txn_do(sub { $rs->create({ label => 'in txn' }) }) }
    "$way: ... and a transaction";
  is labels($way), 'after,p1,p2,in txn', "$way: ... and the rows arrive";

  # ---------------------------------------------------- a failure at once
  throws_ok { $rs->populate([ { label => 'x', amount => 'abc' } ]) }
    qr/8114|converting/i, "$way: a data set whose first row is refused throws";
  is labels($way), 'after,p1,p2,in txn', "$way: ... and adds nothing";
  lives_ok { $rs->create({ label => 'still' }) } "$way: ... the connection goes on";

  # --------------------- the row-by-row path (Sybase: '' / long / binary values)
  throws_ok {
    $rs->populate([
      { label => 'r1', amount => '1.00' },
      { label => '',   amount => 'abc'  },
      { label => 'r3', amount => '3.00' },
    ]);
  } qr/8114|converting/i,
    "$way: a data set the row-by-row path takes throws as well";
  is labels($way), 'after,p1,p2,in txn,still',
    "$way: ... and adds nothing";
  lives_ok { $rs->create({ label => 'last' }) } "$way: ... the connection goes on";
}

$_->do("IF OBJECT_ID('k74_live_price', 'U') IS NOT NULL DROP TABLE k74_live_price")
  for values %ADMIN;

done_testing;
