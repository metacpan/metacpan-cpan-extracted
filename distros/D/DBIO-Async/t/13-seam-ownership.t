use strict;
use warnings;
use Test::More;
use Scalar::Util 'refaddr';
use DBIO::Util ();

use DBIO::Storage::Async;
use DBIO::Storage::Async::TransactionContext;
use DBIO::Storage::PoolBase;
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE structural test: WHO OWNS WHICH METHOD (karr k15 point 2).
#
# WHY can_ok cannot answer this. t/01 asserts, correctly, that the whole
# composed API is reachable on an instance of this transport. That is a real
# claim -- it catches a misspelt method and a broken `use base` -- and it is
# left standing, untouched. But it says nothing about who SUPPLIES a method,
# and here that is the whole question: core DBIO::Storage::Async defines
# _query_async (and every other seam) as an abstract stub, so every transport
# INHERITS one and can() is true for all of them, owner and non-owner alike.
# Core ADR 0032, addendum 2026-07-27, names that probe as unfit for exactly
# this reason.
#
# The probe core itself uses, in DBIO::Storage::DBI::_async_storage, is code-ref
# IDENTITY: resolve the method on both classes and compare. Different code refs
# means this class OVERRIDES the seam -- it owns the query path a layer may
# wrap. Same code ref means it inherited the stub and owns nothing. That probe
# is reproduced verbatim in section 1, because it is not merely a good way to
# ask the question here: it is the literal gate an async extension layer is
# admitted through at compose time (core karr k118). If this transport ever
# stopped overriding _query_async, core would refuse every layer that declares
# no required_transport_capabilities -- so it is a promise this dist makes to
# other dists, and it belongs in this dist's suite.
#
# The second half is the mirror image and is just as load-bearing: the methods
# this transport must NOT own. Since core ADR 0030 section 4 the Model-B
# ORCHESTRATION -- the CRUD runner, txn_do_async, the pipeline scaffold, the
# ADR 0001 sync wrappers -- is concrete in core, and this dist is only the
# transport underneath it. Nothing enforces that but a test: a copy of
# _run_crud pasted down here to "fix" something would be invisible to every
# other file in this suite (they would all still pass, running the copy) and
# would silently fork the orchestration away from the drivers that share it.
# Section 2 is the tripwire for that.

# ---------------------------------------------------------------------------
# 1. Seams this transport OWNS -- it overrides core's, so the code refs differ.
# ---------------------------------------------------------------------------

# The gate, spelled exactly as core spells it (DBIO/Storage/DBI.pm,
# _async_storage): a transport offers the default async query seam iff it
# really overrides the abstract stub.
{
  my $abstract_seam = DBIO::Storage::Async->can('_query_async');
  my $backend_seam  = DBIO::Async::Storage->can('_query_async');
  my $has_seam      = $backend_seam
    && (!$abstract_seam || $backend_seam != $abstract_seam);

  ok $has_seam,
    'core\'s own seam-ownership probe says this transport OWNS _query_async '
    . '-- the gate an async layer with no declared requirements is admitted '
    . 'through (core ADR 0032 addendum / karr k118)';
}

my %OWNED = (
  # the query path
  _query_async         => 'the pooled query seam core probes for layer composition',
  _query_async_pinned  => 'the pinned query seam txn and pipeline run on',
  _await_query_result  => 'submit -> readable -> collect, this transport\'s own',
  _await_conn_ready    => 'poll-shaped readiness, not core\'s croaking stub',
  # the transport\'s identity
  future_class         => 'names Future.pm as the production implementation',
  pool                 => 'builds a DBIO::Async::Pool, not core\'s stub',
  transport_capabilities => 'declares on_connect_replay',
  _async_broker_conninfo => 'one fresh conninfo per spawned pool connection',
  _normalize_conninfo  => 'replaces core\'s identity default with a real seam',
  # karr k13: narrowed here so no adapter has to name them
  _txn_context_class   => 'narrowed to DBIO::Async::TransactionContext',
  _txn_conn_accessor   => 'stated next to the class it belongs to',
  # karr k22 / core ADR 0056: the Future::IO-generic listen seams, once here
  # for every future_io driver instead of once per driver
  _listen_delay        => 'the backoff timer over Future::IO->sleep',
  _listen_watch        => 'the one watch loop, socket- or timer-driven',
  _listen_unwatch      => 'stops that loop',
  _notify_send         => 'the pooled notify over _query_async + _notify_sql',
);

for my $method (sort keys %OWNED) {
  isnt refaddr(DBIO::Async::Storage->can($method)),
       refaddr(DBIO::Storage::Async->can($method)),
    "OWNED: $method is overridden here -- $OWNED{$method}";
}

# Introduced here and unknown to core at all: the Future::IO watcher seam and
# the DB-specific hooks a driver fills. ADR 0004's isolation principle is that
# these live in ONE layer and can be reworked there; core having no opinion
# about them is what makes that true.
#
# The listen watch loop's own steps (_watch_*) sit in the same list for a
# second reason: they share a class with core's private _listen_* machinery, so
# a same-named method appearing in core would be silently overridden by ours.
# "Core knows nothing about it" is the tripwire for that collision.
#
# _idle_connection_alive (karr k28) is a name core does know -- on its POOL,
# DBIO::Storage::PoolBase, whose seam DBIO::Async::Pool answers by asking this
# storage (section 3). What this list asks is only whether core's STORAGE has
# it; it has not, and a same-named method appearing there would be silently
# overridden by the driver seam here.
#
# The register of statements in flight (ADR 0007, karr k46 / k39) is in the
# list for the reason the watch loop's steps are: its methods -- _let_go, the
# one place the transport gives up on something it awaits, and
# _abandon_flights_on, which the pool calls before it closes a connection,
# among them -- share a class with core's storage, and core knowing nothing
# about them is what keeps a same-named method there from being overridden.
my @INTRODUCED = qw(
  _await_readable _conn_poll_fh _collect_on_readable _release_on_ready
  _mark_dead_on_fail _mark_if_fatal _conn_error_is_fatal _idle_connection_alive
  _abandon_on_cancel _report_abandoned
  _let_go _abandon_flights_on _flight_register _flight_abandon
  _flight_landed_cb _flight_cancel_cb _release_and_settle _start_unqueued
  _built_pool _pool_report
  _submit_query _collect_result _conn_ready _conn_fileno
  _create_pool_connection _shutdown_pool_connection
  _listen_drain _listen_poll_interval _notify_sql
  _watch_stop _watch_live _watch_await _watch_callback _watch_run _watch_lost
  _watch_elapsed _watch_polled _watch_drain _watch_drained _watch_deliver
  _watch_arm _watch_readable_now _watch_check
);

for my $method (@INTRODUCED) {
  ok( DBIO::Async::Storage->can($method),
    "INTRODUCED: $method exists on this transport" );
  ok( !DBIO::Storage::Async->can($method),
    "INTRODUCED: ... and core knows nothing about it -- the Future::IO seam is "
    . "isolated in this layer (ADR 0004)" );
}

# ---------------------------------------------------------------------------
# 2. Orchestration this transport must NOT own: concrete in core since ADR 0030
#    section 4, inherited here byte-identically. A different code ref means a
#    copy has appeared in this dist.
# ---------------------------------------------------------------------------

my @INHERITED = qw(
  select_async select_single_async insert_async update_async delete_async
  _run_crud _run_crud_pinned _pool_runner _pinned_runner
  _insert_returned_columns _returning_columns
  txn_do_async pipeline _pipeline_context_class
  select select_single insert update delete txn_do deploy
  deploy_async _install_ddl _execute_ddl_async _drop_statements_for
  connect_info _current_async_connect_info _normalize_async_connect_info
  _conninfo_provider _setup_pool_connection _teardown_pool_connection
  sql_maker _sql_maker_args
  listen unlisten notify listen_alive listen_reconnect
  on_listen_error on_listen_reconnect listen_backoff_initial listen_backoff_max
  _listen_dispatch _listen_lost
);

for my $method (@INHERITED) {
  is refaddr(DBIO::Async::Storage->can($method)),
     refaddr(DBIO::Storage::Async->can($method)),
    "INHERITED: $method is core's, not this dist's (ADR 0030 section 4)";
}

# The croaking seams a DRIVER fills are core's croaks, deliberately not
# re-declared here -- t/01 pins that they croak, this pins that the croak is
# the one core wrote, so a driver reads one message wherever it comes from.
#
# The DB-specific listen seams belong here too (core ADR 0056 section 5): opening,
# closing, subscribing and probing the listen connection are the driver's, and
# this transport has no generic answer for any of them.
my @INHERITED_SEAMS = qw(
  sql_maker_class _transform_sql _post_insert_sql
  _pipeline_enter _pipeline_sync _pipeline_exit
  _ddl_class
  _listen_open _listen_close _listen_subscribe _listen_unsubscribe _listen_probe
);

for my $method (@INHERITED_SEAMS) {
  is refaddr(DBIO::Async::Storage->can($method)),
     refaddr(DBIO::Storage::Async->can($method)),
    "INHERITED SEAM: $method croaks with core's message, not a copy here";
}

# ---------------------------------------------------------------------------
# 3. The pool: readiness gating is this dist's, the queue mechanics are core's.
#    karr k12 moved the gating ONTO core's _connection_ready_future seam so all
#    three acquire paths and acquire_txn are gated identically; that only holds
#    while acquire itself is still core's.
# ---------------------------------------------------------------------------

# _await_conn_ready is introduced by this pool; the others override a
# PoolBase method, so "not the same code ref" is the right question for them
# and "core has none" for it. `refaddr` on undef would warn, so ask which case
# it is first. _idle_connection_alive (karr k28) overrides core's borrow-time
# seam to ask the storage; what a throw from it does stays core's
# (_idle_connection_usable, below). _retire_connection (karr k49) is core's
# plus one step after it, the end of a readiness wait the poll of which
# _shutdown_connection let go of.
for my $method (qw( new _connection_ready_future _create_connection
                    _shutdown_connection _await_conn_ready
                    _idle_connection_alive _retire_connection )) {
  my $base = DBIO::Storage::PoolBase->can($method);
  if ($base) {
    isnt refaddr(DBIO::Async::Pool->can($method)), refaddr($base),
      "POOL OWNED: $method overrides core PoolBase's";
  }
  else {
    ok( DBIO::Async::Pool->can($method),
      "POOL OWNED: $method is introduced by this pool (core PoolBase has none)" );
  }
}

for my $method (qw( acquire acquire_txn release size available max_size
                    shutdown _spawn_connection
                    _acquire_slot _idle_connection_usable future_class )) {
  is refaddr(DBIO::Async::Pool->can($method)),
     refaddr(DBIO::Storage::PoolBase->can($method)),
    "POOL INHERITED: $method is core PoolBase's -- the idle list, the waiter "
    . "queue and the capacity rules are not reimplemented here";
}

# ---------------------------------------------------------------------------
# 4. The transaction context is a THIN subclass: it exists to have a name
#    (_txn_context_class resolves to it), and owns no behaviour whatsoever.
#    Its POD says "all behaviour is inherited unchanged"; this is that sentence
#    as a test.
# ---------------------------------------------------------------------------

for my $method (qw(
  new storage txn_conn pool in_txn _context_active _invalidate _query_async
  select_async select_single_async insert_async update_async delete_async
  select select_single insert update delete
  sql_maker debug pipeline txn_do_async
)) {
  is refaddr(DBIO::Async::TransactionContext->can($method)),
     refaddr(DBIO::Storage::Async::TransactionContext->can($method)),
    "CONTEXT INHERITED: $method comes straight from core's generic context";
}

{
  no strict 'refs';
  my @own = grep { defined &{"DBIO::Async::TransactionContext::$_"} }
            keys %{'DBIO::Async::TransactionContext::'};
  is_deeply [ sort @own ], [],
    'DBIO::Async::TransactionContext defines no sub of its own at all -- it is '
    . 'a name for core\'s context, nothing more';
}

# ---------------------------------------------------------------------------
# 5. One way in, one way out. This dist starts to wait for a socket in ONE
#    place, _await_readable, and gives up on something it awaits in ONE place,
#    _let_go (ADR 0004's isolation principle; ADR 0007, karr k39). The second
#    half is as load-bearing as the first: what a Future::IO implementation
#    does with a cancelled poll differs between them (karr k37, k38), and
#    whatever is ever done about that can be done once only if every cancel
#    this transport makes goes through one sub. Method identity cannot answer
#    this -- the question is how often a call is WRITTEN -- so it is asked of
#    the shipped source, POD and comments stripped.
# ---------------------------------------------------------------------------

{
  my %code;
  for my $file (grep { m{^DBIO/Async(?:/|\.pm$)} } sort keys %INC) {
    my $source = DBIO::Util::slurp_file($INC{$file});
    $source =~ s/^=[a-zA-Z].*?^=cut\b[^\n]*\n//msg;
    $source =~ s/^\s*#[^\n]*\n//mg;
    $code{$file} = $source;
  }
  ok exists $code{'DBIO/Async/Storage.pm'} && exists $code{'DBIO/Async/Pool.pm'},
    'the shipped source of the transport and its pool is read';

  my $all = join "\n", map { $code{$_} } sort keys %code;
  my ($await_readable) = $code{'DBIO/Async/Storage.pm'} =~ /^(sub _await_readable \{.*?^\})/ms;
  my ($let_go)         = $code{'DBIO/Async/Storage.pm'} =~ /^(sub _let_go \{.*?^\})/ms;

  is scalar(() = $all =~ /Future::IO->poll\b/g), 1,
    'this dist calls Future::IO->poll in exactly one place';
  like $await_readable // '', qr/Future::IO->poll\b/, '... which is _await_readable';
  is scalar(() = $all =~ /->cancel\b/g), 1,
    'this dist cancels a Future in exactly one place';
  like $let_go // '', qr/->cancel\b/, '... which is _let_go';

  # And one place asks for the pool by its lazy accessor: the pooled dispatch.
  # pool() builds a pool when there is none, which is right for what starts
  # work and wrong for what finishes it -- a statement that settles after its
  # storage was disconnected would hand that storage a new, empty pool (karr
  # k39). Every completion is handed the pool its statement was dispatched
  # with instead.
  my ($query_async) = $code{'DBIO/Async/Storage.pm'} =~ /^(sub _query_async \{.*?^\})/ms;
  is scalar(() = $code{'DBIO/Async/Storage.pm'} =~ /\$self->pool\b/g), 1,
    'the transport asks $self->pool in exactly one place';
  like $query_async // '', qr/\$self->pool\b/,
    '... which is _query_async, the pooled dispatch -- no completion builds a pool';
}

done_testing;
