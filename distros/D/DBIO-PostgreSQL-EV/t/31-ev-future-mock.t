use strict;
use warnings;
use Test::More;
use Scalar::Util ();

# OFFLINE regression for karr k44: the transport's Futures must be able to wait
# on the EV loop, so that the blocking storage methods work -- and must refuse
# a wait that EV::Pg would turn into a spin.
#
# WHY: core DBIO::Storage::Async implements select, select_single, insert,
# update, delete, txn_do and deploy as `return $self->X_async(@_)->get` (ADR
# 0001). Every Future this transport returns is settled from the EV loop -- by
# an EV::Pg callback -- so it is still pending when ->get is called. A plain
# Future's get then calls await, which Future leaves to subclasses and by
# default dies: "... is not yet complete and does not provide ->await". Until
# k44 this transport's Futures were plain Futures, and every one of those
# methods died (measured live, t/30-sync-fallback-live.t covers it there).
#
# EV::Pg keeps the callback it is delivering to at the head of its queue until
# that callback returns; a nested loop that reads the next result on the same
# connection hands it to that callback again and then spins in C. So a
# blocking wait inside such a callback, while more is pending on that
# connection, must die instead ("Blocking wait refused").
#
# What this file claims:
#   1. DBIO::PostgreSQL::EV::Future's get waits for a Future the EV loop
#      settles -- result and failure alike, also when called from inside an EV
#      callback -- and dies at once, instead of spinning, when nothing left in
#      the loop could settle it. then / needs_all keep the class.
#   2. It refuses to wait while a connection is delivering (_delivering) with
#      more than one statement pending -- on entry and when that happens while
#      it waits -- and not otherwise; the frame ends with the callback, also
#      when it dies, and nests. A refused Future's chain still completes.
#   3. Through the REAL storage and pool, with a fake EV::Pg whose operations
#      complete on EV timers and which, like the real one, counts the
#      delivering callback as pending until it returns: the storage hands the
#      class to the pool, the blocking methods return what their *_async
#      siblings resolve with and rethrow a failure, and every callback the
#      storage hands to EV::Pg marks its connection as delivering.
#
# Without the repair, 1 cannot even load, and 3 fails: the calls die with the
# croak above.
#
# Every wait is bounded by an EV timer with keepalive(0), so the watchdog is
# never itself the reason the loop has work left.

use EV;
use Future;

# The fake EV::Pg, installed before the storage's pool can require the real
# one. Connected from the start; query_params / query / pipeline_sync queue the
# callback and complete the head of the queue from an EV timer, one at a time,
# counting it as pending until its callback has returned -- EV::Pg's order.
# Results by SQL: 'fail_me' fails, INSERT ... RETURNING yields one row, other
# SELECTs a fixed row, everything else a command tag.
BEGIN {
  package EV::Pg;
  our $COLD;   # true: connect completes on an EV timer, not at once
  sub new {
    my ($class, %args) = @_;
    my $self = bless { %args, queue => [], extra => 0, sql => [], up => !$COLD }, $class;
    if ($COLD) {
      Scalar::Util::weaken(my $weak = $self);
      $self->{connecting} = EV::timer(0.01, 0, sub {
        return unless $weak;
        $weak->{up} = 1;
        $weak->{on_connect}->() if $weak->{on_connect};
      });
    }
    return $self;
  }
  sub is_connected { $_[0]{up} }
  sub finish { }
  sub socket { -1 }   # no socket for the pool to look at (karr k72)
  sub pending_count { scalar(@{ $_[0]{queue} }) + $_[0]{extra} }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{sql} }, $sql;
    push @{ $self->{queue} }, [ $sql, [ @$bind ], $cb ];
    $self->_arm;
  }
  sub query { my ($self, $sql, $cb) = @_; $self->query_params($sql, [], $cb) }
  sub pipeline_sync { my ($self, $cb) = @_; push @{ $self->{queue} }, [ 'SYNC', [], $cb ]; $self->_arm }
  sub _arm {
    my $self = shift;
    return if $self->{timer};
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
  }
  sub _complete_head {
    my $self = shift;
    delete $self->{timer};
    my ($sql, $bind, $cb) = @{ $self->{queue}[0] || return };
    my @result =
        $sql =~ /fail_me/          ? (undef, "ERROR:  fail_me requested\n")
      : $sql eq 'SYNC'             ? (1)
      : $sql =~ /^INSERT.*RETURNING/i ? ([ [ 7, $bind->[-1] ] ])
      : $sql =~ /^SELECT/i         ? ([ [ 1, 'one' ] ])
      : $sql =~ /^(?:UPDATE|DELETE)/i ? ('1')
      :                              ('');
    $cb->(@result);
    shift @{ $self->{queue} };   # advanced only after the callback returned
    $self->_arm if @{ $self->{queue} };
  }
  $INC{'EV/Pg.pm'} = __FILE__;
}

use DBIO::PostgreSQL::EV::Future;
use DBIO::PostgreSQL::EV::Storage;

use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;

my $EVF = 'DBIO::PostgreSQL::EV::Future';

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
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(10, 0, sub { BAIL_OUT("$label: still blocked after 10s") });
  $dog->keepalive(0);
  return $code->();
}

# Drive the loop from outside until $f is ready.
sub drive {
  my ($f) = @_;
  bounded('drive', sub { EV::run(EV::RUN_ONCE()) until $f->is_ready });
  return $f;
}

# --- 1. the Future -------------------------------------------------------------

{
  my $plain = Future->new;
  settle_later(0.01, $plain, done => 'never read');
  ok !eval { $plain->get; 1 }, 'a plain Future cannot get while it is pending';
  like $@, qr/does not provide ->await/, '(the reason this class exists)';
  drive($plain);

  my $f = $EVF->new;
  settle_later(0.01, $f, done => 'from the loop');
  is bounded('get', sub { $f->get }), 'from the loop', 'get waits for the EV loop to settle the Future';

  my $failing = $EVF->new;
  settle_later(0.01, $failing, fail => "failed in the loop\n");
  ok !eval { bounded('get failure', sub { $failing->get }); 1 }, 'get on a Future that fails dies';
  is $@, "failed in the loop\n", 'with its failure';

  my $orphan = $EVF->new;
  ok !eval { bounded('orphan', sub { $orphan->get }); 1 },
    'get on a Future nothing in the loop could settle dies';
  like $@, qr/nothing left that could complete it/, 'instead of spinning';

  my ($depth, $got);
  my $inner = $EVF->new;
  settle_later(0.02, $inner, done => 'nested');
  my $t = EV::timer(0, 0, sub { $depth = EV::depth(); $got = $inner->get; EV::break });
  bounded('nested', sub { EV::run });
  is $depth, 1, 'get called from inside an EV callback ...';
  is $got, 'nested', '... waits there too (libev runs the loop recursively)';

  my $p   = $EVF->new;
  my $q   = $EVF->new;
  my $seq = $p->then(sub { 1 });
  my $all = $EVF->needs_all($p, $q);
  isa_ok $seq, $EVF, 'then on a pending instance';
  isa_ok $all, $EVF, 'needs_all over instances';
  $p->done;
  $q->done;
}

# --- 2. the refusal ------------------------------------------------------------

{
  package FakeConn;
  sub new { bless { pending => $_[1] }, $_[0] }
  sub pending_count { $_[0]{pending} }
}
my $REFUSED = qr/^Blocking wait refused/;

{
  my $conn = FakeConn->new(2);
  my $f = $EVF->new;
  settle_later(0.01, $f, done => 'late');
  {
    my $delivering = $EVF->_delivering($conn);
    ok !eval { bounded('refused', sub { $f->get }); 1 },
      'get inside a delivering callback with more pending on its connection dies';
    like $@, $REFUSED, 'refused';
    like $@, qr/1 more result\(s\) due/, 'naming what is due';
    like $@, qr/\*_async/, 'pointing to the *_async methods';
  }
  is bounded('after the frame', sub { $f->get }), 'late',
    'once the callback has returned, the same Future can be waited on';

  my $one = FakeConn->new(1);
  my $g = $EVF->new;
  settle_later(0.01, $g, done => 'waited');
  {
    my $delivering = $EVF->_delivering($one);
    is bounded('pending one', sub { $g->get }), 'waited',
      'with only the delivering statement pending, get waits';
  }

  my $dying = FakeConn->new(2);
  eval { my $delivering = $EVF->_delivering($dying); die "callback died\n" };
  my $h = $EVF->new;
  settle_later(0.01, $h, done => 'after a die');
  is bounded('after a die', sub { $h->get }), 'after a die',
    'a callback that dies ends its frame';

  my $nest = FakeConn->new(2);
  my $n = $EVF->new;
  settle_later(0.01, $n, done => 'nested frames');
  {
    my $outer = $EVF->_delivering($nest);
    { my $inner = $EVF->_delivering($nest) }
    ok !eval { bounded('outer frame', sub { $n->get }); 1 },
      'a nested frame of the same connection restores the outer one';
    like $@, $REFUSED, '(still refused)';
  }
  drive($n);

  my $later = FakeConn->new(1);
  my $w = $EVF->new;
  EV::now_update();   # the bump must come well before the settle
  settle_later(0.5, $w, done => 'too late');
  {
    my $delivering = $EVF->_delivering($later);
    my $bump = EV::timer(0.01, 0, sub { $later->{pending} = 2 });
    ok !eval { bounded('issued while waiting', sub { $w->get }); 1 },
      'a statement issued on the connection while get waits ...';
    like $@, $REFUSED, '... makes it refuse before the next iteration';
  }
  drive($w);

  # The refused Future's chain still runs: Future holds a sequence Future
  # only weakly, and the caller that died dropped it.
  my $src = $EVF->new;
  my ($ran, @lost);
  local $SIG{__WARN__} = sub { push @lost, $_[0] if $_[0] =~ /lost a sequence Future/ };
  {
    my $chain = $src->then(sub { $ran = 1; $EVF->done });
    my $delivering = $EVF->_delivering(FakeConn->new(2));
    eval { $chain->get };
  }
  $src->done;
  ok $ran, 'the chain the refused caller dropped still runs';
  is scalar @lost, 0, 'without losing its sequence Future';
}

# --- 3. through the real storage and pool ---------------------------------------

{
  package FakeOwner;
  sub new { bless {}, shift }
  # The owning sync storage vouches for the transaction context it is asked
  # about (core ADR 0045); ownership is not what this file tests.
  sub _assert_async_context_owner { 1 }
  # The transport takes its quoting from the owner's SQL maker (karr k88):
  # a sync PostgreSQL storage's, with nothing said, quotes with " and . .
  sub sql_maker { DBIO::PostgreSQL::SQLMaker->new(quote_char => '"', name_sep => '.') }
  sub _select_args {
    my ($self, $ident, $select, $where, $attrs) = @_;
    return ('select', $ident, $select, $where, $attrs || {});
  }
}
{
  package FakeSource;
  sub new     { bless {}, shift }
  sub name    { 'thing' }
  sub columns { qw( id name ) }
}

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
$storage->connect_info([ { dbname => 'fake', pool_size => 2 } ]);
my $owner = FakeOwner->new;
$storage->_owner_storage($owner);
my $source = FakeSource->new;

is $storage->future_class, $EVF, 'the storage future_class is the EV Future';
is $storage->pool->future_class, $EVF, 'and the pool gets it';
isa_ok $storage->select_async('thing', [qw( id name )], {}), $EVF, 'select_async';

# Each blocking method returns what its *_async sibling resolves with.
my @cases = (
  [ select        => [ 'thing', [qw( id name )], {} ] ],
  [ select_single => [ 'thing', [qw( id name )], { id => 1 } ] ],
  [ insert        => [ $source, { name => 'x' } ] ],
  [ update        => [ $source, { name => 'y' }, { id => 1 } ] ],
  [ delete        => [ $source, { id => 1 } ] ],
);
for my $case (@cases) {
  my ($m, $args) = @$case;
  my $async_m = "${m}_async";
  my @expect  = drive($storage->$async_m(@$args))->get;
  my @got;
  ok eval { @got = bounded($m, sub { $storage->$m(@$args) }); 1 }, "$m returns" or diag $@;
  is_deeply \@got, \@expect, "$m returns what $async_m resolves with";
}

{
  my $conn;
  my @got;
  ok eval {
    @got = bounded('txn_do', sub {
      $storage->txn_do(sub { my ($ctx) = @_; $conn = $ctx->txn_conn; $ctx->insert_async($source, { name => 'in txn' }) });
    });
    1;
  }, 'txn_do returns' or diag $@;
  is_deeply \@got, [ { id => 7, name => 'in txn' } ], 'with what its coderef resolved with';
  my @control = grep { /^(?:BEGIN|COMMIT|ROLLBACK)$/ } @{ $conn->{sql} };
  is_deeply [ @control[-2, -1] ], [ 'BEGIN', 'COMMIT' ], 'bracketed by BEGIN and COMMIT';
}

ok !eval { bounded('failing select', sub { $storage->select('fail_me', ['x'], {}) }); 1 },
  'a blocking method whose query fails dies';
like $@, qr/fail_me requested/, 'with the query error';

PoolReset->until_reset($storage);   # a connection is idle once its reset is answered (karr k99)
is $storage->pool->available, $storage->pool->size, 'every pooled connection is idle again';

# On a cold pool the first link of the chain -- the acquire, pending until the
# connection is up -- is the pool's Future, so the pool's class decides whether
# the blocking method can wait.
{
  local $EV::Pg::COLD = 1;
  my $cold = DBIO::PostgreSQL::EV::Storage->new(undef);
  $cold->connect_info([ { dbname => 'fake', pool_size => 1 } ]);
  $cold->_owner_storage($owner);
  my @got;
  ok eval { @got = bounded('cold select', sub { $cold->select('thing', [qw( id name )], {}) }); 1 },
    'a blocking method on a cold pool waits for the connection too' or diag $@;
  is_deeply \@got, [ [ 1, 'one' ] ], '(with the rows)';
}

# Every callback the storage hands to EV::Pg marks its connection as
# delivering: inside a then on its Future, one more pending statement makes a
# blocking wait refuse. The extra statement is put on every pooled connection;
# only the one whose callback is running is delivering, so a refusal proves the
# callback marked it.
my $probe = sub {
  my ($label, $f) = @_;
  my $err;
  my $after = $f->then(sub {
    my @conns = @{ $storage->pool->{_connections} };
    $_->{extra} = 1 for @conns;
    my $never = $EVF->new;
    my $t = EV::timer(5, 0, sub { $never->done });
    $t->keepalive(0);
    $err = eval { $never->get; 1 } ? 'waited' : $@;
    $_->{extra} = 0 for @conns;
    return $EVF->done;
  });
  drive($after);
  like $err, $REFUSED, "$label marks its connection as delivering";
};
my $pg = drive($storage->pool->acquire)->get;
$probe->('_query_async_pinned', $storage->_query_async_pinned($pg, 'SELECT 1', []));
$probe->('_pipeline_sync', $storage->_pipeline_sync($pg));
# called as _query_async calls it: with the pool $pg was acquired from (karr k88)
$probe->('_dispatch_query', $storage->_dispatch_query($pg, 'SELECT 1', [], $storage->pool));
$probe->('_dispatch_notify', $storage->notify('chan', 'payload'));
PoolReset->until_reset($storage);
is $storage->pool->available, $storage->pool->size, 'and the pool is idle again';

done_testing;
