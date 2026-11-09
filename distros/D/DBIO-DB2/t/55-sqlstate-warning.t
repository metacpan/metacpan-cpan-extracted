use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::DB2::Storage;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k43, ADR 0007). DBD::DB2 reports a server WARNING the way it
# reports an error. On SQL_SUCCESS_WITH_INFO it sets err to a true value where
# the DBI contract has "0" or "" for a warning, so with RaiseError and core's
# HandleError the statement that just ran becomes an exception. Measured
# against Db2 12.1.5 with DBD::DB2 1.92:
#
#   DELETE FROM "t"     rv 3, err 513, state 01504,
#                       SQL0513W The SQL statement will modify an entire table
#                       or view -- and the three rows are gone
#
# In a txn_do the exception rolls back a statement that succeeded. SQLSTATE
# says which of the two a message is: class 01 is "completed, with a warning",
# and nothing else is. So DBIO::DB2::Storage wraps the HandleError core installs
# and answers a class 01 message as handled; every other state goes to core's
# handler unchanged.
#
# What this file pins, on a real DBI handle (DBD::NullP, shipped with DBI), with
# $h->set_err($err, $errstr, $state, $method, $rv) standing in for the DBD --
# set_err runs the very dispatch a failing DBD method runs, HandleError and
# RaiseError included:
#
#   1. a class 01 message does not throw, and the caller gets the method's
#      return value -- on a database handle, a statement handle and through
#      dbh_do; err, state and errstr stay readable on the handle;
#   2. anything that is not class 01 still throws core's "DBI Exception: ..."
#      as a DBIO::Exception: an error class (42), no state at all (DBI reports
#      S1000), and class 02 -- "no data" is not a warning;
#   3. a class 01 message beside an undef return value is still not an
#      exception from the handler: the SQLSTATE class is the server's word on
#      the outcome, and undef is a legitimate value for several DBI methods
#      (fetchrow_array of a NULL). Where DBIO itself needs a true value --
#      _dbh_execute after execute -- core still throws on the false one;
#   4. every way a handle comes into being runs through the seam: DSN connect,
#      connection coderef, AccessBroker, and a second _connect over a handle
#      that already carries the wrapper (it keeps core's blessing, so core does
#      not refuse it as a foreign handler);
#   5. with unsafe => 1 nothing is installed and a handler of the user's is
#      left where it is -- there the user owns the error handling.
#
# Whether Db2 raises 01504 at all, and what is left in the table, is not
# provable offline: t/56-sqlstate-warning-live.t.

{
  package T::DB2::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}

my $HANDLER_CLASS = '__DBIO__DBH__ERROR__HANDLER__';

my $WARNING = 'SQL0513W  The SQL statement will modify an entire table or view.';
my $ERROR   = 'SQL0204N  "DB2INST1.nope" is an undefined name.';

# The schema declares DB2 and the DSN says DB2, so nothing here is a driver
# mismatch; only the handle DBI->connect hands back is DBD::NullP's.
my $dbi_connect = \&DBI::connect;

sub null_dbh {
  return $dbi_connect->('DBI', 'dbi:NullP:', '', '', {
    AutoCommit => 1, PrintError => 0, RaiseError => 1, %{ $_[0] || {} },
  });
}

sub storage_for {
  my $storage = T::DB2::Schema->connect(@_)->storage;
  no warnings qw(redefine once);
  local *DBI::connect = sub {
    my ($class, undef, @rest) = @_;
    return $dbi_connect->($class, 'dbi:NullP:', @rest);
  };
  $storage->ensure_connected;
  return $storage;
}

my @DSN = ('dbi:DB2:SAMPLE', 'db2inst1', 's3cret');

# -------------------------------------------- 1. class 01 is not an exception

{
  my $storage = storage_for(@DSN);
  my $dbh = $storage->dbh;

  is ref $storage, 'DBIO::DB2::Storage', 'the storage under test is the DB2 one';

  my $rv;
  lives_ok { $rv = $dbh->set_err(513, $WARNING, '01504', 'do', 3) }
    'SQLSTATE 01504 on a database handle is not an exception';
  is $rv, 3, '... and the caller gets the return value: the three rows the '
           . 'statement changed';

  is $dbh->state,  '01504',  '... the state stays readable on the handle';
  is $dbh->err,    513,      '... and so does err';
  is $dbh->errstr, $WARNING, '... and errstr';
}

{
  my $storage = storage_for(@DSN);
  my $sth = $storage->dbh->prepare('DELETE FROM "t"');

  my $rv;
  lives_ok { $rv = $sth->set_err(513, $WARNING, '01504', 'execute', 3) }
    'SQLSTATE 01504 on a statement handle is not an exception -- the handler '
  . 'is inherited from the database handle';
  is $rv, 3, '... and execute answers the row count';
}

{
  my $storage = storage_for(@DSN);

  my $rv;
  lives_ok {
    $rv = $storage->dbh_do(sub { $_[1]->set_err(513, $WARNING, '01504', 'do', 3) });
  } 'raw SQL through dbh_do: a class 01 message does not throw';
  is $rv, 3, '... and dbh_do returns what the statement returned';
}

{
  my $storage = storage_for(@DSN);

  lives_ok { $storage->dbh->set_err(445, 'SQL0445W  Value has been truncated.', '01004', 'do', 1) }
    'the rule is the class, not the one state measured: 01004 passes as well';
}

# --------------------------------------------- 2. everything else still throws

{
  my $storage = storage_for(@DSN);

  throws_ok { $storage->dbh->set_err(-204, $ERROR, '42S02', 'do') }
    qr/DBI Exception: .*SQL0204N/,
    'an error class (42S02) still throws, through core\'s handler';
  isa_ok $@, 'DBIO::Exception', '... the exception';
}

{
  my $storage = storage_for(@DSN);

  throws_ok { $storage->dbh->set_err(-1, 'no state given', undef, 'do') }
    qr/DBI Exception: .*no state given/,
    'an error without a state (DBI answers S1000) still throws';
}

{
  my $storage = storage_for(@DSN);

  throws_ok { $storage->dbh->set_err(100, 'SQL0100W  No row was found.', '02000', 'do') }
    qr/DBI Exception: .*SQL0100W/,
    'class 02 still throws: only class 01 means "completed, with a warning"';
}

{
  my $storage = storage_for(@DSN);

  throws_ok { $storage->dbh_do(sub { $_[1]->set_err(-204, $ERROR, '42S02', 'do') }) }
    qr/DBI Exception: .*SQL0204N/,
    'raw SQL through dbh_do: an error still throws';
}

# ------------------------------------- 3. class 01 beside an undef return value

{
  my $storage = storage_for(@DSN);
  my $dbh = $storage->dbh;

  my @rv = ('not called');
  lives_ok { @rv = $dbh->set_err(513, $WARNING, '01504', 'selectrow_array') }
    'class 01 beside an undef return value is not an exception either: the '
  . 'state is the server\'s word on the outcome, and undef is what a NULL '
  . 'looks like';
  is_deeply \@rv, [ undef ], '... the undef is passed on as it is';
}

{
  my $storage = storage_for(@DSN);

  # the DBD's execute, answering false and a class 01 state
  no warnings qw(redefine once);
  local *DBIO::DB2::Storage::_execute_sth = sub {
    my ($self, $dbh, $sth) = @_;
    return (scalar $sth->set_err(513, $WARNING, '01504', 'execute'), undef);
  };

  throws_ok { $storage->_dbh_execute($storage->dbh, 'DELETE FROM "t"', [], []) }
    qr/SQL0513W/,
    'where DBIO needs a true value -- _dbh_execute after execute -- a false '
  . 'one still throws, with the message the handle carries: no statement '
  . 'DBIO runs is taken as done on the state alone';
  isa_ok $@, 'DBIO::Exception', '... the exception';
}

# ------------------------------------------ 4. every handle runs through it

{
  my $storage = storage_for(@DSN);

  is ref $storage->dbh->{HandleError}, $HANDLER_CLASS,
    'the handler on the handle keeps core\'s blessing, which is how core '
  . 'tells its own handler from a foreign one';
}

{
  my $dbh = null_dbh();
  my $storage = storage_for(sub { $dbh });

  my $rv;
  lives_ok { $rv = $storage->dbh->set_err(513, $WARNING, '01504', 'do', 3) }
    'a handle from a connection coderef: class 01 does not throw';
  is $rv, 3, '... and the return value arrives';

  # the coderef hands the same handle out again, as a pool would
  my $again;
  lives_ok { $again = $storage->_connect }
    'a second _connect over the handle that already carries the wrapper is '
  . 'not refused as a foreign HandleError';
  is $again, $dbh, '... it is the same handle';

  $dbh->set_err(undef, undef);
  lives_ok { $rv = $again->set_err(513, $WARNING, '01504', 'do', 5) }
    '... and class 01 still does not throw on it';
  is $rv, 5, '... return value included';

  $dbh->set_err(undef, undef);
  throws_ok { $again->set_err(-204, $ERROR, '42S02', 'do') }
    qr/DBI Exception: .*SQL0204N/,
    '... while an error still does';
}

{
  my $storage = storage_for(
    DBIO::AccessBroker::Static->new(
      dbname => 'SAMPLE', username => 'db2inst1', password => 's3cret',
    ),
  );

  my $rv;
  lives_ok { $rv = $storage->dbh->set_err(513, $WARNING, '01504', 'do', 3) }
    'a handle connected through an AccessBroker: class 01 does not throw';
  is $rv, 3, '... and the return value arrives';

  # a reconnect asks the broker again and builds a new handle
  my $first = $storage->dbh;
  $storage->disconnect;
  {
    no warnings qw(redefine once);
    local *DBI::connect = sub {
      my ($class, undef, @rest) = @_;
      return $dbi_connect->($class, 'dbi:NullP:', @rest);
    };
    $storage->ensure_connected;
  }
  isnt $storage->dbh, $first, 'after a disconnect the storage holds a new handle';
  lives_ok { $rv = $storage->dbh->set_err(513, $WARNING, '01504', 'do', 7) }
    '... and class 01 does not throw on that one either';
  is $rv, 7, '... return value included';
}

# ------------------------------------------------- 5. unsafe is left alone

{
  my $storage = storage_for(@DSN, { unsafe => 1 });

  is $storage->dbh->{HandleError}, undef,
    'with unsafe => 1 no handler is installed: core installs none, and this '
  . 'driver adds none of its own';
}

{
  my $mine = sub { 0 };
  my $dbh = null_dbh({ HandleError => $mine });
  my $storage = storage_for(sub { $dbh }, { unsafe => 1 });

  is $storage->dbh->{HandleError}, $mine,
    'with unsafe => 1 a HandleError of the user\'s stays exactly the one it '
  . 'was -- not wrapped, not replaced';
}

done_testing;
