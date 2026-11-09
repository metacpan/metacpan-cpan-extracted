use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Oracle::Storage;
use DBIO::Oracle::Deploy;

# F02 / F10 -- the transactional_ddl capability DBIO::Oracle::Storage declares,
# and the branch of DBIO::Deploy::Base::_execute_ddl it selects.
#
# Entirely offline: no DSN, no server, no DBIO_TEST_* anything. The declaration
# is a class fact, and the second half drives core's real _execute_ddl against
# the hybrid mock storage.
#
# WHAT IS AND IS NOT PROVEN HERE. This file proves that the driver states the
# capability, what it states, and that core consequently runs Oracle's DDL loop
# unbracketed -- and, by forcing the capability the other way, that the loop
# WOULD be bracketed if it did not. It cannot prove the engine claim the
# declaration rests on: that Oracle commits before and after every DDL
# statement, which is what makes a bracket useless and misleading rather than
# merely redundant. That half is documented behaviour, quoted with its sources
# at the declaration in DBIO::Oracle::Storage and in DBIO::Oracle::Deploy's
# "Transactional DDL", and measured on Oracle 23ai Free in t/54-deploy-live.t
# (1d, 4).

# --- 1. the declaration -----------------------------------------------------
#
# The value and its DECLAREDNESS are two different assertions and both are
# needed, because core's answer for a driver that declares nothing is 0 as well
# (DBIO::Storage::DBI::Capabilities::_determine_supports_transactional_ddl).
# On a storage INSTANCE -- which is how the deploy path reads it, and how
# section 2 below reads it -- an undeclared capability therefore answers a
# perfectly green 0 through that determination, and a test asserting only the
# value would pass against a driver that had never heard of the capability.
# get_inherited is the tripwire: it is defined only where this class or one of
# its ancestors set the value outright, and no ancestor here does -- core ships
# the _determine_* default, not a declaration.
#
# The order of the two is deliberate. A class-method read of an undeclared
# capability does not answer 0 either -- it dies, because determining one needs
# a $dbh -- so putting the value first would abort the file on core's exception
# and never reach the assertion that names the actual cause. Declaredness
# first fails cleanly and says what is missing; the value read after it is then
# free to be the blunt instrument it is.

isnt (
  DBIO::Oracle::Storage->get_inherited('_use_transactional_ddl'),
  undef,
  'this driver STATES its transactional_ddl answer, rather than resting on '
. 'core\'s default of the same value, which core is free to change',
);

is (
  DBIO::Oracle::Storage->_use_transactional_ddl,
  0,
  '... and the answer is 0 -- Oracle commits before and after every DDL '
. 'statement, so the deploy loop must not be bracketed in txn_do',
);

# Both tiers nailed shut, the way _use_set_operator_all_family is: there is
# nothing here for a determination to probe -- the implicit COMMIT on DDL is
# Oracle's behaviour on every release this driver supports -- so a
# driver-local _determine_supports_transactional_ddl would be a $dbh-opening
# answer to a static question.
is (
  DBIO::Oracle::Storage->can('_determine_supports_transactional_ddl'),
  DBIO::Storage::DBI->can('_determine_supports_transactional_ddl'),
  '... with no driver-local determination behind it: the answer is a class '
. 'fact, not a server probe',
);

# --- 2. the branch that declaration selects in core -------------------------
#
# DBIO::Deploy::Base::_execute_ddl brackets its loop in $storage->txn_do only
# when the storage answers transactional_ddl truthy AND owns the handle it was
# handed. The mock storage records BEGIN/COMMIT in its query log
# (DBIO::Test::Storage::_exec_txn_begin), so the presence or absence of a
# bracket around an unchanged pair of statements is directly observable with no
# database in the picture.
#
# The recording handle exists because core's stock FakeDbh has no do() -- the
# one method _execute_ddl uses. Subclassing it keeps everything else about the
# stand-in handle (Active, AutoCommit, prepare, ...) intact, so this is the
# real fake dbh plus a statement log.
{
  package T::Ora::TxnDdl::Dbh;
  use base 'DBIO::Test::Storage::FakeDbh';

  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{_ddl} ||= [] }, $sql;
    return 1;
  }

  sub ddl_seen  { @{ $_[0]->{_ddl} ||= [] } }
  sub reset_ddl { $_[0]->{_ddl} = [] }
}

my $schema  = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::Oracle::Storage',
);
my $storage = $schema->storage;

# _dbh on the mock storage is a reader over this slot and there is no setter;
# swapping it is how the recording handle gets in front of _execute_ddl, and it
# has to be the storage's OWN handle or core would decline to bracket for a
# reason that has nothing to do with the capability (_storage_owns_dbh).
$storage->{_fake_dbh} = T::Ora::TxnDdl::Dbh->new;
my $dbh = $storage->_dbh;

my $deploy = DBIO::Oracle::Deploy->new(schema => $schema);
my $ddl    = "CREATE TABLE artist (id NUMBER);\nCREATE TABLE cd (id NUMBER)";

sub txn_ops { grep { $_->{op} =~ /^txn_/ } $storage->captured_queries }

is (
  $storage->_use_transactional_ddl,
  0,
  'the storage instance answers 0 too, with nothing connected -- the '
. 'declaration answers, so no $dbh is consulted to find out',
);

# 2a. the declaration answering. Core's F02 notice is a one-shot per process
# and this is the first _execute_ddl of the file, so this is the only place it
# can be caught -- and it is worth catching: the ticket's claim is that the
# notice is a correct statement about Oracle, not a defect to be silenced.
{
  $storage->reset_captured;
  $dbh->reset_ddl;

  my @warn;
  {
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    $deploy->_execute_ddl($dbh, $ddl);
  }

  is_deeply (
    [ $dbh->ddl_seen ],
    [ 'CREATE TABLE artist (id NUMBER)', 'CREATE TABLE cd (id NUMBER)' ],
    'both statements ran, in order',
  );

  is_deeply (
    [ map { $_->{sql} } txn_ops() ],
    [],
    '... statement at a time, with no transaction opened around them. On '
  . 'Oracle a bracket could not have held: the first CREATE TABLE commits '
  . 'whatever transaction it finds open, so a later ROLLBACK would have '
  . 'nothing left to take back',
  );

  ok (
    scalar( grep { /non-transactional DDL on DBIO::Oracle::Deploy\b/ } @warn ),
    '... and core says so once, naming this deploy class. The notice is '
  . 'accurate here rather than a defect: an apply that fails half way leaves '
  . 'the earlier statements committed',
  );
}

# 2b. the counterfactual -- the capability forced true on this one storage
# (ADR 0041 tier 1), which is what "Oracle should surely be able to do
# transactional DDL" would amount to as a change. Same statements, same handle.
{
  $storage->_use_transactional_ddl(1);
  $storage->reset_captured;
  $dbh->reset_ddl;

  $deploy->_execute_ddl($dbh, $ddl);

  is_deeply (
    [ $dbh->ddl_seen ],
    [ 'CREATE TABLE artist (id NUMBER)', 'CREATE TABLE cd (id NUMBER)' ],
    'forced true, the same two statements still run',
  );

  is_deeply (
    [ map { $_->{sql} } txn_ops() ],
    [ 'BEGIN', 'COMMIT' ],
    '... but now wrapped in a transaction. That bracket is what the '
  . 'declaration exists to prevent: against a real Oracle the BEGIN is '
  . 'undone by the first statement\'s implicit COMMIT, leaving a txn_do that '
  . 'reads as atomic at the call site and is not',
  );
}

# 2c. clearing the force hands the question back to the class declaration --
# undef deletes the tier-1 slot rather than leaving a tombstone that would
# shadow it (core ADR 0041). Without a declaration underneath, this is where a
# driver would silently fall through to core's default instead.
{
  $storage->_use_transactional_ddl(undef);

  is (
    $storage->_use_transactional_ddl,
    0,
    'clearing the force falls through to this driver\'s declaration',
  );

  $storage->reset_captured;
  $dbh->reset_ddl;

  $deploy->_execute_ddl($dbh, $ddl);

  is_deeply (
    [ map { $_->{sql} } txn_ops() ],
    [],
    '... and the loop is unbracketed again',
  );
}

done_testing;
