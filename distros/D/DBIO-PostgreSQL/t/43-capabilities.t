use strict;
use warnings;
use Test::More;

# Offline test for what DBIO::PostgreSQL::Storage says about DDL and
# transactions. No DBI, no DSN, no server: the answers below are facts about
# the engine and the DDL this driver emits, and reading them never touches a
# handle. (The version-gated capabilities, supports_upsert and
# supports_upsert_where, need a mocked server version and live in
# t/41-upsert-on-conflict.t.)

use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Diff::Type;
use DBIO::Deploy::Base ();

# --- transactional_ddl: declared 1 ------------------------------------------
#
# Paired with get_inherited(), which is defined only for a value this class set
# itself. Asserting the value alone would pass just as well if the driver
# declared nothing and rested on a core default that core is free to change --
# which is precisely the state this file was written to end.

is(DBIO::PostgreSQL::Storage->_use_transactional_ddl, 1,
  'transactional_ddl is 1 -- PostgreSQL rolls DDL back with its transaction');

isnt(DBIO::PostgreSQL::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

# --- the per-statement exception: ALTER TYPE ... ADD VALUE ------------------
#
# PostgreSQL's DDL is transactional with one exception this driver can emit.
# Before server 12 the engine rejects ALTER TYPE ... ADD VALUE outright inside
# a transaction block; from 12 on it takes it, but the new label is unusable
# until commit -- so a diff that adds a value and then references it fails on
# every version. The hook is what keeps that one statement out of the bracket.

my $pg = DBIO::PostgreSQL::Storage->new;

ok !$pg->_ddl_statement_is_transactional(
  q{ALTER TYPE "public"."mood" ADD VALUE 'ok';}),
  'ALTER TYPE ... ADD VALUE is not transaction-safe';

# INTENT: the pattern has to match what the driver ACTUALLY emits, not a form
# invented here. This asks the diff op itself, so the two cannot drift apart
# -- a change to Diff::Type's sprintf that this hook stopped recognising would
# silently put the statement back inside the transaction.
{
  my $op = DBIO::PostgreSQL::Diff::Type->new(
    action       => 'add_value',
    type_key     => '"public"."mood"',
    added_values => ['superb'],
  );

  my @stmts = grep { length } split /;\s*/, $op->as_sql;
  ok scalar(@stmts), 'the add_value op renders at least one statement';

  ok !$pg->_ddl_statement_is_transactional($_),
    "the op's own SQL is recognised: $_"
    for @stmts;
}

# Several values become several statements; every one of them is the exception.
{
  my $op = DBIO::PostgreSQL::Diff::Type->new(
    action       => 'add_value',
    type_key     => 'mood',
    added_values => [qw( a b c )],
  );

  my @stmts = grep { length } split /;\s*/, $op->as_sql;
  is scalar(@stmts), 3, 'one statement per added value';
  is scalar(grep { !$pg->_ddl_statement_is_transactional($_) } @stmts), 3,
    '... and each is kept out of the transaction';
}

# --- everything else keeps its bracket --------------------------------------
#
# The narrowness is the point. A blanket /ALTER\s+TYPE/ would quietly cost the
# transactional ALTER TYPE forms their atomicity, and they are forms this
# driver's diff can emit.
for my $safe (
  q{CREATE TABLE "artist" (id serial PRIMARY KEY)},
  q{ALTER TABLE "artist" ADD COLUMN "mood" mood},
  q{CREATE TYPE "mood" AS ENUM ('ok', 'sad')},
  q{ALTER TYPE "mood" RENAME VALUE 'sad' TO 'blue'},
  q{ALTER TYPE "addr" ADD ATTRIBUTE "zip" text},
  q{DROP TYPE "mood" CASCADE},
  q{CREATE INDEX "idx" ON "artist" ("mood")},
) {
  ok $pg->_ddl_statement_is_transactional($safe),
    "transaction-safe, keeps its bracket: $safe";
}

# A value that merely CONTAINS the words must not trip the pattern: it is a
# literal being written, not a statement kind.
ok $pg->_ddl_statement_is_transactional(
  q{INSERT INTO "log" ("msg") VALUES ('ALTER TYPE x ADD VALUE y')}),
  'the words inside a literal do not make a statement an exception';

# --- end to end through core's _execute_ddl ---------------------------------
#
# This path is the whole point of the declaration. DBIO::Deploy::Base
# ::_execute_ddl brackets DDL in $storage->txn_do only when the storage reports
# transactional DDL; otherwise it runs statement-at-a-time and carps once that
# nothing is atomic. Exercised against core's real _execute_ddl with a real
# PostgreSQL storage -- DBIO::PostgreSQL::Deploy is not involved, the
# capability is what core keys on.
{
  package MyTest::Pg::SpyStorage;
  our @ISA = ('DBIO::PostgreSQL::Storage');
  # Declares nothing of its own -- transactional_ddl comes down from the
  # driver. That is deliberate: while the declaration was still pending, this
  # file had to set the capability on the spy to exercise the grouping at all,
  # and a spy that keeps doing so passes whatever the driver says.
  our @TXN_DO;
  sub txn_do { my ($self, $code) = @_; push @TXN_DO, 1; return $code->() }
  # Core only brackets a handle the storage owns (core k131), so the spy has to
  # own the fake one it is handed.
  sub _dbh { $_[0]->{fake_dbh} }
}
{
  package MyTest::Pg::FakeDbh;
  sub new { bless { stmts => [] }, shift }
  sub do { push @{ $_[0]->{stmts} }, $_[1]; 1 }
}
{
  package MyTest::Pg::FakeSchema;
  sub new { my ($class, %args) = @_; bless { %args }, $class }
  sub storage { $_[0]->{storage} }
}

sub _spy_deploy {
  my ($dbh) = @_;
  @MyTest::Pg::SpyStorage::TXN_DO = ();
  my $storage = MyTest::Pg::SpyStorage->new;
  $storage->{fake_dbh} = $dbh;
  return DBIO::Deploy::Base->new(
    schema => MyTest::Pg::FakeSchema->new(storage => $storage),
  );
}

# A batch of nothing but transaction-safe statements is one run, and one run is
# one bracket -- identical to wrapping the whole loop.
{
  my $dbh    = MyTest::Pg::FakeDbh->new;
  my $deploy = _spy_deploy($dbh);

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $deploy->_execute_ddl(
      $dbh,
      qq{CREATE TABLE t1 (id serial PRIMARY KEY);\n}
      . q{CREATE TABLE t2 (id serial PRIMARY KEY);},
    );
  }

  is scalar(@MyTest::Pg::SpyStorage::TXN_DO), 1,
    'an all-safe batch is bracketed in one txn_do';
  is scalar(@{ $dbh->{stmts} }), 2,
    '... and still runs every statement';

  # The absence of the notice is the user-visible half of this ticket: an
  # operator deploying to PostgreSQL was being told the DDL was not atomic,
  # which was true, and should not have been.
  is scalar(grep { /non-transactional DDL/ } @warnings), 0,
    '... without core\'s non-transactional-DDL notice';
}

# A failure mid-loop must reach the surrounding txn_do rather than be
# swallowed inside it -- that propagation is what makes the ROLLBACK happen,
# and it is the reason a caller can re-run a failed deploy at all.
{
  package MyTest::Pg::DyingDbh;
  sub new { bless { stmts => [] }, shift }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{stmts} }, $sql;
    die "boom on statement " . scalar(@{ $self->{stmts} }) . "\n"
      if @{ $self->{stmts} } == 2;
    return 1;
  }
}

{
  my $dbh    = MyTest::Pg::DyingDbh->new;
  my $deploy = _spy_deploy($dbh);

  eval {
    $deploy->_execute_ddl(
      $dbh,
      qq{CREATE TABLE t1 (id serial PRIMARY KEY);\n}
      . qq{CREATE TABLE t2 (id serial PRIMARY KEY);\n}
      . q{CREATE TABLE t3 (id serial PRIMARY KEY);},
    );
    1;
  };

  like $@, qr/boom on statement 2/,
    'a failing statement propagates out through the txn_do bracket';
  is scalar(@{ $dbh->{stmts} }), 2,
    '... and the loop stops there instead of running the remaining DDL';
}

# ... and the exception splits that bracket rather than defeating it: core
# groups the batch by the hook, so the enum extension runs bare between two
# bracketed runs instead of costing the whole diff its transaction.
{
  my $dbh    = MyTest::Pg::FakeDbh->new;
  my $deploy = _spy_deploy($dbh);

  {
    local $SIG{__WARN__} = sub { };   # the split is announced; not under test
    $deploy->_execute_ddl($dbh,
      qq{CREATE TYPE "mood" AS ENUM ('ok');\n}
    . qq{ALTER TYPE "mood" ADD VALUE 'sad';\n}
    . q{ALTER TABLE "artist" ADD COLUMN "m" mood;});
  }

  is scalar(@MyTest::Pg::SpyStorage::TXN_DO), 2,
    'the enum extension splits the batch: two bracketed runs round it';
  is scalar(@{ $dbh->{stmts} }), 3,
    '... every statement still runs';
  is $dbh->{stmts}[1], q{ALTER TYPE "mood" ADD VALUE 'sad'},
    '... in the order the diff wrote them';
}

done_testing;
