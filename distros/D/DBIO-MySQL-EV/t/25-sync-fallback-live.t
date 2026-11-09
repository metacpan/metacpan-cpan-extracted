use strict;
use warnings;
use Test::More;

# LIVE test for the sync fallbacks over the ev transport (karr k48, ADR 0001).
#
# The async storage answers the SYNC storage methods too -- select,
# select_single, insert, update, delete, txn_do, deploy -- inherited from core
# DBIO::Storage::Async as `return $self->X_async(@_)->get`. ADR 0001 is the
# decision behind that: the async method is the one implementation, the sync
# method runs it to completion. This file is what the ADR never had: the sync
# path driven against a real server.
#
# The claim, stated plainly: each sync method, called from a script that is
# not running the EV loop, RETURNS what its *_async sibling resolves with --
# the same rows, the same returned-columns hashref, the same affected-row
# count -- and a failure of the operation reaches the caller as a DIE with the
# operation's error, never as a returned value.
#
# The sibling's result is read with the harness's await, which drives the loop
# from outside; the sync call gets no help at all. Whatever makes it block is
# what this file tests. Before karr k48 nothing did: the transport's Futures
# were plain Futures, whose get on a pending one dies ("... is not yet complete
# and does not provide ->await"), so every sync call below died.
#
# The same claim holds for a sync call made from inside a callback of a running
# EV loop -- a timer's, here: libev runs the loop recursively.
#
# Inside a callback of one of this transport's OWN connections -- a then on its
# Futures, a txn_do coderef -- the claim is the same: the sync call RETURNS.
# (Until karr k51 it was REFUSED with "Blocking wait refused", karr k48 option
# b: EV::MariaDB does not send a query issued on a connection while a callback
# of that connection runs, and a then ran inside one. The transport now settles
# its Futures from an idle watcher of the loop, so a then or a coderef runs
# outside every callback of the handle, and the claim of this file for that case
# is replaced.) What stays refused is the exhausted pool (karr k53): a sync call
# on the STORAGE in a txn_do coderef, with the only connection held by the
# transaction.
# t/27-blocking-in-callback-mock.t covers the same offline, with more cases.
#
# Every sync call is bounded by an EV timer: a call that blocks forever sits in
# libev's C code, where an alarm never fires (karr k46). keepalive(0), so the
# watchdog is never itself the reason the loop has work left.

use EV;
use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

{
  package DBIO::MySQL::EV::SyncFallbackLive::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k48_sync_fallback');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64 },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::MySQL::EV::SyncFallbackLive::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL', 'MySQL::EV');
  __PACKAGE__->register_class(Thing => 'DBIO::MySQL::EV::SyncFallbackLive::Thing');
}

my $table = 'k48_sync_fallback';
my $LIMIT = 20;

my ($h, $h1, $hung);

# Leave the database as we found it, also when a call died mid-file (karr
# k41). Not after a watchdog fired: the loop is wedged then, and a cleanup
# driving it would hang the END block too.
END {
  return if !$h || $hung;
  eval { $h->await($h->async->_query_async("DROP TABLE IF EXISTS $table", [])) };
  eval { $h->disconnect };
  eval { $h1->disconnect } if $h1;
}

# Run $code; if it has not returned after $LIMIT seconds, bail out.
sub bounded {
  my ($label, $code) = @_;
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

$h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'DBIO::MySQL::EV::SyncFallbackLive::Schema',
  connect_attrs => { pool_size => 3 },
);

my $async  = $h->async;
my $schema = $h->schema;
my $source = $schema->source('Thing');
isa_ok $async, 'DBIO::MySQL::EV::Storage', 'the ev transport';

# The table comes from the async sibling of deploy; the sync deploy itself is
# tested at the end, on a dropped table.
$h->await($async->_query_async("DROP TABLE IF EXISTS $table", []));
{
  local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /async DDL loop is not atomic/ };
  $h->await($async->deploy_async($schema));
}

# select / select_single take the ident the ResultSet passes; a table name
# will do, as in t/13. insert / update / delete take the source.
my @cols  = qw( id name );
my %by_id = ( order_by => 'id' );

# --- insert ------------------------------------------------------------------
my ($ok, @r) = sync_call('insert', sub { $async->insert($source, { name => 'alpha' }) });
ok $ok, 'insert returned' or diag "insert died: $r[0]";
my $sync_ins = $ok ? $r[0] : undef;
my ($async_ins) = $h->await($async->insert_async($source, { name => 'beta' }));

is ref $sync_ins, 'HASH', 'insert returns the returned-columns hashref, as insert_async resolves';
is_deeply [ sort keys %{ $sync_ins || {} } ], [ sort keys %$async_ins ],
  'insert returns the same columns insert_async resolves with';
is $sync_ins && $sync_ins->{name}, 'alpha', 'with the supplied data';
like $sync_ins && $sync_ins->{id}, qr/^\d+$/, 'and the auto-increment id the server gave the row';
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
  $async->insert($source, { id => $taken->{id}, name => 'duplicate' });
});
ok !$ok, 'insert on a taken primary key dies';
like $ok ? '' : $r[0], qr/Duplicate entry/, 'with the server error the insert_async Future fails with';
{
  my $f = $async->insert_async($source, { id => $taken->{id}, name => 'duplicate' });
  eval { $h->await($f) };
  like scalar $f->failure, qr/Duplicate entry/, '(the async sibling fails with it)';
}

($ok, @r) = sync_call('select (unknown column)', sub {
  $async->select($table, [ 'no_such_column' ], {}, {});
});
ok !$ok, 'select of an unknown column dies';
like $ok ? '' : $r[0], qr/Unknown column/, 'with the server error';

($ok, @r) = sync_call('txn_do (coderef dies)', sub {
  $async->txn_do(sub {
    my ($ctx) = @_;
    return $ctx->insert_async($source, { name => 'rolled back' })
      ->then(sub { die "k48 abort\n" });
  });
});
ok !$ok, 'txn_do dies when its coderef fails';
is $ok ? '' : $r[0], "k48 abort\n", 'with the coderef error';
is_deeply [ $h->await($async->select_async($table, \@cols, { name => 'rolled back' }, {})) ], [],
  'and the transaction was rolled back';

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

# --- inside a callback of the transport's own connection: returns -----------
# (karr k51 replaces the refusal of karr k48 here: the Futures are settled from
# an idle watcher of the loop, so what a then or a txn_do coderef runs is
# outside every callback of the handle.)
# A pool of ONE, so every statement below shares the connection whose callback
# the blocking call runs in, and a connection that leaked would hang the next
# call.
$h1 = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'DBIO::MySQL::EV::SyncFallbackLive::Schema',
  connect_attrs => { pool_size => 1 },
);
my $one     = $h1->async;
my $source1 = $h1->schema->source('Thing');

{
  my @expect = $h->await($async->select_async($table, \@cols, {}, {%by_id}));

  ($ok, @r) = sync_call('select in a then', sub {
    $one->select_async($table, \@cols, {}, {%by_id})->then(sub {
      return $one->future_class->done([ $one->select($table, \@cols, {}, {%by_id}) ]);
    })->get;
  });
  ok $ok, 'a sync select without bind values in a then on this transport (pool of one) returns'
    or diag "died: $r[0]";
  is_deeply $r[0], \@expect, '(with the rows select_async resolves with)';

  my $inserted;
  ($ok, @r) = sync_call('ctx select in a txn coderef', sub {
    $one->txn_do(sub {
      my ($ctx) = @_;
      $inserted = $ctx->insert($source1, { name => 'k51 in txn' });
      my @rows = $ctx->select($table, \@cols, {}, {%by_id});
      return $ctx->storage->future_class->done(scalar @rows);
    });
  });
  is ref $inserted, 'HASH', 'in a txn_do coderef, a sync $ctx->insert (bind values) returns';
  ok $ok, 'a sync $ctx->select without a WHERE there returns, txn_do commits' or diag "died: $r[0]";
  is $r[0], scalar(@expect) + 1, 'and the select saw the row inserted earlier in the same transaction';
  my @now = $h->await($async->select_async($table, \@cols, {}, {%by_id}));
  is $now[-1][1], 'k51 in txn', 'the transaction was committed: the row is in the table';
  $h->await($async->_query_async("DELETE FROM $table WHERE name = ?", ['k51 in txn']));

  ($ok, @r) = sync_call('select after the transaction', sub { $one->select($table, \@cols, {}, {%by_id}) });
  ok $ok, 'the pinned connection went back to the pool: the next select works' or diag "died: $r[0]";
  is_deeply \@r, \@expect, '(with the same rows)';
  # idle once the reset of the session has answered (karr k100, core k398)
  { my $dog = EV::timer(5, 0, sub {});
    EV::run(EV::RUN_ONCE()) until $one->pool->available == 1 || !$dog->is_active; }
  is $one->pool->available, 1, 'and the pool of one is idle';

  # The pool of one is still refused (karr k53): the transaction holds the
  # only connection until its coderef has returned.
  ($ok, @r) = sync_call('storage select in a txn coderef', sub {
    $one->txn_do(sub {
      return $one->future_class->done([ $one->select($table, \@cols, {}, {%by_id}) ]);
    });
  });
  ok !$ok, 'a sync select on the STORAGE in a txn coderef (pool of one) still dies';
  like $ok ? '' : $r[0], qr/\QBlocking wait refused\E/, 'refused: the transaction holds the only connection (karr k53)';
  ($ok, @r) = sync_call('select after the k53 refusal', sub { $one->select($table, \@cols, {}, {%by_id}) });
  ok $ok, 'and the pool recovered' or diag "died: $r[0]";
}

# --- deploy ------------------------------------------------------------------
$h->await($async->_query_async("DROP TABLE $table", []));
{
  local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /async DDL loop is not atomic/ };
  ($ok, @r) = sync_call('deploy', sub { $async->deploy($schema) });
}
ok $ok, 'deploy returned' or diag "deploy died: $r[0]";
my @after = eval { [ $h->await($async->select_async($table, \@cols, {}, {})) ] };
is_deeply $after[0], [], 'deploy created the table' or diag "select: $@";

done_testing;
