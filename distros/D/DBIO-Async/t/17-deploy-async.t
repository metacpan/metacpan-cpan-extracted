use strict;
use warnings;
use Test::More;
use Test::Exception;

use Future;
use Scalar::Util ();
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;

# OFFLINE test for deploy_async on this transport (karr k15 point 7).
#
# THE QUESTION THE TICKET ASKED, ANSWERED. Nothing in this dist mentions
# _ddl_class or deploy_async, and the ticket asks whether that is a test gap or
# a feature gap. It is a TEST gap. deploy_async is concrete in core
# (DBIO::Storage::Async) and needs exactly two things from a backend: a pinned
# connection reachable as txn_conn -- which this transport supplies through
# _txn_conn_accessor -- and a _ddl_class. _ddl_class names a DB-specific DDL
# generator ('DBIO::PostgreSQL::DDL', 'DBIO::MySQL::DDL'), so a DB-AGNOSTIC
# transport base cannot supply one and must not invent one: under ADR 0004 it
# would be the first piece of DB-specific code in this dist. It belongs to the
# driver adapter, which is where dbio-postgresql added it (their k67). So there
# is nothing to implement here -- but there is something to pin, in both
# directions:
#
#  * that the missing _ddl_class fails LOUDLY rather than deploying nothing,
#    so a driver adapter that forgets it finds out at once (section 1), and
#  * that once a driver supplies one, the inherited deploy_async really does
#    run over THIS transport's machinery -- its pool, its pinned query seam,
#    its connection accounting (sections 2 to 4). That is the half core's own
#    tests cannot show, because core has no pool.
#
# The transport is real throughout; the mock supplies only the DB-specific
# seams and, where a driver would, a _ddl_class.

{
  package FakeDDL17;
  our $DDL = "CREATE TABLE artist (id INTEGER);\n\nCREATE TABLE cd (id INTEGER);\n";
  sub install_ddl { return $DDL }
}

{
  package DeployMock;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { r => $r, w => $w, id => ++$self->{_next_id} };
  }
  sub _shutdown_pool_connection { close $_[1]{r}; close $_[1]{w} }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, { sql => $sql, conn => $conn->{id} };
    die "$self->{fail_sql}{$sql}\n"
      if $self->{fail_sql} && $self->{fail_sql}{$sql};
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $b, 1;
    return Future->done(1);
  }
}

# What a driver adapter adds, and nothing more.
{
  package DeployMockWithDDL;
  our @ISA = ('DeployMock');
  sub _ddl_class { 'FakeDDL17' }
}

# A second adapter class for the transactional scenario. Distinct on purpose:
# core's "not atomic" warning is one-shot per message and the message names the
# class, so reusing DeployMockWithDDL there would make "no warning was emitted"
# true merely because section 2 had already spent the one shot.
{
  package DeployMockTxn;
  our @ISA = ('DeployMockWithDDL');
}

# An owning sync storage that declares its DDL transactional (ADR 0026).
{
  package OwnerStorage17;
  sub new { bless { txn_ddl => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn_ddl} }
}

sub new_storage {
  my ($class, %args) = @_;
  my $storage = $class->new(undef);
  $storage->{_next_id} = 0;
  $storage->{wire}     = [];
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  $storage->_owner_storage($args{owner}) if $args{owner};
  return $storage;
}

sub sqls  { [ map { $_->{sql} } @{ $_[0]->{wire} } ] }
sub conns { my %s = map { $_->{conn} => 1 } @{ $_[0]->{wire} }; [ sort keys %s ] }

# deploy_async warns once per message on the non-transactional path (ADR 0026),
# which is informational and belongs in the test log, not on STDERR.
sub deploy_quietly {
  my ($storage, @args) = @_;
  my @warnings;
  my $f;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $f = $storage->deploy_async(@args);
    eval { $f->get };
  }
  note "deploy warned: $_" for @warnings;
  return ($f, \@warnings);
}

# ---------------------------------------------------------------------------
# 1. No _ddl_class: the transport declines, loudly. This is the assertion that
#    says the absence is a decision rather than an oversight -- a DB-agnostic
#    base has no DDL generator to name, and guessing one would be the first
#    DB-specific line in this dist (ADR 0004).
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('DeployMock');

  throws_ok { $storage->deploy_async(undef) }
    qr/Subclass must override _ddl_class to support deploy_async/,
    'deploy_async on the bare transport croaks for a _ddl_class -- the DDL '
    . 'generator is the driver adapter\'s to name, and its absence is loud';

  is_deeply sqls($storage), [],
    '... before anything reached the wire, so a forgetful adapter cannot half-'
    . 'deploy a schema';
}

# ---------------------------------------------------------------------------
# 2. With the driver's _ddl_class supplied, the inherited deploy_async runs
#    over this transport: one pooled connection, every statement through the
#    PINNED query seam, released exactly once.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('DeployMockWithDDL');

  my ($f, $warnings) = deploy_quietly($storage, undef);

  ok $f->is_done, 'deploy_async completes with a driver-supplied _ddl_class';

  is_deeply sqls($storage),
    [ 'CREATE TABLE artist (id INTEGER)', 'CREATE TABLE cd (id INTEGER)' ],
    'every statement of the generated DDL reached the wire, in order';

  is scalar @{ conns($storage) }, 1,
    'all of it ran on ONE connection -- DDL split across pool connections '
    . 'would defeat any ordering the generator relies on';

  is $storage->pool->available, 1,
    'and that connection went back to the pool exactly once';
  is scalar @{ $storage->pool->{_connections} }, 1,
    '... the pool never grew a second connection';

  is scalar(grep { /not atomic/ } @$warnings), 1,
    'the non-transactional DDL path warns once (ADR 0026): with no owning '
    . 'storage declaring transactional DDL, the loop is not atomic and says so';
}

# ---------------------------------------------------------------------------
# 3. A statement fails mid-DDL. The remaining statements must not run, the
#    caller must see the failure -- and the connection must still come back,
#    which on a size-1 pool is the difference between a failed deploy and a
#    deadlocked process.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage('DeployMockWithDDL');
  $storage->{fail_sql} = { 'CREATE TABLE cd (id INTEGER)' => 'syntax error' };

  my ($f) = deploy_quietly($storage, undef);

  ok $f->is_failed, 'a failing DDL statement fails the deploy';
  like scalar($f->failure), qr/syntax error/, '... with the engine\'s error';

  is_deeply sqls($storage),
    [ 'CREATE TABLE artist (id INTEGER)', 'CREATE TABLE cd (id INTEGER)' ],
    'the statements after the failing one were not attempted';

  is $storage->pool->available, 1,
    'the connection still came back to the pool -- a failed deploy must not '
    . 'leak the slot it borrowed';
}

# ---------------------------------------------------------------------------
# 4. An engine whose DDL IS transactional (ADR 0026, declared by the owning
#    sync storage) gets the bracket instead: core routes deploy through
#    txn_do_async, which on this transport means BEGIN/COMMIT on the pinned
#    connection and no "not atomic" warning.
# ---------------------------------------------------------------------------

{
  # Held in a lexical on purpose: _owner_storage weakens its reference (core
  # avoids the storage <-> backend cycle), so an owner kept nowhere else is
  # collected before deploy_async ever asks it anything.
  my $owner   = OwnerStorage17->new(1);
  my $storage = new_storage('DeployMockTxn', owner => $owner);

  my ($f, $warnings) = deploy_quietly($storage, undef);

  ok $f->is_done, 'the transactional deploy completes';

  is_deeply sqls($storage),
    [ 'BEGIN',
      'CREATE TABLE artist (id INTEGER)',
      'CREATE TABLE cd (id INTEGER)',
      'COMMIT' ],
    'the whole DDL batch is bracketed BEGIN..COMMIT on this transport\'s '
    . 'pinned connection (ADR 0026: only where DDL really is transactional)';

  is scalar @{ conns($storage) }, 1,
    'bracket and statements share the one pinned connection';
  is scalar(grep { /not atomic/ } @$warnings), 0,
    'and no "not atomic" warning is emitted for an engine that means it';

  is $storage->pool->available, 1, 'released exactly once afterwards';
}

# ---------------------------------------------------------------------------
# 5. A backend that has run deploy_async is freed when it is dropped, finished
#    or failed (core ed0f33a0e). deploy_async chained its runs and statements
#    through a sub holding itself, which kept the backend, its pool and the
#    connections in it for the life of the process. Only a transport shows
#    the pool and the connection: the pool is closed with the storage.
# ---------------------------------------------------------------------------

for my $case ([ finished => {} ], [ failed => { 'CREATE TABLE artist (id INTEGER)' => 'boom' } ]) {
  my ($label, $fail_sql) = @$case;
  my $storage = new_storage('DeployMockWithDDL');
  $storage->{fail_sql} = $fail_sql;

  my ($f) = deploy_quietly($storage);
  ok $f->is_ready, "deploy $label: the deploy has settled";
  is $f->is_failed ? 1 : 0, $label eq 'failed' ? 1 : 0, '... as expected';
  ok $storage->{pool} && @{ $storage->{pool}{_connections} }, '... a pool connection was opened';

  Scalar::Util::weaken(my $weak_storage = $storage);
  Scalar::Util::weaken(my $weak_pool    = $storage->{pool});
  undef $f;
  undef $storage;
  ok !defined $weak_storage, "deploy $label: the dropped backend is freed";
  ok !defined $weak_pool,    '... and its pool with it';
}

done_testing;
