use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
}

use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::QueryExecutor;
use DBIO::MySQL::Deploy ();
use DBIO::MySQL::DDL ();
use DBIO::SQL::Util ();

# OFFLINE coverage for $storage->deploy_async (karr #21).
#
# WHY this test exists: DBIO::MySQL::EV::Storage inherits core's generic
# deploy_async (DBIO::Storage::Async, core karr #73) but used to leave the
# _ddl_class seam unfilled -- so deploy_async was in the public API and died
# on the core croak ("Subclass must override _ddl_class") the moment anyone
# called it. Filling the seam is the whole fix; these tests pin that the seam
# stays filled, that it points at the SAME generator the sync deploy pipeline
# uses, and that the inherited machinery really drives MySQL DDL through this
# transport's own _query_async_pinned.
#
# It is a mock test on purpose: everything asserted here is decided on this
# side of the wire (which generator, which statements, which connection, how
# many acquires/releases, transactional or not). The live counterpart --
# whether the generated DDL parses on a real server -- is
# t/21-deploy-async-live.t.

# A fake EV::MariaDB-shaped connection that records every statement it runs.
# DDL carries no binds, so it lands on the ->query fast path (QueryExecutor
# only prepares when @$bind); prepare/execute are here so a regression that
# starts feeding binds through the DDL loop is still recorded, not silently
# dropped.
{
  package FakeConn;
  sub new     { bless { log => [], binds => [], fail => $_[1] }, $_[0] }
  sub query   { my ($s, $sql, $cb) = @_; push @{ $s->{log} }, $sql; $s->_reply($cb, $sql) }
  sub prepare { my ($s, $sql, $cb) = @_; $cb->(bless({ sql => $sql }, 'FakeStmt'), undef) if $cb }
  sub execute {
    my ($s, $stmt, $bind, $cb) = @_;
    push @{ $s->{log} }, $stmt->{sql};
    push @{ $s->{binds} }, [ @{ $bind || [] } ];
    $s->_reply($cb, $stmt->{sql});
  }
  sub close_stmt { my ($s, $stmt, $cb) = @_; $cb->(1) if $cb }
  # SELECT LAST_INSERT_ID() answers a fixed id, so the insert_async pin at the
  # bottom can see where that id ends up. No DDL statement matches.
  our $LII = 7;
  sub _reply {
    my ($s, $cb, $sql) = @_;
    return unless $cb;
    return $cb->(undef, $s->{fail}) if $s->{fail};
    return $cb->([ [ $LII ] ], undef) if ($sql // '') =~ /LAST_INSERT_ID/;
    return $cb->([], undef);
  }
}

# A pool with the DBIO::Storage::PoolBase contract: acquire returns a DONE
# Future over a connection, release hands it back. Counting both is what
# proves the DDL batch runs on ONE pinned connection and never leaks it.
{
  package FakePool;
  use Future ();
  sub new {
    my ($class, %args) = @_;
    bless { conns => [], acquired => 0, released => 0, fail => $args{fail} }, $class;
  }
  sub acquire {
    my $self = shift;
    $self->{acquired}++;
    my $conn = FakeConn->new($self->{fail});
    push @{ $self->{conns} }, $conn;
    return Future->done($conn);
  }
  sub acquire_txn { $_[0]->acquire }
  sub release     { $_[0]{released}++ }
  sub _lease      { 1 }   # the lease of a borrow (core k275, karr k91)
  sub shutdown    { }
  sub available   { 1 }
  # The transport reports the connection of a failed statement here when it is
  # gone (karr k55). This double keeps no idle list to keep one off.
  sub _mysql_report_if_gone { }
}

# Two tables plus a unique constraint: enough shape that the generated DDL is
# more than one statement (the loop is what we care about) without turning
# this into a DDL-generator test (that lives in dbio-mysql).
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
__PACKAGE__->load_components('MySQL');
__PACKAGE__->register_class(Artist => 'DeployMock::Result::Artist');
__PACKAGE__->register_class(CD     => 'DeployMock::Result::CD');

# Reserved and non-plain table names, and a real view (karr k96).
package DeployMock::Result::Order;
use base 'DBIO::Core';
__PACKAGE__->table('order');
__PACKAGE__->add_columns(
  id  => { data_type => 'integer', is_auto_increment => 1 },
  qty => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('id');

package DeployMock::Result::Dashed;
use base 'DBIO::Core';
__PACKAGE__->table('my-table');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
);
__PACKAGE__->set_primary_key('id');

package DeployMock::Result::OrderView;
use base 'DBIO::Core';
__PACKAGE__->table_class('DBIO::ResultSource::View');
__PACKAGE__->table('group');
__PACKAGE__->result_source_instance->is_virtual(0);
__PACKAGE__->result_source_instance->view_definition('SELECT id, qty FROM `order`');
__PACKAGE__->add_columns(
  id  => { data_type => 'integer' },
  qty => { data_type => 'integer' },
);

package DeployMock::ReservedSchema;
use base 'DBIO::Schema';
__PACKAGE__->load_components('MySQL');
__PACKAGE__->register_class(Order     => 'DeployMock::Result::Order');
__PACKAGE__->register_class(Dashed    => 'DeployMock::Result::Dashed');
__PACKAGE__->register_class(OrderView => 'DeployMock::Result::OrderView');

package main;

sub build_storage {
  my %args = @_;
  my $storage = DBIO::MySQL::EV::Storage->new(undef);
  my $pool = FakePool->new(%args);
  $storage->{pool}     = $pool;
  $storage->{executor} = DBIO::MySQL::EV::QueryExecutor->new;
  return ($storage, $pool);
}

# The statements core's loop is expected to run, derived from the generator
# itself -- so this test asserts the WIRING (same generator, every statement,
# in order), not a frozen copy of dbio-mysql's DDL output.
my @expected_ddl =
  grep { !/^\s*--/ }
  DBIO::SQL::Util::_split_statements(
    DBIO::MySQL::DDL->install_ddl('DeployMock::Schema')
  );

# --- the seam itself ---------------------------------------------------------

{
  my ($storage) = build_storage;

  is $storage->_ddl_class, 'DBIO::MySQL::DDL',
    '_ddl_class points at the MySQL install-DDL generator';
  is $storage->_ddl_class, DBIO::MySQL::Deploy->_ddl_class,
    'async deploy uses the SAME generator as the sync MySQL deploy pipeline '
    . '(identical DDL on both paths)';
  ok !$storage->_use_transactional_ddl,
    'MySQL DDL is reported non-transactional (ADR 0026) -- no false atomicity wrap';
}

# --- deploy_async: every statement, one connection, no transaction -----------

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my ($storage, $pool) = build_storage;
  my $f = $storage->deploy_async('DeployMock::Schema');
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; Futures settle from the idle watcher (karr k51)

  isa_ok $f, 'Future', 'deploy_async returns a Future';
  ok $f->is_ready, 'deploy_async settles (the _ddl_class croak is gone -- karr #21)';
  ok $f->is_done && !$f->is_failed, 'deploy_async succeeded';

  is $pool->{acquired}, 1, 'the whole DDL batch ran on exactly one acquired connection';
  is $pool->{released}, 1, 'that connection was released again (no pool leak)';

  is_deeply $pool->{conns}[0]{log}, \@expected_ddl,
    'every generated DDL statement ran, in order, on the pinned connection'
    or diag explain $pool->{conns}[0]{log};

  ok !(grep { /^\s*(?:BEGIN|START TRANSACTION|COMMIT)\b/i } @{ $pool->{conns}[0]{log} }),
    'no BEGIN/COMMIT around the batch -- MySQL implicitly commits each DDL (ADR 0026)';

  # The one-shot warning is the ADR 0026 contract for a non-transactional
  # engine: the user is told the batch is not atomic. It is keyed per message
  # for the whole process, so it can only be asserted on the first deploy here.
  ok scalar(grep { /non-transactional DDL on DBIO::MySQL::EV::Storage/ } @warnings),
    'non-transactional DDL warning names this class (ADR 0026)'
    or diag explain \@warnings;
}

# --- add_drop_table: DROPs first, one per table source -----------------------

{
  local $SIG{__WARN__} = sub { };   # one-shot warning already asserted above

  my ($storage, $pool) = build_storage;
  my $f = $storage->deploy_async('DeployMock::Schema', { add_drop_table => 1 });
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; Futures settle from the idle watcher (karr k51)
  ok $f->is_done, 'deploy_async with add_drop_table succeeded';

  my @log   = @{ $pool->{conns}[0]{log} };
  my @drops = grep { /^DROP TABLE IF EXISTS/ } @log;
  is scalar(@drops), 2, 'one DROP TABLE IF EXISTS per table source';
  is_deeply [ sort @drops ],
    [ 'DROP TABLE IF EXISTS `deploy_mock_artist` CASCADE',
      'DROP TABLE IF EXISTS `deploy_mock_cd` CASCADE' ],
    'DROPs name the mapped table names';
  is scalar(@log), scalar(@drops) + scalar(@expected_ddl),
    'DROP pre-pass is prepended to the install DDL, nothing dropped from it';
  like $log[0], qr/^DROP TABLE IF EXISTS/,
    'the DROPs run BEFORE the CREATEs (idempotent re-run)';
  like $log[-1], qr/^CREATE TABLE/,
    'the batch ends on the install DDL';
}

# --- add_drop_table: reserved and non-plain names are backticked (karr k96) --

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage;
  my $f = $storage->deploy_async('DeployMock::ReservedSchema', { add_drop_table => 1 });
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; Futures settle from the idle watcher (karr k51)
  ok $f->is_done, 'deploy_async with add_drop_table over reserved names succeeded'
    or diag scalar $f->failure;

  my @drops = grep { /^DROP / } @{ $pool->{conns}[0]{log} };
  like $drops[0], qr/^DROP VIEW IF EXISTS `group`$/,
    'the view is dropped first, backticked';
  is_deeply [ sort grep { /^DROP TABLE/ } @drops ],
    [ 'DROP TABLE IF EXISTS `my-table` CASCADE',
      'DROP TABLE IF EXISTS `order` CASCADE' ],
    'reserved and dashed table names carry backticks';
}

# --- failure path: the connection still goes back to the pool ----------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage(fail => 'DDL boom');
  my $f = $storage->deploy_async('DeployMock::Schema');
  EV::run(EV::RUN_NOWAIT());   # the fake answers inside dispatch; Futures settle from the idle watcher (karr k51)

  ok $f->is_ready,  'deploy_async settles on a DDL error';
  ok $f->is_failed, 'deploy_async fails when a statement errors';
  like scalar($f->failure), qr/DDL boom/, 'the failure carries the server error';
  is scalar(@{ $pool->{conns}[0]{log} }), 1,
    'the loop stops at the first failing statement (no blind continue)';
  is $pool->{released}, 1, 'connection released on the failure path (no pool leak)';
}

# --- the sync wrapper blocks on the same path --------------------------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage;
  ok eval { $storage->deploy('DeployMock::Schema'); 1 },
    'sync deploy() completes via ->get (dies on a failed Future)' or diag $@;
  is_deeply $pool->{conns}[0]{log}, \@expected_ddl,
    'sync deploy() ran the same statements as deploy_async';
}

# --- insert_async on the deployed schema: the ResultSource carries the id ----
# karr k41: t/21-deploy-async-live.t passed bare table names to insert_async
# and got a hashref WITHOUT the auto_increment id -- the dependent CD insert
# then wrote artist_id NULL. The contract (core ADR 0031 §3) is
# insert_async($source, \%row): only a source tells the transport which column
# SELECT LAST_INSERT_ID() belongs to. Pinned here with the very call shape the
# live test uses (a registered source of this schema), through the public
# insert_async, down to the bind of the dependent INSERT.

{
  my ($storage, $pool) = build_storage;
  my $artist_src = DeployMock::Schema->source('Artist');
  my $cd_src     = DeployMock::Schema->source('CD');

  my $artist = $storage->insert_async($artist_src, { name => 'live-smoke' })->get;
  is_deeply $artist, { name => 'live-smoke', id => $FakeConn::LII },
    'insert_async(<source>) returns the LAST_INSERT_ID() as the auto_increment id';

  my $cd = $storage->insert_async($cd_src,
    { artist_id => $artist->{id}, title => 'live-cd' })->get;
  is $cd->{id}, $FakeConn::LII, 'second source gets its own auto_increment id';

  my $cd_conn = $pool->{conns}[1];
  like $cd_conn->{log}[0], qr/^INSERT INTO `deploy_mock_cd`/,
    'the CD insert ran against the mapped table name (source unwrapped via ->name)';
  ok scalar(grep { defined $_ && $_ eq $FakeConn::LII } @{ $cd_conn->{binds}[0] }),
    'the dependent INSERT carries the artist id as a bind (not NULL -- the k41 failure)'
    or diag explain $cd_conn->{binds};
  is $pool->{acquired}, 2, 'one pinned connection per insert_async';
  is $pool->{released}, 2, 'both connections released after LAST_INSERT_ID()';
}

done_testing;
