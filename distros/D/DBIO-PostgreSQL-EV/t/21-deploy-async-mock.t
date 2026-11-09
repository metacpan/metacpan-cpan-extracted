use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::Deploy ();
use DBIO::PostgreSQL::DDL ();
use DBIO::SQL::Util ();

# OFFLINE coverage for $storage->deploy_async (karr k25).
#
# WHY this test exists: DBIO::PostgreSQL::EV::Storage used to carry its own
# deploy_async / _execute_ddl_async / _drop_statements_for, duplicating logic
# core grew generically (DBIO::Storage::Async, core karr k73). The refactor
# drops the local copies and fills only the _ddl_class seam. Two things make
# PostgreSQL a sharper test of that inherited machinery than the dbio-mysql-ev
# precedent (t/21-deploy-async-mock.t, karr dbio-mysql-ev k21):
#
#   1. PostgreSQL's DDL IS transactional (sync DBIO::PostgreSQL::Storage
#      declares _use_transactional_ddl(1)), so core's deploy_async takes the
#      txn_do_async branch, not the statement-at-a-time pooled branch MySQL
#      exercises. That branch is gated on _use_transactional_ddl probing the
#      OWNING sync storage (_owner_storage) -- get the wiring wrong and it
#      silently downgrades to non-transactional, losing rollback semantics.
#   2. The transactional branch calls $ctx->txn_conn on the transaction
#      context -- a name DBIO::PostgreSQL::EV::TransactionContext did NOT
#      expose before this ticket (it only had txn_pg). Without the txn_conn
#      alias added alongside this refactor, every deploy_async call on a real
#      connection would die "Can't locate object method txn_conn".
#
# Both are exercised here entirely offline (fake pool/connection), so this
# test would have failed loudly on either mistake without touching a real
# database. The live counterpart -- whether the generated DDL actually parses
# on a real server -- is t/21-deploy-async-live.t.

# A fake EV::Pg-shaped connection that records every statement it runs via
# query_params (the seam _query_async_pinned actually calls -- DDL carries no
# binds, but the real transport always dispatches through query_params, never
# the bind-less query() the old local copy used). fail_at makes exactly the
# Nth call (1-indexed, across BEGIN/DDL/COMMIT/ROLLBACK alike) fail, so a
# ROLLBACK issued after a mid-batch failure still succeeds -- proving the
# framework's cleanup path, not just the happy path.
{
  package FakeConn;
  sub new {
    my ($class, %args) = @_;
    bless { log => [], calls => 0, fail_at => $args{fail_at} }, $class;
  }
  sub query_params {
    my ($s, $sql, $bind, $cb) = @_;
    $s->{calls}++;
    push @{ $s->{log} }, $sql;
    if ($s->{fail_at} && $s->{calls} == $s->{fail_at}) {
      return $cb->(undef, 'DDL boom');
    }
    return $cb->([], undef);
  }
}

# A pool with the DBIO::Storage::PoolBase contract: acquire/acquire_txn each
# return a DONE Future over a fresh connection, release hands it back.
# Counting acquires/releases is what proves the whole DDL batch (transactional
# or not) runs on ONE connection and never leaks it.
{
  package FakePool;
  use Future ();
  sub new {
    my ($class, %args) = @_;
    bless { conns => [], acquired => 0, released => 0, fail_at => $args{fail_at} }, $class;
  }
  sub acquire {
    my $self = shift;
    $self->{acquired}++;
    my $conn = FakeConn->new(fail_at => $self->{fail_at});
    push @{ $self->{conns} }, $conn;
    return Future->done($conn);
  }
  sub acquire_txn { $_[0]->acquire }
  sub release     { $_[0]{released}++ }
  sub shutdown    { }
  sub available   { 1 }
}

# An _owner_storage stand-in that reports the sync PostgreSQL capability the
# real DBIO::PostgreSQL::Storage declares (_use_transactional_ddl(1)), without
# pulling in the real sync driver's connection machinery.
{
  package FakeOwner;
  sub _use_transactional_ddl { 1 }
}

# Two tables plus a unique constraint: enough shape that the generated DDL is
# more than one statement (the loop is what we care about) without turning
# this into a DDL-generator test (that lives in dbio-postgresql).
package DeployMock::Result::Artist;
use base 'DBIO::Core';
__PACKAGE__->table('deploy_mock_artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 128 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([qw( name )]);

package DeployMock::Result::CD;
use base 'DBIO::Core';
__PACKAGE__->table('deploy_mock_cd');
__PACKAGE__->add_columns(
  id        => { data_type => 'integer', is_auto_increment => 1 },
  artist_id => { data_type => 'integer' },
  title     => { data_type => 'varchar', size => 256 },
);
__PACKAGE__->set_primary_key('id');

package DeployMock::Schema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('PostgreSQL');
__PACKAGE__->register_class(Artist => 'DeployMock::Result::Artist');
__PACKAGE__->register_class(CD     => 'DeployMock::Result::CD');

package main;

sub build_storage {
  my %args = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  my $pool = FakePool->new(%args);
  $storage->{pool} = $pool;
  $storage->_owner_storage('FakeOwner') if delete $args{with_owner};
  return ($storage, $pool);
}

# The statements core's loop is expected to run, derived from the generator
# itself -- so this test asserts the WIRING (same generator, every statement,
# in order), not a frozen copy of dbio-postgresql's DDL output.
my @expected_ddl =
  grep { !/^\s*--/ }
  DBIO::SQL::Util::_split_statements(
    DBIO::PostgreSQL::DDL->install_ddl('DeployMock::Schema')
  );

# --- the seam itself ---------------------------------------------------------

{
  my ($storage) = build_storage;

  is $storage->_ddl_class, 'DBIO::PostgreSQL::DDL',
    '_ddl_class points at the PostgreSQL install-DDL generator';
  is $storage->_ddl_class, DBIO::PostgreSQL::Deploy->_ddl_class,
    'async deploy uses the SAME generator as the sync PostgreSQL deploy pipeline '
    . '(identical DDL on both paths)';
  ok !$storage->_use_transactional_ddl,
    'no _owner_storage wired -- capability probe conservatively answers false '
    . '(mirrors the sync DeploymentHandler default; karr k25 pitfall 1)';
}

# --- no owner wired: deploy_async falls back to the non-transactional branch -

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my ($storage, $pool) = build_storage;
  my $f = $storage->deploy_async('DeployMock::Schema');

  isa_ok $f, 'Future', 'deploy_async returns a Future';
  ok $f->is_done && !$f->is_failed, 'deploy_async succeeded';

  is $pool->{acquired}, 1, 'the whole DDL batch ran on exactly one acquired connection';
  is $pool->{released}, 1, 'that connection was released again (no pool leak)';

  is_deeply $pool->{conns}[0]{log}, \@expected_ddl,
    'every generated DDL statement ran, in order, with no BEGIN/COMMIT wrap'
    or diag explain $pool->{conns}[0]{log};

  ok scalar(grep { /non-transactional DDL on DBIO::PostgreSQL::EV::Storage/ } @warnings),
    'non-transactional DDL warning names this class when the capability is '
    . 'unknown (ADR 0026) -- the false-atomicity guard the local wrap used to bypass'
    or diag explain \@warnings;
}

# --- owner wired reporting transactional_ddl: the REAL PostgreSQL shape ------

{
  local $SIG{__WARN__} = sub { };   # non-transactional warning already asserted above

  my ($storage, $pool) = build_storage(with_owner => 1);
  ok $storage->_use_transactional_ddl,
    '_owner_storage reporting transactional_ddl flips the probe true '
    . '(what the real sync DBIO::PostgreSQL::Storage always reports)';

  my $f = $storage->deploy_async('DeployMock::Schema');

  ok $f->is_done && !$f->is_failed,
    'deploy_async succeeded through the transactional (txn_do_async) branch -- '
    . 'proves $ctx->txn_conn resolves on DBIO::PostgreSQL::EV::TransactionContext '
    . '(karr k25 pitfall 2)';

  is $pool->{acquired}, 1, 'one connection acquired via acquire_txn';
  is $pool->{released}, 1, 'connection released once, at the txn boundary';

  my @log = @{ $pool->{conns}[0]{log} };
  is $log[0], 'BEGIN', 'batch opens with BEGIN';
  is $log[-1], 'COMMIT', 'batch closes with COMMIT';
  is_deeply [ @log[1 .. $#log - 1] ], \@expected_ddl,
    'every generated DDL statement ran, in order, between BEGIN and COMMIT'
    or diag explain \@log;
}

# --- add_drop_table: DROPs first, one per table source, still transactional -

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage(with_owner => 1);
  my $f = $storage->deploy_async('DeployMock::Schema', { add_drop_table => 1 });
  ok $f->is_done, 'deploy_async with add_drop_table succeeded';

  my @log   = @{ $pool->{conns}[0]{log} };
  my @drops = grep { /^DROP TABLE IF EXISTS/ } @log;
  is scalar(@drops), 2, 'one DROP TABLE IF EXISTS per table source';
  is_deeply [ sort @drops ],
    [ 'DROP TABLE IF EXISTS deploy_mock_artist CASCADE',
      'DROP TABLE IF EXISTS deploy_mock_cd CASCADE' ],
    'DROPs name the mapped table names, quoted via the same DBIO::SQL::Util::_quote_ident '
    . 'DBIO::PostgreSQL::DDL uses (karr k25 pitfall 2) -- _split_statements strips the '
    . 'trailing ; before dispatch';
  is $log[0], 'BEGIN', 'still opens with BEGIN';
  is $log[-1], 'COMMIT', 'still closes with COMMIT';
  like $log[1], qr/^DROP TABLE IF EXISTS/, 'the DROPs run BEFORE the CREATEs (idempotent re-run)';
}

# --- failure path: ROLLBACK fires and the connection still goes back --------

{
  local $SIG{__WARN__} = sub { };

  # fail_at counts BEGIN as call #1, so #2 is the first DDL statement.
  my ($storage, $pool) = build_storage(with_owner => 1, fail_at => 2);
  my $f = $storage->deploy_async('DeployMock::Schema');

  ok $f->is_ready,  'deploy_async settles on a DDL error';
  ok $f->is_failed, 'deploy_async fails when a statement errors';
  like scalar($f->failure), qr/DDL boom/, 'the failure carries the server error';

  my @log = @{ $pool->{conns}[0]{log} };
  is_deeply \@log, [ 'BEGIN', $expected_ddl[0], 'ROLLBACK' ],
    'BEGIN, the one statement that ran before the failure, then ROLLBACK -- '
    . 'no statement after the failing one, atomicity preserved'
    or diag explain \@log;

  is $pool->{released}, 1, 'connection released on the failure path (no pool leak)';
}

# --- the sync wrapper blocks on the same path --------------------------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage(with_owner => 1);
  ok eval { $storage->deploy('DeployMock::Schema'); 1 },
    'sync deploy() completes via ->get (dies on a failed Future)' or diag $@;
  my @log = @{ $pool->{conns}[0]{log} };
  is_deeply [ @log[1 .. $#log - 1] ], \@expected_ddl,
    'sync deploy() ran the same statements as deploy_async, still BEGIN/COMMIT wrapped';
}

done_testing;
