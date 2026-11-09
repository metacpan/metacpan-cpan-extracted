use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE, DBD::ODBC only (karr k42/k43 matrix row, measured 2026-10-17, SQL
# Server 2022 16.0.4295.3, DBD::ODBC 1.61 / tdsodbc 1.3.17). t/61 holds the same
# question for DBD::Sybase, where a handle with an open cursor breaks
# transactions (BEGIN/COMMIT/ROLLBACK go out on a second connection).
#
# Over DBD::ODBC the transaction statements go through the handle
# (begin_work, commit, rollback) and:
#
#   - a cursor opened BEFORE the transaction does not harm it: what the block
#     updates is committed on success and rolled back when the block dies.
#     Core abandons the handle on the way (a warning, once per transaction)
#     because the FreeTDS ODBC driver answers "Invalid cursor state" to the
#     transaction end; the server holds the right value either way;
#   - a second statement run while a cursor is open INSIDE the transaction is
#     refused by the driver ("Invalid cursor state", no MARS): loud, the
#     block's work is rolled back, nothing is half done;
#   - the block runs once; transaction_depth is 0 afterwards.

my ($DSN, $USER, $PASS) = @ENV{ map { "DBIO_TEST_MSSQL_ODBC_$_" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS to run this test'
  unless $DSN and defined $USER and defined $PASS;

plan skip_all => 'DBD::ODBC test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc');

{
  package T::K78::Result::Row;
  use base 'DBIO::Core';
  __PACKAGE__->table('k78_txn');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    v  => { data_type => 'varchar', size => 50, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K78::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Row => 'T::K78::Result::Row');
}

my $admin = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do('SET LOCK_TIMEOUT 10000');
$admin->do("IF OBJECT_ID('k78_txn', 'U') IS NOT NULL DROP TABLE k78_txn");
$admin->do('CREATE TABLE k78_txn (id INT PRIMARY KEY, v VARCHAR(50) NULL)');
END { eval { $admin->do("IF OBJECT_ID('k78_txn', 'U') IS NOT NULL DROP TABLE k78_txn") } if $admin }

sub server_value { ( $admin->selectrow_array('SELECT v FROM k78_txn WHERE id = 1') )[0] }

my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/;
};

my %CASE = (
  'cursor before, block commits'   => { before => 1, die => 0 },
  'cursor before, block dies'      => { before => 1, die => 1 },
  'cursor inside, block commits'   => { inside => 1, die => 0 },
  'cursor inside, block dies'      => { inside => 1, die => 1 },
  'no cursor, block dies'          => { die => 1 },
  'no cursor, block commits'       => { die => 0 },
);

for my $name (sort keys %CASE) {
  my $case = $CASE{$name};

  $admin->do('DELETE FROM k78_txn');
  $admin->do("INSERT INTO k78_txn VALUES (1, 'a'), (2, 'b'), (3, 'c')");

  my $schema = T::K78::Schema->connect($DSN, $USER, $PASS);
  my $rs     = $schema->resultset('Row');
  $schema->storage->ensure_connected;

  my $open = $case->{before} ? do { my $c = $rs->search({}, { order_by => 'id' }); $c->next; $c } : undef;

  my ($runs, $before) = (0, scalar @warnings);
  my $result = eval {
    $schema->txn_do(sub {
      $runs++;
      my $inner;
      if ($case->{inside}) { $inner = $rs->search({}, { order_by => 'id' }); $inner->next }
      $rs->find(1)->update({ v => 'changed' });
      die "block dies\n" if $case->{die};
      return 'done';
    });
  };
  my $error = $@;

  is $runs, 1, "$name: the block runs once";

  if ($case->{inside}) {
    like $error, qr/Invalid cursor state/,
      "$name: the statement beside an open cursor is refused by the driver, loudly";
    is server_value(), 'a', "$name: ... and the block's work is rolled back";
  }
  elsif ($case->{die}) {
    like $error, qr/block dies/, "$name: the block's exception comes through";
    is server_value(), 'a', "$name: ... and its UPDATE is rolled back";
  }
  else {
    is $error, '', "$name: no error";
    is server_value(), 'changed', "$name: the UPDATE is committed (seen from another session)";
  }

  is $schema->storage->transaction_depth, 0, "$name: transaction_depth is 0 afterwards";

  my @new = splice @warnings, $before;
  if ($case->{before}) {
    ok scalar(grep { /Retrying on a new connection/ } @new),
      "$name: core says it abandoned the handle (the driver refuses the transaction end of a handle with an open cursor)";
  }
  elsif (not $case->{inside}) {
    is_deeply \@new, [], "$name: no warning";
  }

  # the storage goes on
  lives_ok { $rs->find(2)->update({ v => "after $name" }) } "$name: the next statement runs";
}

done_testing;
