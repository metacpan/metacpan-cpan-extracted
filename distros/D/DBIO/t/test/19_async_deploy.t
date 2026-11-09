use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;
use DBIO::ResultSource::View;
use DBIO::Storage::PoolBase;

# The generic async deploy pipeline lives in core DBIO::Storage::Async
# (hoisted from dbio-postgresql-ev): deploy_async + _install_ddl / _ddl_class,
# _execute_ddl_async (each statement through the _query_async_pinned seam),
# _drop_statements_for, and the ADR-0026 transactional-DDL probe. This drives
# that orchestration through a fake, fully-synchronous transport -- no event
# loop, no real database.

# --- A fake pool (acquire + acquire_txn hand out one conn) ------------------
{
  package Test::SyncPool;
  sub new { bless { released => [], available => 1 }, shift }
  sub acquire     { DBIO::Test::Future->done('CONN') }
  sub acquire_txn { DBIO::Test::Future->done('CONN') }
  sub release     { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub available   { $_[0]->{available} }
  sub shutdown    { $_[0]->{available} = 0 }
}

# --- A fake DDL class: install_ddl($schema) returns canned SQL --------------
{
  package Test::DDL;
  sub install_ddl {
    my ($class, $schema) = @_;
    return "CREATE TABLE artist (id int);\n"
         . "CREATE TABLE cd (id int);\n"
         . "-- a trailing comment;";
  }
}

# --- A fake owner sync storage, to drive the transactional_ddl probe --------
# Deliberately defines NO per-statement hook: this is the hook-default case
# (every statement transaction-safe), the same shape a driver that never
# declares _ddl_statement_is_transactional presents.
{
  package Test::Owner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
}

# --- A transactional owner WITH a per-statement hook (k132 / k199 grouping) --
# Transactional engine, but a statement matching $nontxn_re is declared
# non-transactional and so must run outside a transaction -- the async mirror of
# the sync Capabilities hook _ddl_statement_is_transactional (e.g. PostgreSQL's
# ALTER TYPE ... ADD VALUE).
{
  package Test::GroupOwner;
  sub new { bless { nontxn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { 1 }
  sub _ddl_statement_is_transactional {
    my ($self, $stmt) = @_;
    return $stmt =~ $self->{nontxn} ? 0 : 1;
  }
}

# --- A pool that hands out DISTINCT connection tokens ------------------------
# acquire_txn -> "TXN<n>", acquire -> "POOL<n>", so a test can prove which
# statements ran on a pinned txn connection vs a bare pooled one (connection
# identity, not just SQL text -- House Rule 7/11), and can prove each connection
# was released exactly once via release_count, with no leak.
{
  package Test::CountingPool;
  sub new { bless { released => [], release_count => {}, n => 0, available => 1 }, shift }
  sub acquire     { my $s = shift; DBIO::Test::Future->done('POOL' . ++$s->{n}) }
  sub acquire_txn { my $s = shift; DBIO::Test::Future->done('TXN'  . ++$s->{n}) }
  sub release {
    my ($s, $c) = @_;
    push @{ $s->{released} }, $c;
    $s->{release_count}{$c}++;
    return 1;
  }
  sub available { $_[0]->{available} }
  sub shutdown  { $_[0]->{available} = 0 }
}

# --- A real PoolBase holding ONE connection ---------------------------------
# DBIO::Storage::PoolBase's own acquire/release/waiter queue, capped at one
# connection: a connection that is never released makes the next acquire wait
# forever (a pending Future), which is exactly the symptom of a leak. The
# release log records each connection handed back.
{
  package Test::OnePool;
  use base 'DBIO::Storage::PoolBase';

  sub new {
    my ($class) = @_;
    return $class->SUPER::new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _create_connection { bless { id => ++$_[0]->{_next_id} }, 'Test::OneConn' }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

# --- Fake schema + sources for _drop_statements_for -------------------------
{
  package Test::Source;
  sub new  { my ($c, %a) = @_; bless { %a }, $c }
  sub name { $_[0]->{name} }
  sub result_class { $_[0]->{result_class} }

  package Test::ViewSource;
  our @ISA = ('Test::Source', 'DBIO::ResultSource::View');

  package Test::DropSchema;
  sub new     { bless { order => $_[1], src => $_[2] }, $_[0] }
  sub sources { @{ $_[0]->{order} } }
  sub source  { $_[0]->{src}{ $_[1] } }
}

sub drop_schema {
  my %src = (
    Artist => Test::Source->new(name => 'artist'),
    CD     => Test::Source->new(name => 'cd'),
    View   => Test::ViewSource->new(name => 'my_view'),        # dropped first: a real view
    Custom => Test::Source->new(name => \'SELECT 1'),          # skipped: scalar ref
    Weird  => Test::Source->new(name => 'has space'),          # skipped: not an identifier
  );
  return Test::DropSchema->new([qw(Artist CD View Custom Weird)], \%src);
}

# --- The fake deploy backend -----------------------------------------------
# A concrete DBIO::Storage::Async overriding only the seam hooks, all resolving
# immediately. Captures every query; per-instance {txn} controls the
# transactional-DDL probe (via a fake owner); {fail_on} makes a statement fail.
{
  package Test::DeployBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, %opt) = @_;
    my $self = $class->SUPER::new(undef);
    $self->{captured} = [];
    $self->{fail_on}  = $opt{fail_on};
    $self->{throw_on} = $opt{throw_on};           # die before any Future exists
    $self->{ddl}      = $opt{ddl};                # optional DDL override
    $self->{pool}     = $opt{pool} if $opt{pool}; # optional richer pool
    # _owner_storage holds the owner WEAKLY (production: the sync storage owns
    # the async backend, not the reverse). Keep a strong ref on the backend so
    # the fake owner survives for the probe.
    if ($opt{owner}) {
      $self->{_test_owner} = $opt{owner};
      $self->_owner_storage($opt{owner});
    }
    elsif (exists $opt{txn}) {
      $self->{_test_owner} = Test::Owner->new($opt{txn});
      $self->_owner_storage($self->{_test_owner});
    }
    return $self;
  }

  sub future_class { 'DBIO::Test::Future' }
  sub pool         { $_[0]->{pool} ||= Test::SyncPool->new }
  sub _ddl_class   { 'Test::DDL' }

  # Optional per-instance DDL override so a grouping test can feed a known set of
  # statements; otherwise the canned Test::DDL install_ddl.
  sub _install_ddl {
    my ($self, $schema) = @_;
    return $self->{ddl} if defined $self->{ddl};
    return $self->SUPER::_install_ddl($schema);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, conn => $conn, pinned => 1 };
    die "dispatch croaked on: $sql\n"
      if $self->{throw_on} && $sql =~ $self->{throw_on};
    if ($self->{fail_on} && $sql =~ $self->{fail_on}) {
      return $self->future_class->fail("DDL failed on: $sql\n");
    }
    return $self->future_class->done;
  }

  sub _sqls { map { $_->{sql} } @{ $_[0]->{captured} } }
}

# ---------------------------------------------------------------------------
# _ddl_class abstract default croaks
# ---------------------------------------------------------------------------
{
  my $bare = DBIO::Storage::Async->new(undef);
  throws_ok { $bare->_ddl_class } qr/must override _ddl_class/,
    'bare _ddl_class croaks';
}

# ---------------------------------------------------------------------------
# _install_ddl defaults to _ddl_class->install_ddl($schema)
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  like $b->_install_ddl('schema'), qr/CREATE TABLE artist/,
    '_install_ddl routes through _ddl_class->install_ddl($schema)';
}

# ---------------------------------------------------------------------------
# _use_transactional_ddl probe: delegates to the owner; 0 when no owner
# ---------------------------------------------------------------------------
{
  my $none = DBIO::Storage::Async->new(undef);
  is $none->_use_transactional_ddl, 0,
    '_use_transactional_ddl is 0 when no owner storage is wired';

  my $on  = Test::DeployBackend->new(txn => 1);
  my $off = Test::DeployBackend->new(txn => 0);
  is $on->_use_transactional_ddl, 1,
    'delegates to owner _use_transactional_ddl (transactional)';
  is $off->_use_transactional_ddl, 0,
    'delegates to owner _use_transactional_ddl (non-transactional)';
}

# ---------------------------------------------------------------------------
# _execute_ddl_async: splits, skips comments, each stmt via _query_async_pinned
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  my $f = $b->_execute_ddl_async('PIN', "ONE;\n-- skip me;\nTWO;");
  isa_ok $f, 'DBIO::Test::Future', '_execute_ddl_async returns a Future';
  ok $f->is_ready && !$f->is_failed, 'resolves on the last statement';
  is_deeply [ $b->_sqls ], [ 'ONE', 'TWO' ],
    '_execute_ddl_async ran real statements, skipped the comment';
  ok !( grep { !$_->{pinned} } @{ $b->{captured} } ),
    'every DDL statement ran through the pinned seam';
  is scalar( grep { $_->{conn} eq 'PIN' } @{ $b->{captured} } ), 2,
    'both statements ran on the supplied pinned connection';
  is_deeply $b->{captured}[0]{bind}, [],
    'DDL statements carry an empty bind list';

  # First-statement failure fails the Future and stops the chain.
  my $bf = Test::DeployBackend->new(txn => 1, fail_on => qr/TWO/);
  my $ff = $bf->_execute_ddl_async('PIN', "ONE;\nTWO;\nTHREE;");
  ok $ff->is_failed, 'a failing statement fails the Future';
  throws_ok { $ff->get } qr/DDL failed on: TWO/, 'the DDL error propagates';
  is_deeply [ $bf->_sqls ], [ 'ONE', 'TWO' ],
    'the chain stops at the first failing statement (THREE never ran)';
}

# ---------------------------------------------------------------------------
# _drop_statements_for: views first, then tables; names that are no plain
# identifier stay out
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  my $sql = $b->_drop_statements_for(drop_schema());
  my @drops = split /\n\n/, $sql;
  is_deeply \@drops,
    [
      'DROP VIEW IF EXISTS my_view;',
      'DROP TABLE IF EXISTS artist CASCADE;',
      'DROP TABLE IF EXISTS cd CASCADE;',
    ],
    '_drop_statements_for drops the declared views, then IF EXISTS ... CASCADE for tables in source order';
  unlike $sql, qr/SELECT 1/,  'scalar-ref (subselect) name skipped';
  unlike $sql, qr/has space/, 'non-identifier name skipped';
}

# ---------------------------------------------------------------------------
# views: readers before the views they read (reverse of the install order),
# virtual views and subselect names stay out
# ---------------------------------------------------------------------------
{
  my %src = (
    A_Top   => Test::ViewSource->new(name => 'v_top', result_class => 'My::Top',
                 deploy_depends_on => { 'My::Base' => 1 }),
    M_Other => Test::ViewSource->new(name => 'v_other', result_class => 'My::Other'),
    Z_Base  => Test::ViewSource->new(name => 'v_base', result_class => 'My::Base'),
    Virt    => Test::ViewSource->new(name => 'v_virtual', result_class => 'My::Virt', is_virtual => 1),
    Sub     => Test::ViewSource->new(name => \'SELECT 2', result_class => 'My::Sub'),
    T       => Test::Source->new(name => 'tbl'),
  );
  my $schema = Test::DropSchema->new([qw(Z_Base T Sub Virt M_Other A_Top)], \%src);
  my $b = Test::DeployBackend->new(txn => 1);
  is_deeply [ split /\n\n/, $b->_drop_statements_for($schema) ],
    [
      'DROP VIEW IF EXISTS v_other;',
      'DROP VIEW IF EXISTS v_top;',
      'DROP VIEW IF EXISTS v_base;',
      'DROP TABLE IF EXISTS tbl CASCADE;',
    ],
    'views dropped in reverse install order, before the tables';
}

# ---------------------------------------------------------------------------
# the quoting of an identifier is a hook of the storage
# ---------------------------------------------------------------------------
{
  {
    package Test::TickBackend;
    our @ISA = ('Test::DeployBackend');
    sub _ddl_quote_ident { "`$_[1]`" }
  }
  my $b = Test::TickBackend->new(txn => 1);
  is_deeply [ split /\n\n/, $b->_drop_statements_for(drop_schema()) ],
    [
      'DROP VIEW IF EXISTS `my_view`;',
      'DROP TABLE IF EXISTS `artist` CASCADE;',
      'DROP TABLE IF EXISTS `cd` CASCADE;',
    ],
    'a storage overriding _ddl_quote_ident quotes the names of the drop statements';
}

# ---------------------------------------------------------------------------
# deploy_async, transactional engine: BEGIN, pinned DDL, COMMIT
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  my $f = $b->deploy_async('schema');
  ok $f->is_ready && !$f->is_failed, 'deploy_async resolves on a transactional engine';
  is_deeply [ $b->_sqls ],
    [ 'BEGIN', 'CREATE TABLE artist (id int)', 'CREATE TABLE cd (id int)', 'COMMIT' ],
    'transactional deploy brackets the DDL batch in BEGIN/COMMIT';
  ok !( grep { !$_->{pinned} } @{ $b->{captured} } ),
    'BEGIN, DDL and COMMIT all ran on the pinned txn connection';
  is $b->{pool}{released}[0], 'CONN', 'txn connection released after COMMIT';
}

# ---------------------------------------------------------------------------
# deploy_async add_drop_table: DROPs prepended before the CREATEs
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  $b->deploy_async(drop_schema(), { add_drop_table => 1 })->get;
  is_deeply [ $b->_sqls ],
    [
      'BEGIN',
      'DROP VIEW IF EXISTS my_view',
      'DROP TABLE IF EXISTS artist CASCADE',
      'DROP TABLE IF EXISTS cd CASCADE',
      'CREATE TABLE artist (id int)',
      'CREATE TABLE cd (id int)',
      'COMMIT',
    ],
    'add_drop_table prepends DROP statements ahead of the install DDL';
}

# ---------------------------------------------------------------------------
# deploy_async failure on a transactional engine rolls the batch back
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1, fail_on => qr/CREATE TABLE cd/);
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'deploy_async fails when a DDL statement fails';
  is_deeply [ $b->_sqls ],
    [ 'BEGIN', 'CREATE TABLE artist (id int)', 'CREATE TABLE cd (id int)', 'ROLLBACK' ],
    'a mid-batch DDL failure triggers ROLLBACK (transactional atomicity)';
}

# ---------------------------------------------------------------------------
# deploy_async, NON-transactional engine (ADR 0026): no txn, one-shot warning
# ---------------------------------------------------------------------------
{
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };

  my $b = Test::DeployBackend->new(txn => 0);
  my $f = $b->deploy_async('schema');
  ok $f->is_ready && !$f->is_failed, 'deploy_async resolves on a non-transactional engine';
  is_deeply [ $b->_sqls ],
    [ 'CREATE TABLE artist (id int)', 'CREATE TABLE cd (id int)' ],
    'non-transactional deploy runs statement-at-a-time with no BEGIN/COMMIT wrap';
  is $b->{pool}{released}[0], 'CONN', 'the single pooled connection is released';
  is scalar(@warns), 1, 'exactly one warning emitted';
  like $warns[0], qr/non-transactional DDL on .*Test::DeployBackend/,
    'the warning names the non-transactional class';

  # The one-shot is keyed on the message: a second deploy on the SAME class does
  # not warn again.
  my $b2 = Test::DeployBackend->new(txn => 0);
  $b2->deploy_async('schema')->get;
  is scalar(@warns), 1, 'the non-transactional warning is one-shot per class';
}

# ---------------------------------------------------------------------------
# non-transactional failure fails the Future and still releases the connection
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };    # swallow the (already-tested) one-shot warn
  my $b = Test::DeployBackend->new(txn => 0, fail_on => qr/CREATE TABLE artist/);
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'non-transactional deploy fails when a statement fails';
  throws_ok { $f->get } qr/DDL failed on/, 'the failure propagates';
  is $b->{pool}{released}[0], 'CONN',
    'connection released even when a non-transactional statement fails';
}

# ---------------------------------------------------------------------------
# sync deploy() fallback blocks on the async Future via ->get
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  lives_ok { $b->deploy('schema') } 'sync deploy() blocks on the async Future via ->get';
  is_deeply [ $b->_sqls ],
    [ 'BEGIN', 'CREATE TABLE artist (id int)', 'CREATE TABLE cd (id int)', 'COMMIT' ],
    'sync deploy() drove the same transactional DDL batch';
}

# ===========================================================================
# k199: deploy_async honours the per-statement DDL-transactional hook (k132)
# with the SAME order/grouping as the sync DBIO::Deploy::Base path. A run of
# transaction-safe statements is bracketed in ONE txn_do_async on a pinned
# connection; a statement the hook declares non-transactional runs on its OWN
# pooled connection, outside any transaction.
# ===========================================================================

# ---------------------------------------------------------------------------
# [txn group] [outlier outside txn] [txn group]: grouping, order, and PINNING
# proven by connection identity (not just SQL text -- House Rule 7/11)
# ---------------------------------------------------------------------------
{
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };

  my $ddl = "CREATE TABLE a (id int);\n"
          . "ALTER TYPE mood ADD VALUE 'ok';\n"     # the non-transactional outlier
          . "CREATE TABLE b (id int);";
  my $b = Test::DeployBackend->new(
    owner => Test::GroupOwner->new(qr/ADD VALUE/),
    ddl   => $ddl,
    pool  => Test::CountingPool->new,
  );

  my $f = $b->deploy_async('schema');
  ok $f->is_ready && !$f->is_failed, 'mixed-grouping deploy_async resolves';

  is_deeply [ $b->_sqls ],
    [
      'BEGIN', 'CREATE TABLE a (id int)', 'COMMIT',
      "ALTER TYPE mood ADD VALUE 'ok'",
      'BEGIN', 'CREATE TABLE b (id int)', 'COMMIT',
    ],
    'txn group, then the outlier bare (no BEGIN/COMMIT), then the next txn group -- sync order preserved';

  # Connection identity proves the pinning, not just the SQL text.
  my @cap = @{ $b->{captured} };
  is $cap[0]{conn}, $cap[1]{conn}, 'group 1 CREATE pinned to its BEGIN connection';
  is $cap[1]{conn}, $cap[2]{conn}, 'group 1 COMMIT on the same pinned connection';
  is $cap[4]{conn}, $cap[5]{conn}, 'group 2 CREATE pinned to its BEGIN connection';
  is $cap[5]{conn}, $cap[6]{conn}, 'group 2 COMMIT on the same pinned connection';

  isnt $cap[3]{conn}, $cap[0]{conn},
    'the outlier did NOT run on the group-1 txn connection (it is outside that transaction)';
  isnt $cap[3]{conn}, $cap[4]{conn},
    'the outlier did NOT run on the group-2 txn connection either';
  isnt $cap[0]{conn}, $cap[4]{conn},
    'the two txn groups used two distinct pinned connections';

  like $cap[3]{conn}, qr/^POOL/, 'the outlier ran on a plain pooled (acquire) connection';
  like $cap[0]{conn}, qr/^TXN/,  'group 1 ran on a txn (acquire_txn) connection';
  like $cap[4]{conn}, qr/^TXN/,  'group 2 ran on a txn (acquire_txn) connection';

  is_deeply $b->{pool}{release_count},
    { $cap[0]{conn} => 1, $cap[3]{conn} => 1, $cap[4]{conn} => 1 },
    'every connection (2 txn + 1 pooled outlier) released exactly once';

  is scalar(@warns), 1, 'exactly one split warning';
  like $warns[0], qr/split DDL batch on .*Test::DeployBackend.*split into 3 runs/,
    'the split warning names the class and the run count';
}

# ---------------------------------------------------------------------------
# consecutive outliers COALESCE into ONE run on ONE pooled connection
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };    # swallow the (already-tested) split warning
  my $ddl = "CREATE TABLE a (id int);\n"
          . "ALTER TYPE mood ADD VALUE 'x';\n"
          . "ALTER TYPE mood ADD VALUE 'y';\n"
          . "CREATE TABLE b (id int);";
  my $b = Test::DeployBackend->new(
    owner => Test::GroupOwner->new(qr/ADD VALUE/),
    ddl   => $ddl,
    pool  => Test::CountingPool->new,
  );
  $b->deploy_async('schema')->get;

  is_deeply [ $b->_sqls ],
    [
      'BEGIN', 'CREATE TABLE a (id int)', 'COMMIT',
      "ALTER TYPE mood ADD VALUE 'x'",
      "ALTER TYPE mood ADD VALUE 'y'",
      'BEGIN', 'CREATE TABLE b (id int)', 'COMMIT',
    ],
    'two adjacent outliers run back-to-back, bracketed by neither BEGIN nor COMMIT';

  my @cap = @{ $b->{captured} };
  # The two outliers are captured[3] and captured[4].
  is $cap[3]{conn}, $cap[4]{conn},
    'both consecutive outliers ran on the SAME pooled connection (one run, one acquire)';
  isnt $cap[3]{conn}, $cap[0]{conn}, 'the outlier run is not the group-1 txn connection';
  isnt $cap[3]{conn}, $cap[5]{conn}, 'the outlier run is not the group-2 txn connection';
  like $cap[3]{conn}, qr/^POOL/, 'the coalesced outlier run used a single pooled connection';

  is $b->{pool}{release_count}{ $cap[3]{conn} }, 1,
    'the single pooled connection for the two outliers was released exactly once';
  is scalar(keys %{ $b->{pool}{release_count} }), 3,
    'exactly three connections used (2 txn groups + 1 coalesced outlier run) -- proves coalescing';
}

# ---------------------------------------------------------------------------
# hook default: an owner that never defines _ddl_statement_is_transactional is
# treated as all-transactional -- one run, one BEGIN/COMMIT, no split warning
# ---------------------------------------------------------------------------
{
  ok !Test::Owner->can('_ddl_statement_is_transactional'),
    'the default owner defines no per-statement hook';

  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };

  my $b = Test::DeployBackend->new(
    txn  => 1,
    ddl  => "CREATE TABLE a (id int);\nCREATE TABLE b (id int);\nCREATE TABLE c (id int);",
    pool => Test::CountingPool->new,
  );
  $b->deploy_async('schema')->get;

  is_deeply [ $b->_sqls ],
    [ 'BEGIN', 'CREATE TABLE a (id int)', 'CREATE TABLE b (id int)', 'CREATE TABLE c (id int)', 'COMMIT' ],
    'no per-statement hook => the whole batch is one transactional run';
  my @cap = @{ $b->{captured} };
  is scalar( grep { $_->{sql} eq 'BEGIN' }  @cap ), 1, 'exactly one BEGIN';
  is scalar( grep { $_->{sql} eq 'COMMIT' } @cap ), 1, 'exactly one COMMIT';
  is scalar(keys %{ $b->{pool}{release_count} }), 1, 'exactly one connection used';
  is scalar(@warns), 0, 'no split warning when nothing splits';
}

# ---------------------------------------------------------------------------
# error path: a failure in a LATER run of a split batch. Earlier runs stay
# applied, the failing txn run rolls back, and EVERY connection is released
# exactly once -- no double release, no leak (DONE #4)
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };
  my $ddl = "CREATE TABLE a (id int);\n"
          . "ALTER TYPE mood ADD VALUE 'x';\n"
          . "CREATE TABLE b (id int);";
  my $b = Test::DeployBackend->new(
    owner   => Test::GroupOwner->new(qr/ADD VALUE/),
    ddl     => $ddl,
    pool    => Test::CountingPool->new,
    fail_on => qr/CREATE TABLE b/,
  );
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'a failure in a later run fails the deploy';
  throws_ok { $f->get } qr/DDL failed on: CREATE TABLE b/, 'the DDL error propagates';

  is_deeply [ $b->_sqls ],
    [
      'BEGIN', 'CREATE TABLE a (id int)', 'COMMIT',   # group 1 committed
      "ALTER TYPE mood ADD VALUE 'x'",                # outlier applied
      'BEGIN', 'CREATE TABLE b (id int)', 'ROLLBACK', # group 2 rolled back
    ],
    'group 1 committed, outlier applied, the failing group 2 rolled back';

  ok !( grep { $_ != 1 } values %{ $b->{pool}{release_count} } ),
    'every acquired connection released exactly once (no double release)';
  is scalar(keys %{ $b->{pool}{release_count} }), 3,
    'all three connections (2 txn + 1 pooled) released, none leaked';
}

# ---------------------------------------------------------------------------
# error path: a failing OUTLIER releases its pooled connection exactly once,
# and the chain short-circuits so the later txn run never even acquires
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };
  my $ddl = "CREATE TABLE a (id int);\n"
          . "ALTER TYPE mood ADD VALUE 'x';\n"
          . "CREATE TABLE b (id int);";
  my $b = Test::DeployBackend->new(
    owner   => Test::GroupOwner->new(qr/ADD VALUE/),
    ddl     => $ddl,
    pool    => Test::CountingPool->new,
    fail_on => qr/ADD VALUE/,
  );
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'a failing outlier fails the deploy';

  is_deeply [ $b->_sqls ],
    [
      'BEGIN', 'CREATE TABLE a (id int)', 'COMMIT',   # group 1 committed
      "ALTER TYPE mood ADD VALUE 'x'",                # outlier attempted, failed
    ],
    'the chain stops at the failing outlier: the later txn group never ran';

  ok !( grep { $_ != 1 } values %{ $b->{pool}{release_count} } ),
    'the group-1 txn conn and the failing outlier conn each released exactly once';
  is scalar(keys %{ $b->{pool}{release_count} }), 2,
    'only two connections acquired (group 1 + outlier); group 2 never acquired -- no leak';
  is $b->{pool}{n}, 2,
    'the pool stopped at 2 acquisitions -- the failure short-circuited the chain';
}

# ===========================================================================
# karr k229: a DDL dispatch that dies SYNCHRONOUSLY -- the transport's
# prepare/query croaks before a Future exists -- must still hand its pooled
# connection back. The non-transactional branches released the connection only
# in the continuations of the statement Future, so a die before that Future
# existed skipped both: the deploy failed, and the connection stayed checked
# out. With a pool of one, every later acquire then waited forever.
#
# Each case below asserts the same three things on a real one-connection pool:
# the deploy fails with the dispatch's own error, the connection was released
# exactly once, and the next acquire resolves at once.
# ===========================================================================

sub next_acquire_resolves {
  my ($b, $label) = @_;
  my $next = $b->pool->acquire;
  ok $next->is_ready, "$label: the next acquire resolves";
  $b->pool->release($next->get) if $next->is_ready;
}

# ---------------------------------------------------------------------------
# Non-transactional engine: the whole batch runs on one pooled connection, and
# its FIRST statement croaks. Before the fix: no release, next acquire pending.
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };    # the (already-tested) one-shot warning
  my $b = Test::DeployBackend->new(
    txn      => 0,
    pool     => Test::OnePool->new,
    throw_on => qr/CREATE TABLE artist/,
  );
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'non-txn engine, sync croak: the deploy fails';
  throws_ok { $f->get } qr/dispatch croaked on: CREATE TABLE artist/,
    'non-txn engine, sync croak: with the dispatch\'s own error';
  is_deeply [ $b->_sqls ], [ 'CREATE TABLE artist (id int)' ],
    'non-txn engine, sync croak: nothing ran after the croaking statement';
  is_deeply $b->pool->{release_log}, [ 1 ],
    'non-txn engine, sync croak: the connection was released exactly once';
  next_acquire_resolves($b, 'non-txn engine, sync croak');
}

# ---------------------------------------------------------------------------
# Transactional engine, a statement the per-statement hook declares
# non-transactional: that run takes its own pooled connection outside any
# transaction -- the second non-transactional branch -- and croaks there.
# Before the fix: the txn run's connection came back, the outlier's did not.
# ---------------------------------------------------------------------------
{
  local $SIG{__WARN__} = sub { };    # the (already-tested) split warning
  my $b = Test::DeployBackend->new(
    owner    => Test::GroupOwner->new(qr/ADD VALUE/),
    ddl      => "CREATE TABLE a (id int);\n"
              . "ALTER TYPE mood ADD VALUE 'x';\n"
              . "CREATE TABLE b (id int);",
    pool     => Test::OnePool->new,
    throw_on => qr/ADD VALUE/,
  );
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'outlier run, sync croak: the deploy fails';
  throws_ok { $f->get } qr/dispatch croaked on: ALTER TYPE/,
    'outlier run, sync croak: with the dispatch\'s own error';
  is_deeply [ $b->_sqls ],
    [ 'BEGIN', 'CREATE TABLE a (id int)', 'COMMIT', "ALTER TYPE mood ADD VALUE 'x'" ],
    'outlier run, sync croak: the chain stopped at the croaking statement';
  is_deeply $b->pool->{release_log}, [ 1, 1 ],
    'outlier run, sync croak: the one connection came back after each run';
  next_acquire_resolves($b, 'outlier run, sync croak');
}

# ---------------------------------------------------------------------------
# A transaction-safe run croaking synchronously. This path was already safe --
# txn_do_async treats the die as a callback failure -- and is here so the fix
# is held to all three branches: ROLLBACK is sent, the connection comes back.
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(
    txn      => 1,
    pool     => Test::OnePool->new,
    throw_on => qr/CREATE TABLE artist/,
  );
  my $f = $b->deploy_async('schema');
  ok $f->is_failed, 'txn run, sync croak: the deploy fails';
  throws_ok { $f->get } qr/dispatch croaked on: CREATE TABLE artist/,
    'txn run, sync croak: with the dispatch\'s own error';
  is_deeply [ $b->_sqls ], [ 'BEGIN', 'CREATE TABLE artist (id int)', 'ROLLBACK' ],
    'txn run, sync croak: the transaction was rolled back';
  is_deeply $b->pool->{release_log}, [ 1 ],
    'txn run, sync croak: the connection was released exactly once';
  next_acquire_resolves($b, 'txn run, sync croak');
}

done_testing;
