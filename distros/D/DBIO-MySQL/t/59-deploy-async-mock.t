use strict;
use warnings;

use Test::More;

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::MySQL::Deploy ();
use DBIO::MySQL::DDL ();
use DBIO::SQL::Util ();
use File::Temp ();

# OFFLINE coverage for deploy_async on the future_io transport (karr k46).
#
# WHY THIS TEST EXISTS. DBIO::MySQL::Storage::Async inherits core's generic
# deploy_async (DBIO::Storage::Async, core karr k73), but that machinery asks
# the transport ONE question -- _ddl_class -- and core's default answer is a
# croak ("Subclass must override _ddl_class to support deploy_async"). Until
# k46 this adapter left the seam unfilled, so deploy_async sat in the public
# API and died the moment anyone called it, while the ev backend
# (DBIO::MySQL::EV::Storage) had it. These tests pin that the seam stays
# filled, that it names the SAME generator the sync MySQL deploy pipeline uses
# (so async and sync deploy emit byte-identical DDL), and that the inherited
# machinery really drives that DDL through this transport's own submit/collect
# seams -- on the MariaDB convention subclass too, which fills nothing itself
# and must inherit the seam.
#
# It is a mock test on purpose: everything asserted here is decided on this
# side of the wire (which generator, which statements, in which order, on which
# connection, with or without a transaction). Whether the generated DDL parses
# on a real server is the live suite's question.

# The future_io transport base (DBIO::Async::Storage) ships in dbio-async,
# which is a recommends only -- load the adapters defensively so a minimal
# install skips instead of dying at compile time.
BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

# --- fake DBD handle ---------------------------------------------------------
#
# A DBI-shaped handle that records the statements it is asked to run. It
# answers BOTH bindings (mysql_* and mariadb_*) so the very same fake plays a
# DBD::mysql and a DBD::MariaDB handle -- which is what lets the two runs below
# be compared statement for statement. Which of the two it plays it says the
# way a DBI handle does, in {Driver}{Name}: the transport picks the binding by
# the connection's DBD, not by its own class (karr k60).
#
# The socket fd handed to the Future::IO watcher is a real fd (a temp file),
# because the transport dups it for Future::IO->poll; a regular file is always
# readable, so the poll settles at once and no event loop is needed.

{
  package MyTest::MySQL::FakeSth;
  sub new {
    my ($class, %args) = @_;
    return bless {
      %args,
      NUM_OF_FIELDS    => 0,   # DDL produces no result set
      mysql_insertid   => 0,
      mariadb_insertid => 0,
    }, $class;
  }
  # execute() returns immediately on an async binding; errors surface when the
  # result is collected, so the statement is recorded as submitted either way.
  sub execute {
    my $self = shift;
    push @{ $self->{log} }, $self->{sql};
    $self->{bind} = [@_];
    return 1;
  }
  sub mysql_async_ready    { 1 }
  sub mariadb_async_ready  { 1 }
  sub more_results { 0 }   # one result set (karr k73)
  sub mysql_async_result   { $_[0]->_result }
  sub mariadb_async_result { $_[0]->_result }
  sub _result {
    my ($self) = @_;
    die "$self->{fail}\n" if $self->{fail};
    return 0;
  }
}

{
  package MyTest::MySQL::FakeDbh;
  sub new {
    my ($class, %args) = @_;
    my $fh = File::Temp->new;
    return bless {
      Driver        => { Name => $args{driver} || 'mysql' },
      Active        => 1,
      log           => [],
      prepare_attrs => [],
      fh            => $fh,
      fail          => $args{fail},
    }, $class;
  }
  sub err { undef }
  sub prepare {
    my ($self, $sql, $attrs) = @_;
    push @{ $self->{prepare_attrs} }, $attrs;
    return MyTest::MySQL::FakeSth->new(
      sql  => $sql,
      log  => $self->{log},
      fail => $self->{fail},
    );
  }
  sub mysql_fd       { fileno $_[0]->{fh} }
  sub mariadb_sockfd { fileno $_[0]->{fh} }
  sub disconnect     { $_[0]->{Active} = 0 }
}

# A pool with the DBIO::Storage::PoolBase contract. Counting acquire/release is
# what proves the whole DDL batch runs on ONE pinned connection and gives it
# back afterwards, on the failure path too.
{
  package MyTest::MySQL::FakePool;
  use Future ();
  sub new {
    my ($class, %args) = @_;
    return bless {
      conns => [], acquired => 0, released => 0,
      fail => $args{fail}, driver => $args{driver},
    }, $class;
  }
  sub acquire {
    my ($self) = @_;
    $self->{acquired}++;
    my $conn = { dbh => MyTest::MySQL::FakeDbh->new(
      fail => $self->{fail}, driver => $self->{driver},
    ) };
    push @{ $self->{conns} }, $conn;
    return Future->done($conn);
  }
  sub acquire_txn { $_[0]->acquire }
  sub release     { $_[0]{released}++ }
  sub shutdown    { }
  sub available   { 1 }
}

# Two tables plus a unique constraint: enough shape that the generated DDL is
# more than one statement (the loop is the point) without turning this into a
# DDL-generator test -- that is t/23-ddl-legacy-alias-size.t.
{
  package DeployAsync::MySQL::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MySQL');
}
{
  package DeployAsync::MySQL::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('deploy_async_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 128 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);
}
{
  package DeployAsync::MySQL::Schema::Result::CD;
  use DBIO;

  __PACKAGE__->table('deploy_async_cd');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    artist_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 256 },
  );
  __PACKAGE__->set_primary_key('id');
}
DeployAsync::MySQL::Schema->register_class(
  Artist => 'DeployAsync::MySQL::Schema::Result::Artist');
DeployAsync::MySQL::Schema->register_class(
  CD => 'DeployAsync::MySQL::Schema::Result::CD');

# The owning sync storage is held for the lifetime of the test: the async
# _owner_storage setter weakens its reference, and the non-transactional
# branch below is only reached because that owner answers the driver's
# _use_transactional_ddl(0). Without an owner the same branch would be taken by
# core's no-owner default, and the assertion would sample core, not this driver.
my @owners;

sub build_storage {
  my (%args) = @_;
  my $async_class = $args{class}       || 'DBIO::MySQL::Storage::Async';
  my $owner_class = $args{owner_class} || 'DBIO::MySQL::Storage';

  my $owner = $owner_class->new;
  push @owners, $owner;

  my $storage = $async_class->new(undef);
  $storage->_owner_storage($owner);

  my $pool = MyTest::MySQL::FakePool->new(fail => $args{fail}, driver => $args{driver});
  $storage->{pool} = $pool;

  return ($storage, $pool);
}

# The statements the loop is expected to run, derived from the generator itself
# and split exactly the way core splits them -- so this asserts the WIRING
# (same generator, every statement, in order), not a frozen copy of the DDL.
my $install_ddl = DBIO::MySQL::DDL->install_ddl('DeployAsync::MySQL::Schema');
my @expected_ddl =
  grep { !/^\s*--/ } DBIO::SQL::Util::_split_statements($install_ddl);

cmp_ok scalar(@expected_ddl), '>', 1,
  'the fixture schema generates a multi-statement DDL batch (there is a loop to test)';

# --- 1. the seam itself ------------------------------------------------------

is(DBIO::MySQL::Storage::Async->_ddl_class, 'DBIO::MySQL::DDL',
  '_ddl_class names the MySQL install-DDL generator');
is(DBIO::MySQL::Storage::Async->_ddl_class, DBIO::MySQL::Deploy->_ddl_class,
  '... the SAME generator the sync MySQL deploy pipeline uses '
. '(so async and sync deploy emit byte-identical DDL)');

isnt(DBIO::MySQL::Storage::Async->can('_ddl_class'),
     DBIO::Storage::Async->can('_ddl_class'),
  '... and it is a real override, not core\'s croaking abstract seam');

# --- 2. the MariaDB convention subclass INHERITS it --------------------------
#
# The MariaDB adapter adds nothing of its own (karr k60). The install DDL
# is a property of the SERVER dialect, not of the DBD binding (karr k28, ADR
# 0021), so a second _ddl_class there would be a place for the two to drift.

is(DBIO::MySQL::Storage::MariaDB::Async->_ddl_class, 'DBIO::MySQL::DDL',
  'the MariaDB convention adapter answers the same generator');
is(DBIO::MySQL::Storage::MariaDB::Async->can('_ddl_class'),
   DBIO::MySQL::Storage::Async->can('_ddl_class'),
  '... by resolving to the very same coderef -- inherited, not repeated');
{
  no strict 'refs';
  ok !defined *{'DBIO::MySQL::Storage::MariaDB::Async::_ddl_class'}{CODE},
    '... with nothing of its own in the subclass (nowhere to drift)';
}

# --- 3. deploy_async: every statement, one connection, no transaction --------

my @async_stmts;
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my ($storage, $pool) = build_storage;

  ok !$storage->_use_transactional_ddl,
    'MySQL DDL is reported non-transactional (ADR 0026) -- no false atomicity wrap';

  my $f = $storage->deploy_async('DeployAsync::MySQL::Schema');
  isa_ok $f, 'Future', 'deploy_async returns a Future';

  ok eval { $f->get; 1 },
    'deploy_async completes (the _ddl_class croak is gone -- karr k46)' or diag $@;
  ok $f->is_done && !$f->is_failed, 'deploy_async succeeded';

  is $pool->{acquired}, 1, 'the whole DDL batch ran on exactly one acquired connection';
  is $pool->{released}, 1, 'that connection was released again (no pool leak)';

  @async_stmts = @{ $pool->{conns}[0]{dbh}{log} };
  is_deeply \@async_stmts, \@expected_ddl,
    'every generated DDL statement ran, in order, through the transport\'s own '
  . 'submit/collect seams'
    or diag explain \@async_stmts;

  is_deeply $pool->{conns}[0]{dbh}{prepare_attrs}[0], { async => 1 },
    '... over the async binding of the connection\'s DBD, here DBD::mysql';

  ok !(grep { /^\s*(?:BEGIN|START TRANSACTION|COMMIT)\b/i } @async_stmts),
    'no BEGIN/COMMIT around the batch -- MySQL implicitly commits each DDL (ADR 0026)';

  # ADR 0026's contract for a non-transactional engine: the operator is told
  # the batch is not atomic. Keyed per message for the whole process, so it can
  # only be asserted on the first deploy through this class.
  ok scalar(grep { /non-transactional DDL on DBIO::MySQL::Storage::Async/ } @warnings),
    'the non-transactional DDL notice names this transport (ADR 0026)'
    or diag explain \@warnings;
}

# --- 4. the sync deploy pipeline runs the same statements --------------------
#
# Same generator (asserted above) plus the same split-and-execute is the whole
# of "byte-identical DDL". This drives core's real DBIO::Deploy::Base::_execute_ddl
# through a real DBIO::MySQL::Deploy, over the same generated DDL text, and
# compares statement for statement with what deploy_async ran.

{
  package MyTest::MySQL::DeployDbh;
  sub new { bless { stmts => [] }, shift }
  sub do  { push @{ $_[0]->{stmts} }, $_[1]; 1 }
}
{
  package MyTest::MySQL::DeploySchema;
  sub new { my ($class, %args) = @_; bless { %args }, $class }
  sub storage { $_[0]->{storage} }
}

{
  local $SIG{__WARN__} = sub { };   # core's sync one-shot notice, not under test here

  my $sync_storage = DBIO::MySQL::Storage->new;
  my $dbh = MyTest::MySQL::DeployDbh->new;
  my $deploy = DBIO::MySQL::Deploy->new(
    schema => MyTest::MySQL::DeploySchema->new(storage => $sync_storage),
  );
  $deploy->_execute_ddl($dbh, $install_ddl);

  is_deeply $dbh->{stmts}, \@async_stmts,
    'the sync deploy pipeline runs exactly the statements deploy_async ran';
}

# --- 5. the inherited seam really drives the MariaDB adapter -----------------

{
  local $SIG{__WARN__} = sub { };   # its own one-shot notice, already covered above

  my ($storage, $pool) = build_storage(
    class       => 'DBIO::MySQL::Storage::MariaDB::Async',
    owner_class => 'DBIO::MySQL::Storage::MariaDB',
    driver      => 'MariaDB',
  );
  my $f = $storage->deploy_async('DeployAsync::MySQL::Schema');
  ok eval { $f->get; 1 }, 'deploy_async works on the MariaDB adapter too' or diag $@;

  is_deeply [ @{ $pool->{conns}[0]{dbh}{log} } ], \@async_stmts,
    '... running the same statements as the MySQL adapter -- the inherited seam '
  . 'is what generated them';
  is_deeply $pool->{conns}[0]{dbh}{prepare_attrs}[0], { mariadb_async => 1 },
    '... over DBD::MariaDB\'s own async binding';
}

# --- 6. add_drop_table: DROPs first, one per table source --------------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage;
  my $f = $storage->deploy_async('DeployAsync::MySQL::Schema', { add_drop_table => 1 });
  ok eval { $f->get; 1 }, 'deploy_async with add_drop_table succeeded' or diag $@;

  my @log   = @{ $pool->{conns}[0]{dbh}{log} };
  my @drops = grep { /^DROP TABLE IF EXISTS/ } @log;
  is scalar(@drops), 2, 'one DROP TABLE IF EXISTS per table source';
  is_deeply [ sort @drops ],
    [ 'DROP TABLE IF EXISTS `deploy_async_artist` CASCADE',
      'DROP TABLE IF EXISTS `deploy_async_cd` CASCADE' ],
    'the DROPs name the mapped table names';
  is scalar(@log), scalar(@drops) + scalar(@expected_ddl),
    'the DROP pre-pass is prepended to the install DDL, nothing dropped from it';
  like $log[0], qr/^DROP TABLE IF EXISTS/,
    'the DROPs run BEFORE the CREATEs (idempotent re-run)';
}

# --- 7. failure path: the connection still goes back to the pool -------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage(fail => 'DDL boom');
  my $f = $storage->deploy_async('DeployAsync::MySQL::Schema');
  ok !eval { $f->get; 1 }, 'deploy_async fails when a statement errors';
  like scalar($f->failure), qr/DDL boom/, 'the failure carries the server error';
  is scalar(@{ $pool->{conns}[0]{dbh}{log} }), 1,
    'the loop stops at the first failing statement (no blind continue)';
  is $pool->{released}, 1, 'the connection is released on the failure path (no pool leak)';
}

# --- 8. the sync ->get wrapper takes the same path ---------------------------

{
  local $SIG{__WARN__} = sub { };

  my ($storage, $pool) = build_storage;
  ok eval { $storage->deploy('DeployAsync::MySQL::Schema'); 1 },
    'sync deploy() on the async storage completes via ->get' or diag $@;
  is_deeply [ @{ $pool->{conns}[0]{dbh}{log} } ], \@async_stmts,
    '... running the same statements as deploy_async';
}

done_testing;
