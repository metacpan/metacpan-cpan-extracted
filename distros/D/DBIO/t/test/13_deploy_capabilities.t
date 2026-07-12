use strict;
use warnings;

use Test::More;
use DBIO::Test;
use DBIO::Diff::Op ();

# F02 / F10 / F12 regression test: the deploy pipeline must probe
# transactional_ddl and supports_if_exists capabilities, not hard-wire
# behavior. The probe is via the storage's _use_X accessor; we record
# the call to txn_do via a fake storage subclass and the call to do()
# via a fake dbh.

# --- 1. F12: Diff::Op::should_emit_if_exists is storage-driven -----------

# Without a storage: conservative false
ok !DBIO::Diff::Op::should_emit_if_exists(undef),
  'should_emit_if_exists(undef) is false';

# With a fake storage that does not advertise the capability: false
{
  package DBIO::Test::NoIfExists;
  sub new { bless {}, shift }
}
{
  my $s = DBIO::Test::NoIfExists->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists returns false when storage lacks the capability';
}

# With a fake storage that does advertise it: true
{
  package DBIO::Test::HasIfExists;
  sub new { bless {}, shift }
  sub _use_if_exists { 1 }
}
{
  my $s = DBIO::Test::HasIfExists->new;
  ok DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists returns true when storage has _use_if_exists=1';
}

# With a fake storage that explicitly opts out: false (not just "undef")
{
  package DBIO::Test::OptOutIfExists;
  sub new { bless {}, shift }
  sub _use_if_exists { 0 }
}
{
  my $s = DBIO::Test::OptOutIfExists->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists returns false when _use_if_exists=0';
}

# --- 2. F02 / F10: Deploy::Base::_execute_ddl wraps in txn_do only when
#                   storage reports transactional DDL. The wrap is not
#                   a blanket apply -- engines that force implicit COMMIT
#                   on DDL (MySQL pre-8.0, Oracle, DB2, Sybase, Informix)
#                   or that depend on AutoCommit=on (SQLite) opt out.

use DBIO::Deploy::Base ();

# A minimal fake dbh that records every do() call. We pass it into
# _execute_ddl directly -- the method takes ($self, $dbh, $sql) -- so we
# do not need a real DBI handle.
{
  package DBIO::Test::FakeDbh;
  sub new { bless { stmts => [] }, shift }
  sub do { push @{ $_[0]->{stmts} }, $_[1]; 1 }
  sub stmts { $_[0]->{stmts} }
}

# A minimal Deploy::Base subclass that supplies a controlled schema.
# _execute_ddl reads $self->schema->storage to probe the capability, so
# we need a schema class with a `storage` accessor. DBIO::Test::Schema
# is a result-class bag, not a DBIO::Schema, so we define a tiny
# accessor-only class here.
{
  package DBIO::Test::FakeSchema;
  sub new { my ($c, %a) = @_; bless { %a }, $c }
  sub storage { $_[0]->{storage} }
}
{
  package DBIO::Test::DeploySub;
  our @ISA = ('DBIO::Deploy::Base');
  sub new { my ($c, %a) = @_; bless { %a }, $c }
}

sub _make_deploy {
  my ($storage) = @_;
  my $schema = DBIO::Test::FakeSchema->new(storage => $storage);
  return DBIO::Test::DeploySub->new(schema => $schema);
}

# Case A: transactional_ddl = true. Expect: statements run inside txn_do
# and emitted once each.
{
  package DBIO::Test::TxnStorage;
  sub new { bless { txn_do_calls => 0, txn_do_seen_stmts => [] }, shift }
  sub _use_transactional_ddl { 1 }
  sub txn_do {
    my ($self, $code) = @_;
    $self->{txn_do_calls}++;
    $code->();
    return 1;
  }
}

{
  my $storage = DBIO::Test::TxnStorage->new;
  my $deploy  = _make_deploy($storage);
  my $dbh     = DBIO::Test::FakeDbh->new;
  my $sql     = "CREATE TABLE t1 (id INT);\nCREATE TABLE t2 (id INT);";

  $deploy->_execute_ddl($dbh, $sql);

  is $storage->{txn_do_calls}, 1,
    'F02: transactional DDL wraps the DDL loop in exactly one txn_do call';
  is scalar @{ $dbh->stmts }, 2,
    'F02: both non-comment statements ran';
  is $dbh->stmts->[0], 'CREATE TABLE t1 (id INT)',
    'F02: first statement ran unchanged';
  is $dbh->stmts->[1], 'CREATE TABLE t2 (id INT)',
    'F02: second statement ran unchanged';
}

# Case B: transactional_ddl = false. Expect: statements run, NO txn_do
# wrap, and a carp_once warning is emitted naming the deploy class.
{
  package DBIO::Test::NonTxnStorage;
  sub new { bless { txn_do_calls => 0 }, shift }
  sub _use_transactional_ddl { 0 }
  sub txn_do { $_[0]->{txn_do_calls}++; 'SHOULD_NOT_RUN' }
}

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $storage = DBIO::Test::NonTxnStorage->new;
  my $deploy  = _make_deploy($storage);
  my $dbh     = DBIO::Test::FakeDbh->new;
  my $sql     = "CREATE TABLE t1 (id INT);\nCREATE TABLE t2 (id INT);";

  $deploy->_execute_ddl($dbh, $sql);

  is $storage->{txn_do_calls}, 0,
    'F02/F10: non-transactional DDL does NOT wrap in txn_do (no SQLite regression)';
  is scalar @{ $dbh->stmts }, 2,
    'F02/F10: statements still run statement-at-a-time';
  ok scalar @warnings >= 1, 'F02/F10: a warning is emitted on non-transactional DDL';
  like "@warnings",
    qr/non-transactional DDL on DBIO::Test::DeploySub/i,
    'F02/F10: warning names the deploy class so operators see which engine is non-atomic';
}

# Case C: storage that lacks the probe entirely. Treated as non-transactional.
# This guards against a future driver subclassing Storage (not
# Storage::DBI::Capabilities) and silently regressing to non-atomic.
{
  package DBIO::Test::NoProbeStorage;
  sub new { bless {}, shift }
  # no _use_transactional_ddl method at all
}

{
  my $storage = DBIO::Test::NoProbeStorage->new;
  my $deploy  = _make_deploy($storage);
  my $dbh     = DBIO::Test::FakeDbh->new;
  $deploy->_execute_ddl($dbh, "CREATE TABLE t (id INT);");
  is scalar @{ $dbh->stmts }, 1,
    'F02: storage without _use_transactional_ddl probe -> loop runs (no txn_do attempted)';
}

# Case D: empty / comment-only SQL is a no-op (no txn_do either way).
{
  my $storage = DBIO::Test::TxnStorage->new;
  my $deploy  = _make_deploy($storage);
  my $dbh     = DBIO::Test::FakeDbh->new;
  $deploy->_execute_ddl($dbh, "-- only a comment\n");
  is $storage->{txn_do_calls}, 0,
    'F02: empty / comment-only SQL skips the txn_do wrap';
  is scalar @{ $dbh->stmts }, 0,
    'F02: empty / comment-only SQL does not call do()';
}

done_testing;
