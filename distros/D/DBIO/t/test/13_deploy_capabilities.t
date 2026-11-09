use strict;
use warnings;

use Test::More;
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Diff::Op ();

# F02 / F10 / F12 regression test: the deploy pipeline must probe
# transactional_ddl and supports_if_exists capabilities, not hard-wire
# behavior. The probe is via the storage's _use_X accessor; we record
# the call to txn_do via a fake storage subclass and the call to do()
# via a fake dbh.

# --- 1. F12: Diff::Op::should_emit_if_exists is storage-driven -----------
#
# These cases go through REAL storage subclasses that register the
# capability the documented way (__PACKAGE__->_use_supports_if_exists(0|1),
# or _determine_supports_supports_if_exists). Hand-rolled fake storages
# that define a _use_* sub literally are what let the bug ship: the
# helper probed _use_if_exists, a name the capability registration never
# mints, so it was dead against every real driver while the fakes stayed
# green. Anything asserted below must run against the registered accessor.

# The name the helper probes and the name Capabilities.pm mints must be
# the same one -- that identity IS the bug.
can_ok 'DBIO::Test::Storage', '_use_supports_if_exists';
ok !DBIO::Test::Storage->can('_use_if_exists'),
  'no _use_if_exists accessor exists: the capability is named supports_if_exists';

# Without a storage: conservative false
ok !DBIO::Diff::Op::should_emit_if_exists(undef),
  'should_emit_if_exists(undef) is false';

# With an object that is not a capability-carrying storage at all: false
{
  package DBIO::Test::NoIfExists;
  sub new { bless {}, shift }
}
{
  my $s = DBIO::Test::NoIfExists->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists returns false when storage lacks the capability probe';
}

# An unblessed reference is no storage either: the same conservative false,
# not "Can't call method on unblessed reference" (karr k228 sweep).
{
  my $emit = eval { DBIO::Diff::Op::should_emit_if_exists({}) };
  is $@, '', 'should_emit_if_exists does not die on an unblessed reference';
  is $emit, 0, 'and answers false for it';
}

# A real storage that registers nothing: false (the conservative default
# of _determine_supports_supports_if_exists).
{
  my $s = DBIO::Test::Storage->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists is false on a storage that declares nothing';
}

# A real storage subclass that declares the capability the documented way.
{
  package DBIO::Test::Storage::IfExistsYes;
  use base 'DBIO::Test::Storage';
  __PACKAGE__->_use_supports_if_exists(1);
}
{
  my $s = DBIO::Test::Storage::IfExistsYes->new;
  ok DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists is true for a driver registering _use_supports_if_exists(1)';
}

# ... and one that explicitly opts out: false (not just "undef").
{
  package DBIO::Test::Storage::IfExistsNo;
  use base 'DBIO::Test::Storage';
  __PACKAGE__->_use_supports_if_exists(0);
}
{
  my $s = DBIO::Test::Storage::IfExistsNo->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists is false for a driver registering _use_supports_if_exists(0)';
}

# The other half of the two-tier contract: a driver may leave _use_* undef
# and answer through _determine_supports_supports_if_exists (e.g. version-gated).
# The helper reads _use_supports_if_exists, whose getter falls through to the
# _supports_ tier, so this must be honoured without extra code in the helper.
{
  package DBIO::Test::Storage::IfExistsDetermined;
  use base 'DBIO::Test::Storage';
  sub _determine_supports_supports_if_exists { 1 }
}
{
  my $s = DBIO::Test::Storage::IfExistsDetermined->new;
  ok DBIO::Diff::Op::should_emit_if_exists($s),
    'should_emit_if_exists honours _determine_supports_supports_if_exists (two-tier fallback)';
}

# ... and the tiers rank correctly: an explicit _use_* of 0 wins over a
# _determine_* that would say 1.
{
  package DBIO::Test::Storage::IfExistsForcedOff;
  use base 'DBIO::Test::Storage';
  __PACKAGE__->_use_supports_if_exists(0);
  sub _determine_supports_supports_if_exists { 1 }
}
{
  my $s = DBIO::Test::Storage::IfExistsForcedOff->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'explicit _use_supports_if_exists(0) overrides a _determine_* that says 1';
}

# The misspelled probe must never come back: a storage that
# defines only the never-registered _use_if_exists stays false.
{
  package DBIO::Test::Storage::IfExistsWrongName;
  use base 'DBIO::Test::Storage';
  sub _use_if_exists { 1 }
}
{
  my $s = DBIO::Test::Storage::IfExistsWrongName->new;
  ok !DBIO::Diff::Op::should_emit_if_exists($s),
    'a bare _use_if_exists sub does not flip the helper: only the registered capability counts';
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
#
# The storage carries a _dbh, as every real one does: the bracket only goes
# round a handle the storage actually owns, because _execute_ddl is also called
# with a foreign one (DBIO::Deploy::Base::TempDatabase deploys into a
# connection it opened itself, where a txn_do on the live storage would roll
# back the caller's work and buy nothing). A mock without a handle would
# therefore not be bracketed -- and would not be modelling any storage that can
# reach this code. The foreign-handle half of the rule is covered in
# t/deploy-base.t.
{
  package DBIO::Test::TxnStorage;
  sub new {
    my ($class, $dbh) = @_;
    bless { txn_do_calls => 0, txn_do_seen_stmts => [], dbh => $dbh }, $class;
  }
  sub _dbh { $_[0]->{dbh} }
  sub _use_transactional_ddl { 1 }
  sub txn_do {
    my ($self, $code) = @_;
    $self->{txn_do_calls}++;
    $code->();
    return 1;
  }
}

{
  my $dbh     = DBIO::Test::FakeDbh->new;
  my $storage = DBIO::Test::TxnStorage->new($dbh);
  my $deploy  = _make_deploy($storage);
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

# --- 4. why a driver must DECLARE, not inherit ------------------------------
#
# Every driver is asked to state its transactional_ddl answer outright rather
# than let core's default stand in (see DBIO::Deploy::Base, TRANSACTIONAL DDL;
# DBIO::ClickHouse::Storage is the reference shape). This block pins the
# machinery that advice rests on, because without it "declare your answer"
# would be style advice with nothing behind it.
#
# Real DBIO::Storage::DBI subclasses, never a hand-rolled fake with a literal
# _use_* sub -- that shortcut is exactly what let the bug ship.
{
  package DBIO::Test::SilentStorage;
  our @ISA = ('DBIO::Storage::DBI');

  package DBIO::Test::DeclaredStorage;
  our @ISA = ('DBIO::Storage::DBI');
  __PACKAGE__->_use_transactional_ddl(1);

  package DBIO::Test::InheritingStorage;
  our @ISA = ('DBIO::Test::DeclaredStorage');
}

# Silence is not a quiet 0 at class level -- it is not answerable at all. This
# is the sharpest form of the rule: core refuses the question rather than
# handing back a default that would read like a statement by the driver.
{
  my $v = eval { DBIO::Test::SilentStorage->_use_transactional_ddl };
  my $err = $@;
  ok !defined $v, 'an undeclared capability has no class-level answer';
  like $err, qr/Cannot determine the capability/,
    '... core refuses the question instead of returning its default';
  like $err, qr/_use_transactional_ddl/,
    '... naming the declaration that would have answered it';
}

is(DBIO::Test::DeclaredStorage->_use_transactional_ddl, 1,
  'a declared capability answers as a class method');

# The same storage DOES answer as an instance, from core's _determine_* default
# -- which is the whole problem the declaration solves. An undeclared driver
# looks identical to one that considered the question and said 0.
is(DBIO::Test::SilentStorage->new->_use_transactional_ddl, 0,
  'an undeclared capability still answers 0 on an instance (core default)');

# get_inherited is what tells the two apart, and it is the check every driver
# test should carry beside the value.
is(DBIO::Test::SilentStorage->get_inherited('_use_transactional_ddl'), undef,
  'get_inherited is undef while nobody declared -- silence is visible');
is(DBIO::Test::DeclaredStorage->get_inherited('_use_transactional_ddl'), 1,
  '... and defined once a driver states its answer');

# Inheriting a driver's declaration counts as declared: a storage subclass
# (MariaDB under MySQL, a driver's NoBindVars variant) inherits an ANSWER,
# which is categorically different from falling through to core's default.
is(DBIO::Test::InheritingStorage->get_inherited('_use_transactional_ddl'), 1,
  'a subclass inherits the declaration -- an answer, not core\'s default');

done_testing;
