use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;

# karr k303 (decision C+B): a rollback of the outermost transaction that
# fails leaves a handle nobody can vouch for. The storage forgets the
# transaction (depth 0, no deferred rollback) and discards the handle; the
# retry of txn_do disconnects the old handle, with a warning, before it
# reconnects. Mock-only: the fake handle counts its disconnects.

sub fresh {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  return ($schema, $schema->storage);
}

sub ops { map { $_->{op} } $_[0]->captured_queries }

sub disconnects { $_[0]->_dbh->{disconnected} || 0 }

sub fail_rollback { sub { die "ROLLBACK BROKE\n" } }

subtest 'a failed rollback resets the state and discards the handle' => sub {
  my ($schema, $storage) = fresh();

  $storage->txn_begin;
  is $storage->transaction_depth, 1, 'inside the transaction';

  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_rollback = fail_rollback();

  eval { $storage->txn_rollback };
  is $@, "ROLLBACK BROKE\n", 'the original error is rethrown, unchanged';

  is $storage->transaction_depth, 0, 'no transaction is claimed any more';
  ok !$storage->deferred_rollback, 'no deferred rollback';
  is_deeply $storage->savepoints, [], 'no savepoints';
  is disconnects($storage), 1, 'the handle was disconnected';
};

subtest 'the next txn_do is a real transaction' => sub {
  my ($schema, $storage) = fresh();

  {
    no warnings 'redefine';
    local *DBIO::Test::Storage::_exec_txn_rollback = fail_rollback();
    $storage->txn_begin;
    eval { $storage->txn_rollback };
  }

  $storage->reset_captured;
  my $ran = 0;
  $storage->txn_do(sub { $ran++ });

  is $ran, 1, 'the block ran';
  is_deeply [ grep { /^txn_/ } ops($storage) ], [qw(txn_begin txn_commit)],
    'BEGIN and COMMIT were issued, not a silent nested no-op';
  is $storage->transaction_depth, 0, 'and the depth is back to 0';
};

subtest 'a guard whose rollback fails does not leave depth 1' => sub {
  my ($schema, $storage) = fresh();

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, "@_" };
    no warnings 'redefine';
    local *DBIO::Test::Storage::_exec_txn_rollback = fail_rollback();
    eval { my $guard = $schema->txn_scope_guard; die "body died\n" };
  }

  ok((grep { /ROLLBACK FAILED/ } @warnings), 'the failure is still reported');
  is $storage->transaction_depth, 0, 'the depth is not stuck at 1';
  is disconnects($storage), 1, 'the handle was discarded';
};

subtest 'not a failed rollback: nested and refused rollbacks leave the handle' => sub {
  my ($schema, $storage) = fresh();

  eval { $storage->txn_rollback };
  like $@, qr/Refusing to roll back/, 'rollback without a transaction refused';
  is disconnects($storage), 0, 'handle untouched';

  $storage->txn_begin;
  $storage->txn_begin;
  eval { $storage->txn_rollback };
  isa_ok $@, 'DBIO::Storage::NESTED_ROLLBACK_EXCEPTION';
  ok $storage->deferred_rollback, 'deferred rollback kept';
  is $storage->transaction_depth, 1, 'depth kept';
  is disconnects($storage), 0, 'handle untouched';
};

{
  package K303::BareStorage;
  our @ISA = ('DBIO::Storage');
  sub _exec_txn_begin    { 1 }
  sub _exec_txn_rollback { die "BARE ROLLBACK BROKE\n" }
}

subtest 'a storage without a connection resets its state too' => sub {
  my $s = K303::BareStorage->new(undef);
  $s->txn_begin;
  eval { $s->txn_rollback };
  is $@, "BARE ROLLBACK BROKE\n", 'the original error is rethrown';
  is $s->transaction_depth, 0, 'depth reset';
  ok !$s->deferred_rollback, 'no deferred rollback';
};

subtest 'txn_do retry disconnects the old handle with a warning' => sub {
  my ($schema, $storage) = fresh();
  my $old = $storage->_dbh;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "@_" };

  my (@runs, $disconnects_at_rerun);
  my $res = $storage->txn_do(sub {
    push @runs, 1;
    if (@runs == 1) {
      # the connection is gone as far as ping can tell
      $storage->_fake_connected(0);
      die "statement failed\n";
    }
    $disconnects_at_rerun = disconnects($storage);
    $storage->_fake_connected(1);
    return 'again';
  });

  is $res, 'again', 'the retry succeeded';
  is scalar(@runs), 2, 'the block ran twice';
  is $disconnects_at_rerun, 1,
    'the old handle was already disconnected when the block ran again';
  my @w = grep { /old handle is disconnected/ } @warnings;
  is scalar(@w), 1, 'one warning says the old handle is disconnected'
    or diag explain \@warnings;
};

subtest 'txn_do without a retry does not disconnect' => sub {
  my ($schema, $storage) = fresh();

  eval { $storage->txn_do(sub { die "plain failure\n" }) };
  like $@, qr/plain failure/, 'the error is thrown';
  is disconnects($storage), 0, 'a connected storage keeps its handle';
};

# The mock keeps its stand-in handle whatever is done to _dbh; a plain DBI
# storage over the same fake handle shows the real drop (AutoCommit off, where
# DBI::txn_rollback would otherwise restore depth 1 after the rollback).
sub dbi_storage_over_fake_handle {
  my ($schema) = fresh();
  my $s = DBIO::Storage::DBI->new($schema);
  my $d = DBIO::Test::Storage::FakeDbh->new;
  $d->{AutoCommit} = 0;
  $s->_dbh($d);
  $s->{_dbh_autocommit} = 0;
  $s->{_connection_pid} = $$;
  $s->{transaction_depth} = 1;
  return ($s, $d);
}

subtest 'a DBI storage lets go of the handle, AutoCommit off' => sub {
  my ($s, $d) = dbi_storage_over_fake_handle();

  no warnings qw(redefine once);
  local *DBIO::Test::Storage::FakeDbh::rollback = sub { die "RB\n" };

  eval { $s->txn_rollback };
  is $@, "RB\n", 'the original error is rethrown';
  is $s->transaction_depth, 0, 'AutoCommit does not restore depth 1';
  ok !defined $s->_dbh, 'the handle is dropped';
  is $d->{disconnected}, 1, 'and disconnected once, with no second rollback';
};

subtest 'a DBI storage retry drops the old handle with a warning' => sub {
  my ($s, $d) = dbi_storage_over_fake_handle();

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "@_" };

  $s->_abandon_handle_before_reconnect;
  ok !defined $s->_dbh, 'handle dropped';
  is $d->{disconnected}, 1, 'and disconnected';
  is scalar(grep { /old handle is disconnected/ } @warnings), 1, 'with a warning';

  @warnings = ();
  $s->_abandon_handle_before_reconnect;
  is scalar(@warnings), 0, 'nothing to drop, nothing to warn about';
};

done_testing;
