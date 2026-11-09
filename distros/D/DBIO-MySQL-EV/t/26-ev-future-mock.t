use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k48: the transport's Futures must be able to wait
# on the EV loop, so that the blocking storage methods work.
#
# WHY: core DBIO::Storage::Async implements select, select_single, insert,
# update, delete, txn_do and deploy as `return $self->X_async(@_)->get` (ADR
# 0001). Every Future this transport returns is settled from the EV loop -- by
# an EV::MariaDB callback -- so it is still pending when ->get is called. A
# plain Future's get then calls await, which Future leaves to subclasses and by
# default dies: "... is not yet complete and does not provide ->await". Until
# k48 this transport's Futures were plain Futures, and every one of those
# methods died.
#
# What this file claims:
#   1. DBIO::MySQL::EV::Future's get waits for a Future the EV loop settles --
#      result and failure alike, also when called from inside an EV callback --
#      and dies at once, instead of spinning, when nothing left in the loop
#      could settle it. then / needs_all keep the class, so a chain waits too.
#   2. The storage hands that class to everything a blocking method waits on:
#      its own future_class, the pool's, the executor's Futures.
#   3. Through the REAL storage, pool and executor, with a fake EV::MariaDB
#      whose every operation completes on an EV timer, the blocking methods
#      return what their *_async siblings resolve with, and rethrow a failure.
#
# Without the repair, 2 and 3 fail: the calls die with the croak above.
#
# Every wait is bounded by an EV timer with keepalive(0): a wait that never
# returns sits in libev's C code, where an alarm does not fire (karr k46).

use EV;
use Future;
use DBIO::MySQL::EV::Future;
use DBIO::MySQL::EV::Storage;
use DBIO::MySQL::EV::Pool;
use DBIO::MySQL::EV::QueryExecutor;

my $EVF = 'DBIO::MySQL::EV::Future';

# Settle $f from the loop after $delay seconds.
sub settle_later {
  my ($delay, $f, $method, @values) = @_;
  my $t;
  $t = EV::timer($delay, 0, sub { undef $t; $f->$method(@values) });
  return;
}

# Run $code; bail out if it has not returned after 10 seconds.
sub bounded {
  my ($label, $code) = @_;
  my $dog = EV::timer(10, 0, sub { BAIL_OUT("$label: still blocked after 10s") });
  $dog->keepalive(0);
  return $code->();
}

# --- 1. the Future -------------------------------------------------------------

{
  my $plain = Future->new;
  settle_later(0.01, $plain, done => 'never read');
  ok !eval { $plain->get; 1 }, 'a plain Future cannot get while it is pending';
  like $@, qr/does not provide ->await/, '(the reason this class exists)';
  bounded('drain', sub { EV::run(EV::RUN_ONCE()) until $plain->is_ready });

  my $f = $EVF->new;
  settle_later(0.01, $f, done => 'from the loop');
  is bounded('get', sub { $f->get }), 'from the loop', 'get waits for the EV loop to settle the Future';

  my $failing = $EVF->new;
  settle_later(0.01, $failing, fail => "failed in the loop\n");
  ok !eval { bounded('get failure', sub { $failing->get }); 1 }, 'get on a Future that fails dies';
  is $@, "failed in the loop\n", 'with its failure';

  my $orphan = $EVF->new;
  my $dog = EV::timer(5, 0, sub { $orphan->fail("watchdog\n") });
  $dog->keepalive(0);
  ok !eval { $orphan->get; 1 }, 'get on a Future nothing in the loop can settle dies';
  like $@, qr/nothing left that could complete it/, 'at once, saying so -- it does not spin';
}

{
  my ($depth, $got);
  my $t = EV::timer(0, 0, sub {
    $depth = EV::depth();
    my $inner = $EVF->new;
    settle_later(0.01, $inner, done => 'nested');
    $got = eval { $inner->get } // "died: $@";
    EV::break;
  });
  bounded('nested', sub { EV::run });
  is $depth, 1, 'called from inside an EV callback';
  is $got, 'nested', 'get runs the loop recursively and returns there';
}

{
  my $f1 = $EVF->new;
  my $f2 = $EVF->new;
  my $chain = $f1->then(sub { return $_[0] * 2 });
  isa_ok $chain, $EVF, 'then on a pending Future';
  my $all = Future->needs_all($chain, $f2);
  isa_ok $all, $EVF, 'needs_all over them';
  settle_later(0.01, $f1, done => 21);
  settle_later(0.02, $f2, done => 'b');
  is_deeply [ bounded('chain', sub { $all->get }) ], [ 42, 'b' ], 'and get on the chain waits for all of it';
}

# --- 2. the class reaches everything a blocking method waits on ---------------

# EVFakeMDB stands in for EV::MariaDB: the operations the executor and the pool
# use, each completing on an EV timer, so nothing is ready before the loop runs.
# It answers by statement: an error for any statement on table `broken`.
{
  package EVFakeMDB;
  use Socket ();

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, connected => 0, log => [], stmts => {}, next => 0 }, $class;
    # A live session: a real socket with nothing to read, which is what the
    # transport asks a handle about after a failed statement (karr k55).
    socketpair($self->{sock}[0], $self->{sock}[1], Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    _later(sub { $self->{connected} = 1; $self->{on_connect}->() });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub _answer {
    my ($self, $sql) = @_;
    push @{ $self->{log} }, $sql;
    return (undef, "Table 'test.broken' doesn't exist") if $sql =~ /`broken`/;
    return ([ [ 7 ] ])         if $sql =~ /LAST_INSERT_ID/;
    return ([ [ 1, 'one' ] ])  if $sql =~ /^SELECT/;
    return (1)                 if $sql =~ /^(?:INSERT|UPDATE|DELETE)/;
    return (0);
  }

  sub is_connected { $_[0]{connected} }
  sub close_async  { }
  sub finish       { }
  sub socket       { fileno $_[0]{sock}[0] }
  sub pending_count { 0 }

  sub query {
    my ($self, $sql, $cb) = @_;
    _later(sub { $cb->($self->_answer($sql)) });
    return;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    my $id = ++$self->{next};
    $self->{stmts}{$id} = $sql;
    _later(sub { $cb->($id) });
    return;
  }

  sub execute {
    my ($self, $id, $bind, $cb) = @_;
    my $sql = $self->{stmts}{$id};
    _later(sub { $cb->($self->_answer($sql)) });
    return;
  }

  sub close_stmt {
    my ($self, $id, $cb) = @_;
    delete $self->{stmts}{$id};
    _later(sub { $cb->(1) });
    return;
  }

  # The reset the pool sends at the end of every borrow (karr k100, core k398);
  # it is no statement of the log.
  sub reset_connection {
    my ($self, $cb) = @_;
    _later(sub { $cb->(1, undef) });
    return;
  }
}

# The real pool builds its handles through this seam (t/08).
{
  no warnings 'redefine';
  *DBIO::MySQL::EV::Pool::_new_connection = sub { shift; EVFakeMDB->new(@_) };
}

my $storage = DBIO::MySQL::EV::Storage->new(undef);
$storage->connect_info([ { host => 'fake', database => 'fake', pool_size => 2 }, {} ]);

is $storage->future_class, $EVF, 'the storage future_class';
is $storage->pool->future_class, $EVF, 'is the pool future_class (acquire and readiness Futures)';
isa_ok $storage->_executor->execute(EVFakeMDB->new(on_connect => sub {}), 'SELECT 1', []), $EVF,
  'a query Future of the executor';
isa_ok +DBIO::MySQL::EV::QueryExecutor->new->execute(EVFakeMDB->new(on_connect => sub {}), 'SELECT 1', []),
  $EVF, 'a query Future of an executor built without one';

# --- 3. the blocking methods, end to end ----------------------------------------

# Call a blocking method: (1, @result) when it returned, (0, $error) when it died.
sub sync_call {
  my ($label, $code) = @_;
  my @r;
  return (1, @r) if eval { @r = bounded($label, $code); 1 };
  return (0, $@);
}

my ($ok, @r) = sync_call('select', sub { $storage->select_single_async('artist', [qw( id name )], { id => 1 }, {})->get });
is_deeply [ $ok, @r ], [ 1, [ 1, 'one' ] ], 'get on select_single_async returns the row';

($ok, @r) = sync_call('update', sub { $storage->update('artist', { name => 'x' }, { id => 1 }) });
is_deeply [ $ok, @r ], [ 1, 1 ], 'update returns the affected-row count';

($ok, @r) = sync_call('delete', sub { $storage->delete('artist', { id => 1 }) });
is_deeply [ $ok, @r ], [ 1, 1 ], 'delete returns the affected-row count';

($ok, @r) = sync_call('insert', sub { $storage->insert('artist', { name => 'x' }) });
is_deeply [ $ok, @r ], [ 1, { name => 'x' } ], 'insert returns the returned-columns hashref';
is $storage->last_insert_id, 7, 'after reading LAST_INSERT_ID() on the same connection';

($ok, @r) = sync_call('txn_do', sub {
  $storage->txn_do(sub { $_[0]->update_async('artist', { name => 'y' }, { id => 2 }) });
});
is_deeply [ $ok, @r ], [ 1, 1 ], 'txn_do returns what its coderef resolved with';
my ($txn_conn) = grep { grep { $_ eq 'BEGIN' } @{ $_->{log} } } @{ $storage->pool->{_connections} };
my @txn = grep { /^(?:BEGIN|COMMIT|ROLLBACK|UPDATE)/ } @{ $txn_conn ? $txn_conn->{log} : [] };
is_deeply [ @txn[-3 .. -1] ], [ 'BEGIN', 'UPDATE `artist` SET `name` = ? WHERE `id` = ?', 'COMMIT' ],
  'and ran its statement between BEGIN and COMMIT';

($ok, @r) = sync_call('update (fails)', sub { $storage->update('broken', { name => 'x' }, { id => 1 }) });
ok !$ok, 'a failed statement makes the blocking method die';
like $r[0], qr/Table 'test\.broken' doesn't exist/, 'with the statement error';

{
  my ($depth, @got);
  my $t = EV::timer(0, 0, sub {
    $depth = EV::depth();
    @got = eval { $storage->update('artist', { name => 'z' }, { id => 3 }) };
    @got = ("died: $@") if $@;
    EV::break;
  });
  bounded('update in a callback', sub { EV::run });
  is $depth, 1, 'called from inside an EV timer callback';
  is_deeply \@got, [ 1 ], 'a blocking method returns there too';
}

done_testing;
