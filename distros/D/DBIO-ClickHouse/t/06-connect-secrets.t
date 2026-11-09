use strict;
use warnings;

use Test::More;

# A password must not leave this driver in an error message (karr k39). Core
# masks what it throws from the connect path (DBIO::Util::mask_connect_secrets);
# this driver's own code may not hand the DSN and the secrets around unmasked.
#
# Audit result, lib/ as of k39: every throw_exception / croak / die / warn
# either carries no connection data (SQLMaker, Native, Result, Diff, DDL, the
# txn hooks) or rethrows the original error unchanged (Storage::txn_do,
# Deploy via core's TempDatabase, whose connects run in core). The one place
# that built a message out of DSN and DBI's own connect error is
# DBIO::ClickHouse::Test::_admin_dbh, which is what the first block pins.
#
# Offline: nothing connects; DBI::connect is replaced by a stand-in that fails
# the way a DBD does -- with the connect arguments in the text.

use DBIO::ClickHouse::Test;

my $PASSWORD     = 'Zx9-hunter2-QQ';
my $DSN_PASSWORD = 'dsnSecret-8841';
my $DSN = "dbi:mysql:database=default;host=127.0.0.1;port=9004;password=$DSN_PASSWORD";

# --- the test harness's admin connection --------------------------------------
{
  no warnings 'redefine';
  local *DBI::connect = sub {
    my ($class, $dsn, $user, $pass) = @_;
    die "DBI connect('$dsn','$user',...) failed: Access denied for user "
      . "'$user' (using password: YES, '$pass')\n";
  };

  my $error;
  eval { DBIO::ClickHouse::Test->_admin_dbh($DSN, 'ch', $PASSWORD); 1 }
    or $error = $@;

  ok defined $error, 'a failing admin connect throws';
  unlike $error, qr/\Q$PASSWORD\E/, '... without the password argument in it';
  unlike $error, qr/\Q$DSN_PASSWORD\E/, '... and without a password written into the DSN';
  like $error, qr/127\.0\.0\.1/, '... while still saying where it tried to connect';
}

# --- the storage's own connect path stays masked (core's, pinned here) --------
{
  my $schema = DBIO::ClickHouse::Test::Schema->connect(
    'dbi:NoSuchDBDForK39:host=127.0.0.1;port=9004', 'ch', $PASSWORD,
  );

  my $error;
  local $SIG{__WARN__} = sub { };
  eval { $schema->storage->ensure_connected; 1 } or $error = $@;

  ok defined $error, 'connecting through an unusable DBD throws';
  unlike "$error", qr/\Q$PASSWORD\E/,
    '... and the storage connect path does not carry the password either';
}

done_testing;
