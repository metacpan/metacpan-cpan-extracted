use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;

# karr k372: a COMMIT of the outermost transaction that fails ends that
# transaction. The storage does not keep claiming depth 1 (the next write would
# run "inside" a transaction nobody will ever commit and be lost silently): it
# resets its transaction state like after a failed rollback, tries a ROLLBACK
# so the server keeps no open transaction, discards the handle when that fails
# too, and rethrows the error of the COMMIT, not that of the ROLLBACK.
# Mock-only: the fake handle counts its disconnects.

sub fresh {
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  return ($schema, $schema->storage);
}

sub ops { map { $_->{op} } $_[0]->captured_queries }
sub disconnects { $_[0]->_dbh->{disconnected} || 0 }

sub fail_commit   { sub { die "COMMIT BROKE\n" } }
sub fail_rollback { sub { die "ROLLBACK BROKE\n" } }

subtest 'direct txn_commit: state reset, rollback tried, commit error thrown' => sub {
  my ($schema, $storage) = fresh();
  $storage->txn_begin;
  $storage->reset_captured;

  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_commit = fail_commit();

  eval { $storage->txn_commit };
  is $@, "COMMIT BROKE\n", 'the error of the commit is thrown';
  is $storage->transaction_depth, 0, 'no transaction is claimed any more';
  ok !$storage->deferred_rollback, 'no deferred rollback';
  is_deeply $storage->savepoints, [], 'no savepoints';
  is_deeply [ grep { /^txn_/ } ops($storage) ], [qw(txn_rollback)],
    'a ROLLBACK was tried so the server holds no open transaction';
  is disconnects($storage), 0, 'the handle stays, the rollback worked';
};

subtest 'commit and rollback both die: handle discarded, commit error wins' => sub {
  my ($schema, $storage) = fresh();
  $storage->txn_begin;

  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_commit   = fail_commit();
  local *DBIO::Test::Storage::_exec_txn_rollback = fail_rollback();

  eval { $storage->txn_commit };
  is $@, "COMMIT BROKE\n", 'the commit error, not the rollback error';
  is $storage->transaction_depth, 0, 'depth 0';
  ok !$storage->deferred_rollback, 'no deferred rollback';
  is_deeply $storage->savepoints, [], 'no savepoints';
  is disconnects($storage), 1, '_discard_dbh ran: the handle was disconnected';
};

subtest 'the statement after a failed commit is a real transaction, not depth 1' => sub {
  my ($schema, $storage) = fresh();
  $storage->txn_begin;
  {
    no warnings 'redefine';
    local *DBIO::Test::Storage::_exec_txn_commit = fail_commit();
    eval { $storage->txn_commit };
  }

  $storage->reset_captured;
  $storage->txn_do(sub { 1 });
  is_deeply [ grep { /^txn_/ } ops($storage) ], [qw(txn_begin txn_commit)],
    'BEGIN and COMMIT issued, not a silent nested no-op';
  is $storage->transaction_depth, 0, 'depth back to 0';
};

subtest 'txn_scope_guard: commit fails, depth 0, error is the commit error' => sub {
  my ($schema, $storage) = fresh();

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "@_" };
  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_commit   = fail_commit();
  local *DBIO::Test::Storage::_exec_txn_rollback = fail_rollback();

  my $guard = $schema->txn_scope_guard;
  eval { $guard->commit };
  is $@, "COMMIT BROKE\n", 'the commit error is thrown';
  is $storage->transaction_depth, 0, 'depth 0';
  is disconnects($storage), 1, 'handle discarded';
  undef $guard;
  is scalar(grep { /ROLLBACK FAILED/ } @warnings), 0,
    'the guard has nothing left to roll back';
};

subtest 'txn_do: commit fails, depth 0, commit error reported' => sub {
  my ($schema, $storage) = fresh();

  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_commit = fail_commit();

  $storage->reset_captured;
  eval { $storage->txn_do(sub { 1 }) };
  like $@, qr/COMMIT BROKE/, 'the commit error is reported';
  unlike $@, qr/ROLLBACK BROKE|Transaction aborted|Rollback failed/,
    '... as it is, with no word of a rollback';
  is $storage->transaction_depth, 0, 'depth 0';
  is_deeply [ grep { /^txn_/ } ops($storage) ], [qw(txn_begin txn_rollback)],
    'one ROLLBACK, the one of the storage after the failed commit';
};

subtest 'txn_do: a commit error object reaches the caller unchanged' => sub {
  my ($schema, $storage) = fresh();

  my $broke = bless { msg => 'COMMIT BROKE' }, 'T::CommitError';
  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_commit = sub { die $broke };

  eval { $storage->txn_do(sub { 1 }) };
  is $@, $broke, 'the caller is handed the object the commit died with';
  is $storage->transaction_depth, 0, 'depth 0';
};

subtest 'txn_do: a body that dies is still rolled back by the runner' => sub {
  my ($schema, $storage) = fresh();
  $storage->reset_captured;

  eval { $storage->txn_do(sub { die "BODY BROKE\n" }) };
  like $@, qr/BODY BROKE/, 'the error of the body';
  unlike $@, qr/Transaction aborted|Rollback failed/, '... and the rollback went through';
  is_deeply [ grep { /^txn_/ } ops($storage) ], [qw(txn_begin txn_rollback)],
    'BEGIN, then the ROLLBACK of the runner';
  is $storage->transaction_depth, 0, 'depth 0';
};

subtest 'a nested commit is not a failed commit' => sub {
  my ($schema, $storage) = fresh();
  $storage->txn_begin;
  $storage->txn_begin;
  $storage->txn_commit;
  is $storage->transaction_depth, 1, 'inner commit only lowers the depth';
  $storage->txn_commit;
  is $storage->transaction_depth, 0, 'outer commit ends it';
  is disconnects($storage), 0, 'handle untouched';
};

{
  package K372::BareStorage;
  our @ISA = ('DBIO::Storage');
  sub _exec_txn_begin    { 1 }
  sub _exec_txn_commit   { die "BARE COMMIT BROKE\n" }
  sub _exec_txn_rollback { die "BARE ROLLBACK BROKE\n" }
}

subtest 'a storage without a connection resets its state too' => sub {
  my $s = K372::BareStorage->new(undef);
  $s->txn_begin;
  eval { $s->txn_commit };
  is $@, "BARE COMMIT BROKE\n", 'the commit error is rethrown';
  is $s->transaction_depth, 0, 'depth reset';
  ok !$s->deferred_rollback, 'no deferred rollback';
};

# A plain DBI storage over the fake handle, AutoCommit off, where
# DBI::txn_commit restores depth 1 after a good commit.
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

subtest 'a DBI storage, AutoCommit off, both die: handle dropped, depth 0' => sub {
  my ($s, $d) = dbi_storage_over_fake_handle();

  no warnings qw(redefine once);
  local *DBIO::Test::Storage::FakeDbh::commit   = sub { die "CM\n" };
  local *DBIO::Test::Storage::FakeDbh::rollback = sub { die "RB\n" };

  eval { $s->txn_commit };
  is $@, "CM\n", 'the commit error, not the rollback error';
  is $s->transaction_depth, 0, 'AutoCommit does not restore depth 1';
  ok !defined $s->_dbh, 'the handle is dropped';
  is $d->{disconnected}, 1, 'and disconnected';
};

# The rollback tried after a failed COMMIT must not warn. DBI has AutoCommit
# on again by then and answers a rollback with "rollback ineffective with
# AutoCommit enabled" unless the handle's Warn attribute is off. The fake
# handle warns the same way, gated by Warn like DBI: the claim is that the
# attempt runs silenced and the handle's Warn is back afterwards.
subtest 'a DBI storage: the rollback after a failed commit does not warn' => sub {
  my ($s, $d) = dbi_storage_over_fake_handle();
  $d->{Warn} = 1;
  my $rolled_back = 0;

  no warnings qw(redefine once);
  local *DBIO::Test::Storage::FakeDbh::commit = sub { die "CM\n" };
  local *DBIO::Test::Storage::FakeDbh::rollback = sub {
    $rolled_back++;
    warn "rollback ineffective with AutoCommit enabled" if $_[0]{Warn};
    1;
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "@_" };

  eval { $s->txn_commit };
  is $@, "CM\n", 'the commit error is thrown';
  is $rolled_back, 1, 'the rollback was tried';
  is_deeply \@warnings, [], 'and raised no warning';
  is $d->{Warn}, 1, 'the handle\'s Warn attribute is restored';
  is $s->transaction_depth, 0, 'depth 0';
};

done_testing;
