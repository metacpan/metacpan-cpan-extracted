use strict;
use warnings;
use Test::More;

# LIVE test for the sync fallbacks over the ev transport (karr k44, ADR 0001).
#
# The async storage answers the SYNC storage methods too -- select,
# select_single, insert, update, delete, txn_do, deploy -- inherited from core
# DBIO::Storage::Async as `return $self->X_async(@_)->get`. ADR 0001 is the
# decision behind that: the async method is the one implementation, the sync
# method runs it to completion. Nothing drove that path against a server until
# this file, and it did not work: the transport's Futures were plain Futures,
# whose get on a pending one dies ("... is not yet complete and does not
# provide ->await"), and every one of them is pending when get is called,
# because EV::Pg settles it from the EV loop. Every call below died, and each
# died call left its chain dropped -- its pooled connection never came back.
#
# The claim, stated plainly: each sync method, called from a script that is not
# running the EV loop, RETURNS what its *_async sibling resolves with -- the same
# rows, the same returned-columns hashref, the same affected-row count -- and a
# failure of the operation reaches the caller as a DIE with the operation's
# error. Afterwards every pooled connection is idle again.
#
# The sibling's result is read with the harness's await, which drives the loop
# from outside; the sync call gets no help at all. Whatever makes it block is
# what this file tests -- DBIO::PostgreSQL::EV::Future's await.
#
# The same claim holds for a sync call made from inside a callback of a running
# EV loop -- a timer's, here: libev runs the loop recursively -- and inside a
# then on a pooled Future, as long as the pool can hand the call another
# connection.
#
# Inside a callback of one of this transport's OWN connections while more
# results are due on it, the claim is a different one. EV::Pg would hand the
# next result on that connection to the callback that is still running and then
# spin in C (measured, karr k44), so the wait is REFUSED instead: it dies at
# once with "Blocking wait refused". The case here is a pipeline, and it is
# chosen so that the server answers the batch in one flush -- a nested wait
# would have come through. The refusal does not depend on that timing: it fires
# on what is due, so this assertion fails the moment the refusal stops firing,
# without ever reaching the spin. And the refusal leaves nothing behind: the
# batch completes, and the pool is idle afterwards.
#
# Every sync call is bounded by an EV timer (keepalive(0), so the watchdog is
# never itself the reason the loop has work left).

use EV;
use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use PoolReset;
use LiveServer;
LiveServer->require_server;

{
  package DBIO::PostgreSQL::EV::SyncFallbackLive::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k44_sync_fallback');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint([qw( name )]);

  package DBIO::PostgreSQL::EV::SyncFallbackLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Thing => 'DBIO::PostgreSQL::EV::SyncFallbackLive::Thing');
}

my $table = 'k44_sync_fallback';
my $LIMIT = 20;

my ($h, $hung);

# Leave the database as we found it, also when a call died mid-file. Not after
# a watchdog fired: the loop is wedged then, and a cleanup driving it would
# hang the END block too.
END {
  return if !$h || $hung;
  eval { $h->await($h->async->_query_async("DROP TABLE IF EXISTS $table", [])) };
  eval { $h->disconnect };
}

# Run $code; if it has not returned after $LIMIT seconds, bail out.
sub bounded {
  my ($label, $code) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer($LIMIT, 0, sub {
    $hung = 1;
    BAIL_OUT("$label: still blocked after ${LIMIT}s");
  });
  $dog->keepalive(0);
  return $code->();
}

# Call a sync method: (1, @result) when it returned, (0, $error) when it died.
sub sync_call {
  my ($label, $code) = @_;
  my @r;
  return (1, @r) if eval { @r = bounded($label, $code); 1 };
  return (0, $@);
}

$h = DBIO::PostgreSQL::EV::TestHarness->new(
  schema_class  => 'DBIO::PostgreSQL::EV::SyncFallbackLive::Schema',
  connect_attrs => { pool_size => 3 },
);

my $async  = $h->async;
my $schema = $h->schema;
my $source = $schema->source('Thing');
isa_ok $async, 'DBIO::PostgreSQL::EV::Storage', 'the ev transport';

# The table comes from the async sibling of deploy; the sync deploy itself is
# tested at the end, on a dropped table.
$h->await($async->_query_async("DROP TABLE IF EXISTS $table", []));
$h->await($async->deploy_async($schema));

my @cols  = qw( id name );
my %by_id = ( order_by => 'id' );

my $idle_ok = sub {
  my ($what) = @_;
  PoolReset->until_reset($async);   # idle once the reset of the last borrow is answered (karr k99)
  is $async->pool->available, $async->pool->size,
    "every pooled connection is idle again ($what)";
};

# --- insert ------------------------------------------------------------------
my ($ok, @r) = sync_call('insert', sub { $async->insert($source, { name => 'alpha' }) });
ok $ok, 'insert returned' or diag "insert died: $r[0]";
my $sync_ins = $ok ? $r[0] : undef;
my ($async_ins) = $h->await($async->insert_async($source, { name => 'beta' }));

is ref $sync_ins, 'HASH', 'insert returns the returned-columns hashref, as insert_async resolves';
is_deeply [ sort keys %{ $sync_ins || {} } ], [ sort keys %$async_ins ],
  'insert returns the same columns insert_async resolves with';
is $sync_ins && $sync_ins->{name}, 'alpha', 'with the supplied data';
like $sync_ins && $sync_ins->{id}, qr/^\d+$/, 'and the id the server gave the row (RETURNING)';
my $alpha = $sync_ins ? $sync_ins->{id} : 0;
my $beta  = $async_ins->{id};

# --- select / select_single --------------------------------------------------
($ok, @r) = sync_call('select', sub { $async->select($table, \@cols, {}, {%by_id}) });
ok $ok, 'select returned' or diag "select died: $r[0]";
my @sync_rows  = $ok ? @r : ();
my @async_rows = $h->await($async->select_async($table, \@cols, {}, {%by_id}));
is scalar @async_rows, 2, 'the async sibling sees both rows';
is_deeply \@sync_rows, \@async_rows, 'select returns the rows select_async resolves with';

($ok, @r) = sync_call('select_single', sub {
  $async->select_single($table, \@cols, { name => 'beta' }, {});
});
ok $ok, 'select_single returned' or diag "select_single died: $r[0]";
my ($async_single) = $h->await($async->select_single_async($table, \@cols, { name => 'beta' }, {}));
is_deeply $async_single, [ $beta, 'beta' ], 'the async sibling finds the row';
is_deeply $ok ? $r[0] : undef, $async_single,
  'select_single returns the row select_single_async resolves with';

# --- update / delete: the affected-row count ---------------------------------
($ok, @r) = sync_call('update', sub { $async->update($source, { name => 'alpha2' }, { id => $alpha }) });
ok $ok, 'update returned' or diag "update died: $r[0]";
my ($async_upd) = $h->await($async->update_async($source, { name => 'beta2' }, { id => $beta }));
is $async_upd, 1, 'update_async resolves with one affected row';
is $ok ? $r[0] : undef, $async_upd, 'update returns the count update_async resolves with';

($ok, @r) = sync_call('update (no match)', sub { $async->update($source, { name => 'x' }, { id => -1 }) });
my ($async_none) = $h->await($async->update_async($source, { name => 'x' }, { id => -1 }));
is $ok ? $r[0] : 'died', $async_none, 'a no-match update returns what update_async resolves with';

is_deeply [ $h->await($async->select_async($table, \@cols, {}, {%by_id})) ],
  [ [ $alpha, 'alpha2' ], [ $beta, 'beta2' ] ], 'the updates reached the table';

($ok, @r) = sync_call('delete', sub { $async->delete($source, { id => $alpha }) });
ok $ok, 'delete returned' or diag "delete died: $r[0]";
my ($async_del) = $h->await($async->delete_async($source, { id => $beta }));
is $async_del, 1, 'delete_async resolves with one affected row';
is $ok ? $r[0] : undef, $async_del, 'delete returns the count delete_async resolves with';
is_deeply [ $h->await($async->select_async($table, \@cols, {}, {})) ], [],
  'the deletes reached the table';

# --- txn_do ------------------------------------------------------------------
($ok, @r) = sync_call('txn_do', sub {
  $async->txn_do(sub {
    my ($ctx) = @_;
    return $ctx->insert_async($source, { name => 'in txn' });
  });
});
ok $ok, 'txn_do returned' or diag "txn_do died: $r[0]";
my ($async_txn) = $h->await($async->txn_do_async(sub {
  my ($ctx) = @_;
  return $ctx->insert_async($source, { name => 'in async txn' });
}));
is_deeply [ sort keys %{ $ok ? $r[0] : {} } ], [ sort keys %$async_txn ],
  'txn_do returns what its coderef resolved with, as txn_do_async does';
is_deeply [ map { $_->[1] } $h->await($async->select_async($table, \@cols, {}, {%by_id})) ],
  [ 'in txn', 'in async txn' ], 'both transactions committed';

# --- a failure is a die ------------------------------------------------------
my ($taken) = $h->await($async->insert_async($source, { name => 'taken' }));
($ok, @r) = sync_call('insert (duplicate key)', sub {
  $async->insert($source, { name => $taken->{name} });
});
ok !$ok, 'insert of a taken unique name dies';
like $ok ? '' : $r[0], qr/duplicate key value/, 'with the server error';
{
  my $f = $async->insert_async($source, { name => $taken->{name} });
  eval { $h->await($f) };
  like scalar $f->failure, qr/duplicate key value/, '(the async sibling fails with it)';
}

($ok, @r) = sync_call('select (unknown column)', sub {
  $async->select($table, [ 'no_such_column' ], {}, {});
});
ok !$ok, 'select of an unknown column dies';
like $ok ? '' : $r[0], qr/no_such_column.*does not exist/, 'with the server error';

($ok, @r) = sync_call('txn_do (coderef fails)', sub {
  $async->txn_do(sub {
    my ($ctx) = @_;
    return $ctx->insert_async($source, { name => 'rolled back' })
      ->then(sub { die "k44 abort\n" });
  });
});
ok !$ok, 'txn_do dies when its coderef fails';
is $ok ? '' : $r[0], "k44 abort\n", 'with the coderef error';
is_deeply [ $h->await($async->select_async($table, \@cols, { name => 'rolled back' }, {})) ], [],
  'and the transaction was rolled back';

$idle_ok->('after the blocking calls, died ones included');

# --- from inside a running loop ----------------------------------------------
# Run $code from a timer callback and leave the loop when it returns. The
# depth it saw proves it ran inside the loop (1), not outside (0).
sub in_loop {
  my ($label, $code) = @_;
  my ($ok, $depth, @r);
  my $t = EV::timer(0, 0, sub {
    $depth = EV::depth();
    $ok = eval { @r = $code->(); 1 };
    @r = ($@) unless $ok;
    EV::break;
  });
  bounded($label, sub { EV::run });
  return ($ok, $depth, @r);
}

{
  my @expect = $h->await($async->select_async($table, \@cols, {}, {%by_id}));
  my ($ok, $depth, @rows) = in_loop('select in a callback', sub {
    $async->select($table, \@cols, {}, {%by_id});
  });
  is $depth, 1, 'the next calls run inside a running loop';
  ok $ok, 'select returned inside a timer callback' or diag "died: $rows[0]";
  is_deeply \@rows, \@expect, 'with the rows select_async resolves with';

  ($ok, $depth, @r) = in_loop('txn_do in a callback', sub {
    $async->txn_do(sub { $_[0]->insert_async($source, { name => 'from a callback' }) });
  });
  ok $ok, 'txn_do returned inside a timer callback' or diag "died: $r[0]";
  is $ok && $r[0]{name}, 'from a callback', 'with what its coderef resolved with';
  my @committed = $h->await($async->select_async($table, \@cols, { name => 'from a callback' }, {}));
  is scalar @committed, 1, 'and the transaction committed';
}

# --- inside a then on a pooled Future ----------------------------------------
# The connection whose callback runs the then is still checked out; a pool of
# three hands the blocking call another one.
{
  my @expect = $h->await($async->select_async($table, \@cols, {}, {%by_id}));
  ($ok, @r) = sync_call('select in a then', sub {
    $async->select_async($table, \@cols, {}, {%by_id})->then(sub {
      return [ $async->select($table, \@cols, {}, {%by_id}) ];
    })->get;
  });
  ok $ok, 'a sync select inside a then on a pooled Future returns' or diag "died: $r[0]";
  is_deeply $ok ? $r[0] : undef, \@expect, 'with the rows select_async resolves with';
}

$idle_ok->('after the calls from inside callbacks');

# --- refused: more results due on the delivering connection ------------------
# In a pipeline, the then on the first in-batch Future runs inside that
# result's callback, with the second statement and the sync still due on the
# same connection.
{
  my $blocked;
  my $batch_f = $async->pipeline(sub {
    my ($batch) = @_;
    my $f1 = $batch->select_async($table, \@cols, {}, {%by_id});
    my $f2 = $batch->insert_async($source, { name => 'pipelined' });
    $blocked = $f1->then(sub { [ $async->select($table, \@cols, {}, {}) ] });
    return $batch->future_class->needs_all($f1, $f2);
  });
  my $batch_ok = eval { $h->await($batch_f); 1 };
  ok $batch_ok, 'the pipeline completes' or diag "pipeline died: $@";

  ok $blocked->is_failed, 'a blocking select in a then on an in-batch Future dies';
  like scalar $blocked->failure, qr/^Blocking wait refused/, 'refused, instead of waiting';
  like scalar $blocked->failure, qr/\*_async/, 'pointing to the *_async methods';

  is scalar(my @landed = $h->await($async->select_async($table, \@cols, { name => 'pipelined' }, {}))), 1,
    'the batch statement after the refused one still ran';

  # The refused select was already on its way to another connection: the
  # refusal cancels nothing, so it still completes there and gives that
  # connection back. Drive the loop until it has.
  bounded('the refused select completing', sub {
    EV::run(EV::RUN_ONCE()) until $async->pool->available == $async->pool->size;
  });
  $idle_ok->('after the refusal');

  ($ok, @r) = sync_call('select after the refusal', sub { $async->select($table, \@cols, { name => 'pipelined' }, {}) });
  ok $ok, 'the pool serves the next blocking call' or diag "died: $r[0]";
}

# --- deploy ------------------------------------------------------------------
$h->await($async->_query_async("DROP TABLE $table", []));
($ok, @r) = sync_call('deploy', sub { $async->deploy($schema) });
ok $ok, 'deploy returned' or diag "deploy died: $r[0]";
my @after = eval { [ $h->await($async->select_async($table, \@cols, {}, {})) ] };
is_deeply $after[0], [], 'deploy created the table' or diag "select: $@";

$idle_ok->('at the end');

done_testing;
