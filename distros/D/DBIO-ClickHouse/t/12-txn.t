use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);

# Offline test for the ClickHouse no-transaction policy (ADR 0003).
#
# No DBI, no DSN, no server. txn_do never touches a handle at all; txn_begin /
# txn_commit run core's connection bookkeeping, so the storage gets a two-line
# fake $dbh that answers the only thing core asks it here (an attribute FETCH).
# Nothing in this file connects.

use DBIO::ClickHouse::Storage;

{
  # Stand-in for a live $dbh. Core only FETCHes attributes (Active,
  # AutoCommit) on this path - both are true for a ClickHouse connection.
  package MyTest::CH::DBH;
  sub FETCH { 1 }
}

sub ch_storage {
  my $storage = DBIO::ClickHouse::Storage->new;
  $storage->_dbh(bless {}, 'MyTest::CH::DBH');
  $storage->_dbh_autocommit(1);
  # We instantiated the concrete driver storage directly, so there is nothing
  # left to detect - this keeps core's "determine driver first" wrapper around
  # txn_begin from trying to connect.
  $storage->_driver_determined(1);
  return $storage;
}

# The two no-op warnings use carp_once, i.e. once per interpreter per message.
# The blocks that count warnings must therefore come before any other use of
# the same path in this file. Order below is deliberate.

# --- txn_do runs the coderef, unwrapped -------------------------------------
{
  my $storage = ch_storage();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my @got_args;
  my @list = $storage->txn_do(sub { @got_args = @_; return (1, 2, 3) }, 'a', 'b');

  is_deeply \@list, [1, 2, 3],
    'txn_do passes the coderef return value through in list context';
  is_deeply \@got_args, ['a', 'b'],
    'txn_do passes its extra arguments on to the coderef';

  my $scalar = $storage->txn_do(sub { 'one-value' });
  is $scalar, 'one-value',
    'txn_do passes the coderef return value through in scalar context';

  is scalar(@warnings), 1,
    'txn_do warns exactly once, no matter how often it runs';
  like $warnings[0], qr/no transactions.+txn_do/s,
    '... and the warning says why: no transactions, so no atomicity';

  # warn-once is per interpreter (carp_once), not per storage object
  my @second;
  {
    local $SIG{__WARN__} = sub { push @second, $_[0] };
    ch_storage()->txn_do(sub { 1 });
  }
  is scalar(@second), 0,
    'a second storage object does not repeat the txn_do warning';
}

# --- a dying coderef: original exception, unmasked, plus a loud warning ------
{
  my $storage = ch_storage();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $boom = bless { msg => 'boom' }, 'MyTest::CH::Error';
  eval { $storage->txn_do(sub { die $boom }) };
  my $err = $@;

  isa_ok $err, 'MyTest::CH::Error', 'exception thrown out of txn_do';
  is refaddr($err), refaddr($boom),
    'the very same exception object comes back - nothing re-wrapped it';

  is scalar(@warnings), 1, 'a failed txn_do warns';
  like $warnings[0], qr/NOTHING WAS ROLLED BACK/,
    '... loudly, that the completed statements are permanent';

  # this one is deliberately NOT warn-once: every failure is its own incident
  eval { $storage->txn_do(sub { die $boom }) };
  is scalar(@warnings), 2,
    'the "nothing was rolled back" warning repeats on every failure';
}

# A plain string exception keeps its text (core wraps it in a DBIO::Exception
# on the way out, exactly as every other driver's txn_do does).
{
  my $storage = ch_storage();
  local $SIG{__WARN__} = sub { };

  eval { $storage->txn_do(sub { die "plain string boom\n" }) };
  like $@, qr/plain string boom/,
    'a string exception from the coderef keeps its message';
  unlike $@, qr/[Rr]ollback failed/,
    '... and is not decorated with a failed-rollback report';
}

# --- txn_begin / txn_commit are no-ops, but keep core's bookkeeping ---------
{
  my $storage = ch_storage();
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  $storage->txn_begin;
  is $storage->transaction_depth, 1,
    'txn_begin bumps transaction_depth without sending BEGIN';

  $storage->txn_commit;
  is $storage->transaction_depth, 0,
    'txn_commit unwinds transaction_depth without sending COMMIT';

  is scalar(@warnings), 1,
    'txn_begin/txn_commit warn exactly once between them';
  like $warnings[0], qr/no transactions.+no-ops/s,
    '... that neither of them makes anything atomic';
}

# --- explicit txn_rollback is the one path that must NOT be a no-op ---------
{
  my $storage = ch_storage();
  local $SIG{__WARN__} = sub { };

  eval { $storage->txn_rollback };
  my $err = $@;

  ok $err, 'txn_rollback throws instead of silently accepting the rollback';
  isa_ok $err, 'DBIO::Exception';
  like $err, qr/txn_rollback\(\) cannot undo anything/,
    '... naming the reason: the statements are already permanent';
  is $storage->transaction_depth, 0,
    'depth is untouched when there was no transaction to unwind';

  # inside a "transaction" it still throws, and leaves the storage usable
  $storage->txn_begin;
  is $storage->transaction_depth, 1, 'depth is 1 after txn_begin';

  eval { $storage->txn_rollback };
  like $@, qr/cannot undo anything/, 'txn_rollback throws at depth 1 too';
  is $storage->transaction_depth, 0,
    '... and unwinds the depth, so the storage is not stuck in a transaction';
}

done_testing;
