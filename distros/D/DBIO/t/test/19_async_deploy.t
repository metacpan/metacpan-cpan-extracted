use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util 'blessed';

use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;
use DBIO::ResultSource::View;

# karr #73: the generic async deploy pipeline lives in core DBIO::Storage::Async
# (hoisted from dbio-postgresql-ev): deploy_async + _install_ddl / _ddl_class,
# _execute_ddl_async (each statement through the _query_async_pinned seam),
# _drop_statements_for, and the ADR-0026 transactional-DDL probe. This drives
# that orchestration through a fake, fully-synchronous transport -- no event
# loop, no real database.

# --- A synchronous, contract-compliant Future (as in 15_async_orchestration) -
{
  package Test::SyncFuture;
  sub done { my $c = shift; bless { failed => 0, result => [@_] }, ref($c) || $c }
  sub fail { my ($c, $e) = @_; bless { failed => 1, error => $e, result => [] }, ref($c) || $c }
  sub is_ready  { 1 }
  sub is_failed { $_[0]->{failed} ? 1 : 0 }
  sub get {
    my $self = shift;
    die $self->{error} if $self->{failed};
    return wantarray ? @{ $self->{result} } : $self->{result}[0];
  }
  sub then {
    my ($self, $on_done, $on_fail) = @_;
    if ($self->{failed}) {
      return $self unless $on_fail;
      return _dispatch($on_fail, $self->{error});
    }
    return _dispatch($on_done, @{ $self->{result} });
  }
  sub _dispatch {
    my ($cb, @args) = @_;
    my @r = eval { $cb->(@args) };
    return __PACKAGE__->fail($@) if $@;
    return $r[0]
      if @r == 1 && Scalar::Util::blessed($r[0]) && $r[0]->isa(__PACKAGE__);
    return __PACKAGE__->done(@r);
  }
}

# --- A fake pool (acquire + acquire_txn hand out one conn) ------------------
{
  package Test::SyncPool;
  sub new { bless { released => [], available => 1 }, shift }
  sub acquire     { Test::SyncFuture->done('CONN') }
  sub acquire_txn { Test::SyncFuture->done('CONN') }
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
{
  package Test::Owner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
}

# --- Fake schema + sources for _drop_statements_for -------------------------
{
  package Test::Source;
  sub new  { my ($c, %a) = @_; bless { %a }, $c }
  sub name { $_[0]->{name} }

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
    View   => Test::ViewSource->new(name => 'my_view'),        # skipped: view
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
    if (exists $opt{txn}) {
      # _owner_storage holds the owner WEAKLY (production: the sync storage owns
      # the async backend, not the reverse). Keep a strong ref on the backend so
      # the fake owner survives for the probe.
      $self->{_test_owner} = Test::Owner->new($opt{txn});
      $self->_owner_storage($self->{_test_owner});
    }
    return $self;
  }

  sub future_class { 'Test::SyncFuture' }
  sub pool         { $_[0]->{pool} ||= Test::SyncPool->new }
  sub _ddl_class   { 'Test::DDL' }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, bind => $bind, conn => $conn, pinned => 1 };
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
  isa_ok $f, 'Test::SyncFuture', '_execute_ddl_async returns a Future';
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
# _drop_statements_for: tables only, skips views + non-identifier names
# ---------------------------------------------------------------------------
{
  my $b = Test::DeployBackend->new(txn => 1);
  my $sql = $b->_drop_statements_for(drop_schema());
  my @drops = split /\n\n/, $sql;
  is_deeply \@drops,
    [ 'DROP TABLE IF EXISTS artist CASCADE;', 'DROP TABLE IF EXISTS cd CASCADE;' ],
    '_drop_statements_for emits IF EXISTS ... CASCADE for tables in source order';
  unlike $sql, qr/my_view/,   'view source skipped';
  unlike $sql, qr/SELECT 1/,  'scalar-ref (subselect) name skipped';
  unlike $sql, qr/has space/, 'non-identifier name skipped';
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

done_testing;
