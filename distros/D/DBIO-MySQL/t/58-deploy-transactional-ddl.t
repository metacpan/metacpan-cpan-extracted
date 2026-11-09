use strict;
use warnings;

use Test::More;

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::MySQL::Deploy;

# F02 / F10 -- the transactional_ddl capability DBIO::MySQL::Storage declares
# (karr #34, handoff from core karr #130).
#
# FULLY OFFLINE. No DBI, no DSN, no DBIO_TEST_*, no server: the declaration is
# a class-level fact, and the deploy path below is driven with a fake handle
# that records the statements it was asked to run.
#
# WHY THE VALUE ALONE WOULD PROVE NOTHING. Core's answer for an undeclared
# capability is 0 as well (DBIO::Storage::DBI::Capabilities defines
# _determine_supports_transactional_ddl => 0), so a bare is(..., 0) stays green
# with nothing declared at all -- it would sample core's default and report it
# as this driver's position. Each value assertion is therefore paired with
# get_inherited, which is defined only for a value some class in the MRO set
# itself, and part 2 drives the codepath the declaration actually governs.

# --- 1. the declaration ------------------------------------------------------

is(DBIO::MySQL::Storage->_use_transactional_ddl, 0,
  'transactional_ddl is 0 -- both products commit implicitly on every DDL statement');

isnt(DBIO::MySQL::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# The answer is the same for MariaDB, and that is not a second declaration:
# which commit semantics DDL carries is a property of the SERVER, while
# DBIO::MySQL::Storage::MariaDB is the DBD::MariaDB binding and nothing else
# (karr k28, this dist's ADR 0001). It reads 0 by inheritance, which is what the pair below
# distinguishes -- get_inherited walks the MRO and so cannot tell a declaration
# from an inherited one, but the class-level slot it writes can: CAG stores a
# class declaration in $Class::__cag_<field> (documented as such in
# DBIO::Storage::DBI::Capabilities, "Which tier a driver writes to").
is(DBIO::MySQL::Storage::MariaDB->_use_transactional_ddl, 0,
  'the DBD::MariaDB binding answers 0 too -- MariaDB commits implicitly as well');

{
  no strict 'refs';
  ok(defined ${'DBIO::MySQL::Storage::__cag__use_transactional_ddl'},
    '... and the value lives on the shared class');
  ok(! defined ${'DBIO::MySQL::Storage::MariaDB::__cag__use_transactional_ddl'},
    '... which the subclass inherits instead of repeating (nowhere to drift)');
}

# --- 2. and what it governs: the deploy loop is not bracketed -----------------
#
# The counterexample, run against core's real DBIO::Deploy::Base::_execute_ddl
# with a real DBIO::MySQL::Deploy, because the capability is what core keys on
# and nothing in this dist overrides that method.
#
# Order matters here: core's "non-transactional DDL" notice is a one-shot, so
# the forced-true run has to come FIRST -- otherwise the notice is already
# spent and its absence in that run would prove nothing. Which is exactly the
# point of the exercise: a future "MySQL 8 has atomic DDL, so this should be a
# 1" cleanup does not gain atomicity, it loses the notice.

{
  package MyTest::MySQL::SpyStorage;
  our @ISA = ('DBIO::MySQL::Storage');
  our @TXN_DO;
  sub _dbh   { $_[0]->{__fake_dbh} }
  sub txn_do { my ($self, $code) = @_; push @TXN_DO, 1; return $code->() }
}
{
  package MyTest::MySQL::FakeDbh;
  sub new { bless { stmts => [] }, shift }
  sub do  { push @{ $_[0]->{stmts} }, $_[1]; 1 }
}
{
  package MyTest::MySQL::FakeSchema;
  sub new { my ($class, %args) = @_; bless { %args }, $class }
  sub storage { $_[0]->{storage} }
}

my $DDL = "CREATE TABLE `artist` (`id` integer NOT NULL) ENGINE=InnoDB;\n"
        . "CREATE INDEX `artist_idx` ON `artist` (`id`);\n"
        . "ALTER TABLE `artist` ADD COLUMN `name` varchar(100);";

my $dbh     = MyTest::MySQL::FakeDbh->new;
my $storage = MyTest::MySQL::SpyStorage->new;
$storage->{__fake_dbh} = $dbh;    # so _storage_owns_dbh sees its own handle

my $deploy = DBIO::MySQL::Deploy->new(
  schema => MyTest::MySQL::FakeSchema->new(storage => $storage),
);

# 2a. the capability forced true on the storage (tier 1) -- what "tidying" the
# declaration up to match the atomic-DDL feature amounts to.
$storage->_use_transactional_ddl(1);

my @warnings;
{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $deploy->_execute_ddl($dbh, $DDL);
}

is(scalar @MyTest::MySQL::SpyStorage::TXN_DO, 1,
  'forced true, core brackets the whole DDL batch in one txn_do');
is(scalar @{ $dbh->{stmts} }, 3,
  '... running the same three statements');
is(scalar(grep { /non-transactional DDL/ } @warnings), 0,
  '... and says nothing about atomicity -- the notice an operator needs is gone, '
. 'while the implicit COMMIT on each statement leaves the batch just as unatomic');

# 2b. clear the force and the class declaration answers again. undef DELETES
# the tier-1 slot rather than tombstoning it (core karr #137), so this falls
# through to the declaration and not to core's determination tier.
$storage->_use_transactional_ddl(undef);
is($storage->_use_transactional_ddl, 0,
  'clearing the force hands the question back to the declaration');

@MyTest::MySQL::SpyStorage::TXN_DO = ();
$dbh->{stmts} = [];
@warnings     = ();

{
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $deploy->_execute_ddl($dbh, $DDL);
}

is(scalar @MyTest::MySQL::SpyStorage::TXN_DO, 0,
  'answering 0, the DDL loop is not bracketed at all');
is(scalar @{ $dbh->{stmts} }, 3,
  '... and still runs every statement, one at a time');
is(scalar(grep { /non-transactional DDL/ } @warnings), 1,
  '... with core\'s one-time notice, which is the accurate statement here: '
. 'recovery is re-running the upgrade against live state, not a rollback');

done_testing;
