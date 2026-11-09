package DBIO::Storage;
# ABSTRACT: Generic Storage Handler

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Base/;
use mro 'c3';

{
  package # Hide from PAUSE
    DBIO::Storage::NESTED_ROLLBACK_EXCEPTION;
  use base 'DBIO::Exception';
}

use DBIO::Carp;
use DBIO::Storage::BlockRunner;
use Scalar::Util qw/blessed weaken/;
use DBIO::Storage::TxnScopeGuard;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  debug schema transaction_depth deferred_rollback auto_savepoint savepoints
  access_broker access_broker_mode
/);
__PACKAGE__->mk_group_accessors(component_class => 'cursor_class');

__PACKAGE__->cursor_class('DBIO::Cursor');

sub cursor { shift->cursor_class(@_); }


sub new {
  my ($self, $schema) = @_;

  $self = ref $self if ref $self;

  my $new = bless( {
    transaction_depth => 0,
    savepoints => [],
  }, $self);

  $new->set_schema($schema);
  $new->debug($self->_trace_level_of($ENV{DBIO_TRACE}))
    if $ENV{DBIO_TRACE};

  $new;
}

# The trace level a flag stands for: its leading digits (2=/path is level 2),
# level 1 for any other true value, 0 for a false one.
sub _trace_level_of {
  my ($class, $flag) = @_;
  return 0 unless $flag;
  return $flag =~ /^(\d+)/ ? $1 + 0 : 1;
}


sub set_schema {
  my ($self, $schema) = @_;
  $self->schema($schema);
  weaken $self->{schema} if ref $self->{schema};
}


sub set_access_broker {
  my ($self, $broker, $mode) = @_;

  $self->throw_exception('set_access_broker() requires a broker object')
    unless blessed($broker);

  $self->throw_exception(
    'set_access_broker() requires a DBIO::AccessBroker instance'
  ) unless $broker->isa('DBIO::AccessBroker');

  # A broker that is replaced lets go of this storage first, so it does not
  # go on answering for a storage that no longer uses it (karr k278).
  my $old = $self->access_broker;
  $old->unset_storage($self)
    if blessed($old) && $old->can('unset_storage');

  $self->access_broker($broker);
  $self->access_broker_mode($mode || 'write');
  $broker->set_storage($self);

  return $self;
}


sub clear_access_broker {
  my $self = shift;
  my $broker = $self->access_broker;
  $broker->unset_storage($self)
    if blessed($broker) && $broker->can('unset_storage');
  $self->access_broker(undef);
  $self->access_broker_mode(undef);
  return $self;
}


sub current_access_broker_connect_info {
  my ($self, $mode) = @_;
  my $broker = $self->access_broker or return;
  $mode ||= $self->access_broker_mode || 'write';

  my $answer  = $broker->current_connect_info_for_storage($self, $mode);
  my $nothing = !defined $answer         ? 'undef'
              : ref $answer eq 'HASH'    ? (%$answer ? undef : 'an empty hashref')
              : ref $answer eq 'ARRAY'   ? (@$answer ? undef : 'an empty arrayref')
              : !ref $answer && !$answer ? 'a false value'
              :                            undef;

  return $answer unless defined $nothing;

  # A view (HostBound) answers nothing only when the broker it wraps did.
  my ($answered, @views) = ($broker);
  while ($answered->can('underlying_broker')) {
    my $inner = $answered->underlying_broker or last;
    push @views, ref $answered;
    $answered = $inner;
  }

  $self->throw_exception(
    'AccessBroker ' . ref($answered) . " answered no connect info ($nothing)"
  . (@views ? ' through ' . join(' over ', @views) : '') . '. '
  . "A new connection is opened only with the broker's current answer, never "
  . 'with the connect info of an earlier one.'
  );
}

# One rule for a setting that a connection gets both from the hash beside its
# AccessBroker ([ $broker, \%options ]) and from the broker's answer (ADR 0030
# addendum, karr k243): both must name the same value -- the same plain value,
# both undef, or the very same reference -- or this throws, naming the
# setting (never its values, which may carry secrets). Returns the merged
# hashref; neither argument is modified. Shared by the sync storage and by an
# async transport merging the same settings into each connection it opens.
sub _merge_access_broker_settings {
  my ($self, $answer, $beside) = @_;

  my %merged = %{ $answer || {} };
  for my $key (sort keys %{ $beside || {} }) {
    my $value = $beside->{$key};

    $self->throw_exception(
      "Connection setting '$key' is given both beside the AccessBroker and in "
    . "the broker's answer, with different values. Give it in one place, or "
    . 'give both the same value.'
    ) if exists $merged{$key} && !_same_access_broker_setting($merged{$key}, $value);

    $merged{$key} = $value;
  }

  return \%merged;
}

sub _same_access_broker_setting {
  my ($x, $y) = @_;
  return !defined $y if !defined $x;
  return 0 if !defined $y;
  return 0 if !!ref $x != !!ref $y;
  return ref $x ? Scalar::Util::refaddr($x) == Scalar::Util::refaddr($y) : $x eq $y;
}


sub connected { die "Virtual method!" }


sub disconnect { die "Virtual method!" }


sub ensure_connected { die "Virtual method!" }


sub throw_exception {
  my $self = shift;

  if (ref $self and $self->schema) {
    $self->schema->throw_exception(@_);
  }
  else {
    DBIO::Exception->throw(@_);
  }
}


sub txn_do {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  DBIO::Storage::BlockRunner->new(
    storage => $self,
    wrap_txn => 1,
    retry_handler => sub {
      $_[0]->failed_attempt_count == 1
        and
      ! $_[0]->storage->connected
    },
  )->run(@_);
}


sub txn_begin {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;
  $self->_assert_transaction_safe_access_broker;

  if($self->transaction_depth == 0) {
    $self->debugobj->txn_begin()
      if $self->debug;
    $self->_exec_txn_begin;
  }
  elsif ($self->auto_savepoint) {
    $self->svp_begin;
  }
  $self->{transaction_depth}++;

}

sub _assert_transaction_safe_access_broker {
  my $self = shift;

  return if $self->{_access_broker_txn_safety_checked};
  return if $self->transaction_depth;

  my $broker = $self->access_broker or return;
  return if $broker->is_transaction_safe;

  my @reasons;
  push @reasons, 'credential rotation' if $broker->has_rotating_credentials;
  my $reason = @reasons
    ? join(' and ', @reasons)
    : 'broker-specific transaction safety constraints';

  if ($ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS}) {
    carp sprintf(
      'Starting a transaction with unsafe AccessBroker %s via override: %s',
      ref($broker) || $broker,
      $reason,
    );
    return;
  }

  $self->throw_exception(sprintf(
    'Refusing to start a transaction with unsafe AccessBroker %s: %s can break transactional consistency',
    ref($broker) || $broker,
    $reason,
  ));
}


sub txn_commit {
  my $self = shift;
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if ($self->transaction_depth == 1) {
    $self->debugobj->txn_commit() if $self->debug;

    unless (eval { $self->_exec_txn_commit; 1 }) {
      my $err = $@;
      $self->_abandon_after_failed_commit;
      die $err;
    }

    $self->{transaction_depth}--;
    $self->savepoints([]);
  }
  elsif($self->transaction_depth > 1) {
    $self->{transaction_depth}--;
    $self->svp_release if $self->auto_savepoint;
  }
  else {
    $self->throw_exception( 'Refusing to commit without a started transaction' );
  }
}


sub txn_rollback {
  my $self = shift;

  if ($self->transaction_depth == 1) {
    $self->debugobj->txn_rollback() if $self->debug;

    # a rollback that fails leaves nothing to rely on: the transaction may
    # still be open on the server. Do not keep claiming depth 1 on it.
    unless (eval { $self->_exec_txn_rollback; 1 }) {
      my $err = $@;
      $self->_abandon_after_failed_rollback;
      die $err;
    }

    $self->{transaction_depth}--;
    $self->savepoints([]);
    $self->deferred_rollback(undef);
  }
  elsif ($self->transaction_depth > 1) {
    $self->{transaction_depth}--;

    if ($self->auto_savepoint) {
      $self->svp_rollback;
      $self->svp_release;
    }
    else {
      $self->deferred_rollback(1);
      DBIO::Storage::NESTED_ROLLBACK_EXCEPTION->throw(
        "A txn_rollback in nested transaction is ineffective! (depth $self->{transaction_depth})"
      );
    }
  }
  else {
    $self->throw_exception( 'Refusing to roll back without a started transaction' );
  }
}


sub _abandon_after_failed_rollback {
  my $self = shift;
  $self->{transaction_depth} = 0;
  $self->savepoints([]);
  $self->deferred_rollback(undef);
}


sub _abandon_after_failed_commit {
  my $self = shift;

  $self->{transaction_depth} = 0;
  $self->savepoints([]);
  $self->deferred_rollback(undef);

  local $@;
  $self->_abandon_after_failed_rollback
    unless eval { $self->_exec_txn_rollback; 1 };
}


sub _abandon_handle_before_reconnect { }


sub _throw_deferred_rollback {
  DBIO::Storage::NESTED_ROLLBACK_EXCEPTION->throw(
    "You are in the middle of a deferred rollback from a nested transaction."
    ." No further statements can be executed until the rollback is complete."
  );
}


sub svp_begin {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_begin')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  $name = $self->_svp_generate_name
    unless defined $name;

  push @{ $self->{savepoints} }, $name;

  $self->debugobj->svp_begin($name) if $self->debug;

  $exec->($self, $name);
}


sub _svp_generate_name {
  my ($self) = @_;
  return 'savepoint_'.scalar(@{ $self->{'savepoints'} });
}



sub svp_release {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_release')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if (defined $name) {
    my @stack = @{ $self->savepoints };
    my $svp = '';

    while( $svp ne $name ) {

      $self->throw_exception ("Savepoint '$name' does not exist")
        unless @stack;

      $svp = pop @stack;
    }

    $self->savepoints(\@stack); # put back what's left
  }
  else {
    $name = pop @{ $self->savepoints }
      or $self->throw_exception('No savepoints to release');;
  }

  $self->debugobj->svp_release($name) if $self->debug;

  $exec->($self, $name);
}


sub svp_rollback {
  my ($self, $name) = @_;

  $self->throw_exception ("You can't use savepoints outside a transaction")
    unless $self->transaction_depth;

  my $exec = $self->can('_exec_svp_rollback')
    or $self->throw_exception ("Your Storage implementation doesn't support savepoints");

  # This could happen if savepoints were not enabled at the time rollback was called
  $self->_throw_deferred_rollback if $self->deferred_rollback;

  if (defined $name) {
    my @stack = @{ $self->savepoints };
    my $svp;

    # a rollback doesn't remove the named savepoint,
    # only everything after it
    while (@stack and $stack[-1] ne $name) {
      pop @stack
    };

    $self->throw_exception ("Savepoint '$name' does not exist")
      unless @stack;

    $self->savepoints(\@stack); # put back what's left
  }
  else {
    $name = $self->savepoints->[-1]
      or $self->throw_exception('No savepoints to rollback');;
  }

  $self->debugobj->svp_rollback($name) if $self->debug;

  $exec->($self, $name);
}


sub txn_scope_guard {
  return DBIO::Storage::TxnScopeGuard->new($_[0]);
}


sub sql_maker { die "Virtual method!" }


sub debugfh {
    my $self = shift;

    if ($self->debugobj->can('debugfh')) {
        return $self->debugobj->debugfh(@_);
    }
}


sub debugobj {
  my $self = shift;

  if (@_) {
    return $self->{debugobj} = $_[0];
  }

  $self->{debugobj} ||= do {
    if (my $profile = $ENV{DBIO_TRACE_PROFILE}) {
      require DBIO::Storage::Debug::PrettyTrace;
      my @pp_args;

      if ($profile =~ /^\.?\//) {
        require Config::Any;

        my $cfg = try {
          Config::Any->load_files({ files => [$profile], use_ext => 1 });
        } catch {
          # sanitize the error message a bit
          $_ =~ s/at \s+ .+ Storage\.pm \s line \s \d+ $//x;
          $self->throw_exception("Failure processing \$ENV{DBIO_TRACE_PROFILE}: $_");
        };

        @pp_args = values %{$cfg->[0]};
      }
      else {
        @pp_args = { profile => $profile };
      }

      # FIXME - FRAGILE
      # Hash::Merge is a sorry piece of shit and tramples all over $@
      # *without* throwing an exception
      # This is a rather serious problem in the debug codepath
      # Insulate the condition here with a try{} until a review of
      # DBIO::Storage::Debug::PrettyTrace takes place
      # we do rethrow the error unconditionally, the only reason
      # to try{} is to preserve the precise state of $@ (down
      # to the scalar (if there is one) address level)
      #
      # Yes I am aware this is fragile and TxnScopeGuard needs
      # a better fix. This is another yak to shave... :(
      try {
        DBIO::Storage::Debug::PrettyTrace->new(@pp_args);
      } catch {
        $self->throw_exception($_);
      }
    }
    else {
      require DBIO::Storage::Statistics;
      DBIO::Storage::Statistics->new
    }
  };
}


sub debugcb {
    my $self = shift;

    if ($self->debugobj->can('callback')) {
        return $self->debugobj->callback(@_);
    }
}



sub deploy { die "Virtual method!" }


sub connect_info { die "Virtual method!" }

# --- DBIO-private connect attributes -------------------------------------
# Single authoritative source for the attribute names a caller may pass in
# connect_info that are DBIO-private and must NEVER reach DBI->connect. Both
# connect-info paths consume these lists -- the sync normalizer
# (DBIO::Storage::DBI::_normalize_connect_info) and the async strip
# (DBIO::Storage::Async::connect_info) -- so the two paths can never drift on
# what counts as DBIO-private. They live on this shared base (the common
# ancestor of both DBI and Async storage) rather than on DBIO::Storage::DBI, so
# the async base can reach them without a new Async->DBI dependency direction.

# Storage-config options: routed to the storage, kept out of DBI->connect.
# (cursor_class is a storage option too, but carries its own component_class
# accessor, so it is appended at the split sites rather than listed here.)
# A driver storage may extend this -- override, return
# SUPER::_dbio_storage_option_names plus the driver's own names, and register
# an accessor for each added name in the driver class body
# (mk_group_accessors 'simple'), because both split sites set the option by
# calling that accessor -- the one _dbio_storage_option_accessor names.
sub _dbio_storage_option_names {
  qw/
    on_connect_call on_disconnect_call on_connect_do on_disconnect_do
    disable_sth_caching unsafe auto_savepoint schema
  /;
}

# An option is set through the accessor of its own name, unless it is listed
# here: 'schema' (the connection's namespace, ADR 0065) shares its name with the
# accessor holding the back-reference to the DBIO schema class, so it is kept
# under connection_schema. The map lives once, beside the names; the sync
# normaliser, the connect_info setter and the accessor registration all ask
# _dbio_storage_option_accessor.
sub _dbio_storage_option_accessor_map {
  schema => 'connection_schema',
}

sub _dbio_storage_option_accessor {
  my ($self, $name) = @_;
  my %map = $self->_dbio_storage_option_accessor_map;
  return $map{$name} // $name;
}

# Async options (karr core k397): the connect options an async backend takes.
# With an async mode set they are kept out of the sync storage's own
# DBI->connect and handed to the backend. This is the one place the core names
# are listed; a backend adds its own through
# DBIO::Storage::Async->async_option_names, and the sync storage asks
# DBIO::Storage::DBI::_async_option_names for the union.
sub _core_async_option_names {
  qw/ pool_size acquire_timeout max_waiters txn_timeout reset_timeout /;
}

# SQL-maker options: routed to the sql_maker, kept out of DBI->connect.
sub _dbio_sql_maker_option_names {
  qw/ quote_char name_sep quote_names /;
}


sub select { die "Virtual method!" }


sub insert { die "Virtual method!" }


sub update { die "Virtual method!" }


sub delete { die "Virtual method!" }


sub select_single { die "Virtual method!" }

# The force_pool value the read of a read-then-write call (find_or_create,
# find_or_new, update_or_create, update_or_new, the upsert fallback) carries in
# its attributes. Nothing by default; DBIO::Replicated::Storage answers 'master'.
sub _read_pool_for_read_modify_write { undef }

# Live async backend (a DBIO::Storage::Async) or undef when none configured.
# Overridden in DBIO::Storage::DBI to do real discovery. Base = no backend.
sub _async_storage { undef }

# The connect-time async mode name (ADR 0030), or undef for a sync instance.
# Overridden by the _async_mode accessor on DBIO::Storage::DBI; the base stub
# keeps non-DBI storages on the sync path (their *_async croak).
sub _async_mode { undef }

# Shared dispatch for the six *_async methods (ADR 0030). Three outcomes:
#   - an embedded backend is live    -> route ${op}_async to it (real async)
#   - the instance is in 'immediate' -> run $op synchronously, wrap the result
#     mode (no backend, mode chosen)    in an immediately-resolved future
#   - the instance is sync            -> croak loudly: *_async was called but no
#     (no async mode chosen)             async mode was chosen at connect time
# _async_storage croaks on its own for a chosen-but-unavailable or wrong-type
# mode; the guard below also makes any future undef backend fail closed unless
# its literal mode is 'immediate'.
sub _run_async {
  my ($self, $op, @args) = @_;

  if (my $async = $self->_async_storage) {
    my $method = "${op}_async";
    return $async->$method(@args);
  }

  my $mode = $self->_async_mode;
  $self->throw_exception(
    "not an async connection -- connect with { async => ... } to use ${op}_async"
  ) unless defined $mode;
  $self->throw_exception(
    "async mode '$mode' did not produce a DBIO::Storage::Async backend"
  ) unless $mode eq 'immediate';

  my $fc = $self->future_class;
  my @r = eval { $self->_run_immediate($op, @args) };
  return $fc->done(@r) unless $@;

  my $error = $@;
  # Inside an immediate txn_do_async this failed Future is a statement the
  # transaction's context handed out: its failure fails the transaction,
  # awaited or not (_run_immediate_txn, karr k236).
  $self->_note_immediate_failure($error);
  return $fc->fail($error);
}

# The failed-statement ledger of an immediate txn_do_async (karr k236, k331):
# every failed *_async Future inside the transaction lands here, from the
# storage's own _run_async and from the unbound Row/ResultSet paths, which
# build their failed Future themselves. No-op outside such a transaction.
sub _note_immediate_failure {
  my ($self, $error) = @_;
  push @{ $self->{_immediate_txn_failures} }, $error
    if $self->{_immediate_txn_failures};
  return;
}

# Produce the 'immediate'-mode result for one *_async op (ADR 0053). The value
# a storage-level *_async resolves with is backend-independent: it is the
# transport form a real DBIO::Storage::Async backend resolves with -- the raw
# form the ORM inflation consumes -- NOT whatever the synchronous method happens
# to hand back. In immediate mode there is no backend, so the sync op runs
# in-process here; its return is then shaped to that canonical form.
#
# For most ops the synchronous return already IS the canonical form -- insert
# gives the returned-columns hashref, update/delete the affected-row count --
# so they pass through untouched. The two reads are the exceptions the ticket
# confirmed: sync select returns a cursor and sync select_single a flat row
# list, whereas the canonical async forms are the raw row arrayrefs a cursor's
# ->all yields (select_async) and a single such arrayref, or undef (select_
# single_async). Shape exactly those two, matching a real backend by
# construction (cf. the delegating backend in t/resultset/async_backend.t).
#
# txn_do is the third exception (ADR 0055, karr k207): its callback contract --
# the context handed in and the adoption of a returned Future -- also has to
# match a real backend, so it routes through _run_immediate_txn rather than the
# bare $self->$op pass-through.
sub _run_immediate {
  my ($self, $op, @args) = @_;

  if ($op eq 'select') {
    return $self->select(@args)->all;
  }
  elsif ($op eq 'select_single') {
    my @row = $self->select_single(@args);
    return @row ? [ @row ] : undef;
  }
  elsif ($op eq 'txn_do') {
    return $self->_run_immediate_txn(@args);
  }
  elsif ($op eq '_query') {
    # The raw-SQL seam (DBIO::Storage::DBI::_query_async, karr k282): a
    # statement core rendered itself, resolving with its rows.
    my (undef, $sth) = $self->_execute_rendered(@args);
    return @{ $sth->fetchall_arrayref };
  }

  return $self->$op(@args);
}

# 'immediate'-mode txn_do_async, matching the storage-level txn_do_async
# callback contract of a real DBIO::Storage::Async backend (ADR 0055, karr
# k207). Two axes:
#
#   1. Context argument. A real backend calls $coderef->($txn_ctx, @args) with a
#      DBIO::Storage::Async::TransactionContext pinned to the transaction
#      connection. immediate has no event loop and no pinned connection: the
#      sync op each *_async runs happens IN-PROCESS, already inside the sync
#      transaction this wrapper opens -- so the storage itself IS the context,
#      and $self->*_async are exactly the methods a real backend's context
#      exposes (the documented portable pattern only ever uses *_async /
#      txn_do_async, all present on $self). Hand $self in as the first argument.
#
#   2. Returned-Future adoption. A real backend's _txn_terminal_chain adopts a
#      Future the coderef returns: it commits on the Future's success and
#      resolves with its VALUE(S), or rolls back on its failure. Under immediate
#      every *_async Future is already resolved, so ->get extracts the value(s)
#      without blocking -- and re-raising a failed Future's error as a throw is
#      what makes the enclosing sync txn_do roll back, so the commit-on-success
#      / rollback-on-failure decision matches too. A plain (non-Future) return
#      passes straight through, exactly as $fc->done($inner) would carry it.
#
#   3. A failed statement fails the transaction (karr k236). A real backend
#      refuses COMMIT when any statement Future its context handed out failed,
#      awaited or not, handled by the coderef or not. Here every *_async on the
#      context goes through _run_async, which notes each failure in
#      _immediate_txn_failures while this transaction runs; the first one is
#      rethrown so the enclosing sync txn_do rolls back -- after a failed
#      returned Future, whose own error comes first, as it does there.
#
# The whole body runs in the list context _run_async invokes it under, so
# ->get resolves the full value list a multi-value Future carries.
sub _run_immediate_txn {
  my ($self, $coderef, @args) = @_;

  return $self->txn_do(sub {
    local $self->{_immediate_txn_failures} = [];
    my $inner = $coderef->($self, @args);
    my $adopt = blessed($inner) && $inner->can('then') && $inner->can('get');
    $inner->get if $adopt && $inner->is_failed;
    die $self->{_immediate_txn_failures}[0]
      if @{ $self->{_immediate_txn_failures} };
    return $adopt ? $inner->get : $inner;
  });
}


sub select_async { shift->_run_async('select', @_) }


sub select_single_async { shift->_run_async('select_single', @_) }


sub insert_async { shift->_run_async('insert', @_) }


sub update_async { shift->_run_async('update', @_) }


sub delete_async { shift->_run_async('delete', @_) }


sub txn_do_async { shift->_run_async('txn_do', @_) }


sub future_class {
  my $self = shift;
  if (ref $self and my $async = $self->_async_storage) {
    return $async->future_class;
  }
  require DBIO::Future::Immediate;
  'DBIO::Future::Immediate';
}


sub columns_info_for { die "Virtual method!" }

# Type registry: maps type names to behavior descriptors, keyed by class so
# subclasses can add or override entries. Use type_info() for MRO-aware lookup.
my %_type_registry;


sub register_type {
  my ($class, $type_name, $info) = @_;
  $_type_registry{$class}{$type_name} = $info;
}


sub type_info {
  my ($class, $type_name) = @_;
  for my $pkg (@{ mro::get_linear_isa($class) }) {
    return $_type_registry{$pkg}{$type_name}
      if exists $_type_registry{$pkg}
      && exists $_type_registry{$pkg}{$type_name};
  }
  return undef;
}


sub all_type_names {
  my ($class) = @_;
  my %seen;
  for my $pkg (@{ mro::get_linear_isa($class) }) {
    $seen{$_}++ for keys %{ $_type_registry{$pkg} || {} };
  }
  return keys %seen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage - Generic Storage Handler

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

L<DBIO::Storage> is the abstract base class for storage backends. It contains
the generic transaction, exception, and cursor plumbing shared by concrete
storage implementations.

Most real applications use L<DBIO::Storage::DBI> or a driver-specific subclass
such as PostgreSQL, MySQL, or SQLite storage. This module is where the common
storage contract is defined.

=head1 METHODS

=head2 new

Arguments: $schema

Instantiates the Storage object.

=head2 set_schema

Used to reset the schema class or object which owns this
storage object, such as during L<DBIO::Schema/clone>.

=head2 set_access_broker

Attach an L<DBIO::AccessBroker> instance to this storage and set the
default broker mode (defaults to C<write>). A broker attached before is
detached from this storage first (L<DBIO::AccessBroker/unset_storage>); other
storages stay attached to it.

=head2 clear_access_broker

Detach any currently attached broker from this storage. The broker is told
(L<DBIO::AccessBroker/unset_storage>) and no longer answers for this storage;
the other storages it is attached to are not affected.

This is the broker slot only. A storage that keeps more with a broker extends
it, and L</set_access_broker> where needed: L<DBIO::Storage::DBI> drops the
connect info stored from the broker's answer and takes its embedded async
backend along (L<DBIO::Storage::DBI::AccessBroker/clear_access_broker>), an
async storage drops what came with the broker and has its connect info
provider refuse from then on (L<DBIO::Storage::Async/clear_access_broker>).

=head2 current_access_broker_connect_info

Return the current storage-native connect info for the requested mode:
the attached broker's answer as it stands now, asked again on every call.
Without a broker it returns nothing.

A broker that answers nothing -- C<undef>, an empty hash or array, a false
value -- throws, naming the broker class and the shape of the answer, never a
value. Every storage opens a new connection only with the
broker's current answer: the sync storage's C<_connect>, an async backend's
C<_current_async_connect_info>, and a transport reading this method directly
all get the refusal from here, instead of falling back to connect info stored
from an earlier answer or an earlier connection. A broker that throws is left
to throw.

A view over another broker -- one that answers C<underlying_broker>, as
L<DBIO::AccessBroker::HostBound> does -- hands an answer of nothing on as it
came, so the error names the broker at the bottom that answered nothing, and
the view(s) it was asked through.

=head2 connected

Returns true if we have an open storage connection, false
if it is not (yet) open.

=head2 disconnect

Closes any open storage connection unconditionally.

=head2 ensure_connected

Initiate a connection to the storage if one isn't already open.

=head2 throw_exception

Throws an exception - croaks.

=head2 txn_do

=over 4

=item Arguments: C<$coderef>, @coderef_args?

=item Return Value: The return value of $coderef

=back

Executes C<$coderef> with (optional) arguments C<@coderef_args> atomically,
returning its result (if any). If an exception is caught, a rollback is issued
and the exception is rethrown. If the rollback fails, (i.e. throws an
exception) an exception is thrown that includes a "Rollback failed" message.

For example,

  my $author = $schema->resultset('Author')->find(1);
  my @titles = qw/Night Day It/;

  my $coderef = sub {
    # If any one of these fails, the entire transaction fails
    $author->create_related('books', {
      title => $_
    }) foreach (@titles);

    return $author->books;
  };

  my $rs;
  try {
    $rs = $schema->txn_do($coderef);
  } catch {
    my $error = shift;
    # Transaction failed
    die "something terrible has happened!"
      if ($error =~ /Rollback failed/);          # Rollback failed

    deal_with_failed_transaction();
  };

In a nested transaction (calling txn_do() from within a txn_do() coderef) only
the outermost transaction will issue a L</txn_commit>, and txn_do() can be
called in void, scalar and list context and it will behave as expected.

Please note that all of the code in your coderef, including non-DBIO
code, is part of a transaction.  This transaction may fail out halfway, or
it may get partially double-executed (in the case that our DB connection
failed halfway through the transaction, in which case we reconnect and
restart the txn).  Therefore it is best that any side-effects in your coderef
are idempotent (that is, can be re-executed multiple times and get the
same result), and that you check up on your side-effects in the case of
transaction failure.

Before it reconnects for that restart, a DBI storage disconnects the old
handle and warns: the block must not run a second time next to the
transaction the old handle still holds open. Statement handles of your own
on the old connection are dead from then on.

=head2 txn_begin

Starts a transaction.

See the preferred L</txn_do> method, which allows for
an entire code block to be executed transactionally.

=head2 txn_commit

Issues a commit of the current transaction.

It does I<not> perform an actual storage commit unless there's a DBIO
transaction currently in effect (i.e. you called L</txn_begin>).

If the commit of the outermost transaction fails, the transaction is over
whatever the server says (a deferred constraint is checked at commit time):
the storage resets its transaction state (depth 0, no savepoints, no deferred
rollback) exactly as after a failed rollback, so the next statement is not run
inside a transaction nobody will commit. It then tries a rollback, so that the
server keeps no open transaction; if that fails as well the handle is discarded
(L</_abandon_after_failed_rollback>) and the next statement connects anew. The
error of the commit is rethrown, never that of the rollback. This holds for
every way to a commit: L<DBIO::Storage::TxnScopeGuard/commit>, L</txn_do>,
L<DBIO::Storage::BlockRunner> and a direct call.

=head2 txn_rollback

Issues a rollback of the current transaction (or savepoint, if
auto_savepoint is enabled, and you are in a nested transaction).

If you are in a nested transaction without auto_savepoint, rollback will
put the storage into a "deferred rollback" state and throw a
L<DBIO::Storage::NESTED_ROLLBACK_EXCEPTION> exception
to help you unwind to the outer-most transaction's scope.
Until the "deferred rollback" condition is resolved,
the storage engine will throw exceptions on any attempt to begin, commit,
or rollback a transaction.

If the rollback of the outermost transaction itself fails, the handle is
unusable (the transaction may still be open on the server): the storage resets
its transaction state (depth 0, no savepoints, no deferred rollback), a DBI
storage disconnects the handle without a further rollback and the next
statement connects anew, and the original error is rethrown.

=head2 _abandon_after_failed_rollback

Called by L</txn_rollback> when the rollback of the outermost transaction
itself failed. The handle can no longer be trusted, so the storage forgets the
transaction (depth 0, no savepoints, no deferred rollback); a storage that holds
a connection (L<DBIO::Storage::DBI>) discards it as well. The original error is
rethrown by L</txn_rollback> afterwards.

=head2 _abandon_after_failed_commit

Called by L</txn_commit> when the commit of the outermost transaction failed.
The transaction is over: the state is reset first (depth 0, no savepoints, no
deferred rollback), then a rollback is tried so the server holds no open
transaction, and when that fails too the handle is discarded through
L</_abandon_after_failed_rollback>. Errors of that rollback are swallowed; the
error of the commit is rethrown by L</txn_commit>.

=head2 _abandon_handle_before_reconnect

Called by the retry path of L<DBIO::Storage::BlockRunner> right before it
reconnects. A no-op here; L<DBIO::Storage::DBI> disconnects the old handle.

=head2 _throw_deferred_rollback

=head2 _svp_generate_name

=head2 register_type

  DBIO::PostgreSQL::Storage->register_type('jsonb', {
    cake_options => [qw(inflate_json inflate_jsonb)],
    components   => ['InflateColumn::Serializer'],
    col_attrs    => { serializer_class => 'JSON' },
  });

Registers type metadata for use by L<DBIO::Cake> and other DBIO subsystems.
Driver distributions call this in their module body to declare how their
specific types should be handled. Subclass registrations inherit from and
can override parent class registrations via normal MRO lookup.

=head2 type_info

  my $info = DBIO::PostgreSQL::Storage->type_info('jsonb');

Returns the type metadata for a given type name, walking up the MRO
so subclasses inherit and can override base type definitions.
Returns C<undef> if the type is not registered.

=head2 all_type_names

  my @types = DBIO::PostgreSQL::Storage->all_type_names;

Returns all type names registered for this class and its ancestors
(deduplicated, most-derived class wins).

=head2 svp_begin

Arguments: $savepoint_name?

Created a new savepoint using the name provided as argument. If no name
is provided, one is generated from the number of savepoints currently open:
C<savepoint_0>, C<savepoint_1>, ...

=head2 svp_release

Arguments: $savepoint_name?

Release the savepoint provided as argument. If none is provided,
release the savepoint created most recently. This will implicitly
release all savepoints created after the one explicitly released as well.

=head2 svp_rollback

Arguments: $savepoint_name?

Rollback to the savepoint provided as argument. If none is provided,
rollback to the savepoint created most recently. This will implicitly
release all savepoints created after the savepoint we rollback to.

=head2 txn_scope_guard

An alternative way of transaction handling based on
L<DBIO::Storage::TxnScopeGuard>:

 my $txn_guard = $storage->txn_scope_guard;

 $result->col1("val1");
 $result->update;

 $txn_guard->commit;

If an exception occurs, or the guard object otherwise leaves the scope
before C<< $txn_guard->commit >> is called, the transaction will be rolled
back by an explicit L</txn_rollback> call. In essence this is akin to
using a L</txn_begin>/L</txn_commit> pair, without having to worry
about calling L</txn_rollback> at the right places. Note that since there
is no defined code closure, there will be no retries and other magic upon
database disconnection. If you need such functionality see L</txn_do>.

=head2 sql_maker

Returns a C<sql_maker> object - normally an object of class
C<DBIO::SQLMaker>.

=head2 debug

Causes trace information to be emitted on the L</debugobj> object.
(or C<STDERR> if L</debugobj> has not specifically been set).

The value is the trace level: C<debug(1)> traces the statement, C<debug(2)>
adds the bind values (see L</DBIO_TRACE>). This is the equivalent to setting
C<DBIO_TRACE> in your shell environment.

=head2 debugfh

An opportunistic proxy to L<< ->debugobj->debugfh(@_)
|DBIO::Storage::Statistics/debugfh >>
If the currently set L</debugobj> does not have a L</debugfh> method, caling
this is a no-op.

=head2 debugobj

Sets or retrieves the object used for metric collection. Defaults to an instance
of L<DBIO::Storage::Statistics> that is compatible with the original
method of using a coderef as a callback.  See the aforementioned Statistics
class for more information.

=head2 debugcb

Sets a callback to be executed each time a statement is run; takes a sub
reference.  Callback is executed as $sub->($op, $info) where $op is
SELECT/INSERT/UPDATE/DELETE and $info is what would normally be printed.

See L</debugobj> for a better way.

=head2 cursor_class

The cursor class for this Storage object.

=head2 deploy

Deploy the tables to storage (CREATE TABLE and friends in a SQL-based
Storage class). This would normally be called through
L<DBIO::Schema/deploy>.

=head2 connect_info

The arguments of C<connect_info> are always a single array reference,
and are Storage-handler specific.

This is normally accessed via L<DBIO::Schema/connection>, which
encapsulates its argument list in an arrayref before calling
C<connect_info> here.

=head2 select

Handle a select statement.

=head2 insert

Handle an insert statement.

=head2 update

Handle an update statement.

=head2 delete

Handle a delete statement.

=head2 select_single

Performs a select, fetch and return of data - handles a single row
only.

=head2 select_async

Async variant of L</select>. Returns a L<DBIO::Future> that resolves with the
query result rows as raw arrayrefs -- the same C<< cursor->all >> shape a real
L<DBIO::Storage::Async> backend resolves with (ADR 0053), so the storage-level
C<select_async> contract is the same across every async mode. Requires an async
connection (C<< connect(..., { async => ... }) >>); on a sync instance it
croaks. In the C<immediate> mode it runs synchronously and returns an
immediately-resolved Future via L</future_class> carrying that same form.

=head2 select_single_async

Async variant of L</select_single>. Resolves with a single raw row arrayref, or
C<undef> when there is no row -- the same form a real L<DBIO::Storage::Async>
backend resolves with (ADR 0053), rather than the flat column list synchronous
L</select_single> returns.

=head2 insert_async

Async variant of L</insert>.

=head2 update_async

Async variant of L</update>.

=head2 delete_async

Async variant of L</delete>.

=head2 txn_do_async

Async variant of L</txn_do>. Returns a L<DBIO::Future> that resolves
after COMMIT or rejects after ROLLBACK.

The coderef is called with a transaction context as its first argument,
followed by any extra C<txn_do_async> arguments:
C<< $coderef->($ctx, @args) >>. On a real L<DBIO::Storage::Async> backend
C<$ctx> is a L<DBIO::Storage::Async::TransactionContext> pinned to the
transaction connection; in the C<immediate> mode it is the storage itself
(its C<*_async> methods run in-process inside the transaction), so the
portable pattern C<< sub { my ($ctx) = @_; $ctx->insert_async(...) } >> is
substitutable across modes (ADR 0055). A L<DBIO::Future> returned by the
coderef is B<adopted>: the transaction resolves with that Future's value(s)
on success and rolls back on its failure -- the same across every async mode.

A statement Future the context handed out that failed rolls the transaction
back as well, and the transaction fails with that statement's error -- also
when nothing awaited it, and also when the coderef caught the failure and
returned normally. The same across every async mode (see
L<DBIO::Storage::Async/txn_do_async>).

C<$ctx> is also what a ResultSet, Row or ResultSetColumn is bound to with
C<with_context>, in every async mode (L<DBIO::ResultSet/with_context>). In the
C<immediate> mode that is this storage: a bound object's C<*_async> run
in-process inside the transaction, its failed statements fail the transaction
like the context's own, and once the coderef has returned it is refused. The
storage's own C<*_async> methods are not guarded that way -- called after the
transaction they simply run outside it.

=head2 future_class

Returns the class name used to construct Future objects. Defaults to
L<DBIO::Future::Immediate> which resolves synchronously. Async storage
drivers override this to return their event loop's Future class.

=head2 columns_info_for

Returns metadata for the given source's columns.  This
is *deprecated*, and will be removed before 1.0.  You should
be specifying the metadata yourself if you need it.

=head1 ENVIRONMENT VARIABLES

=head2 DBIO_TRACE

If C<DBIO_TRACE> is set then trace information
is produced (as when the L</debug> method is set).

C<DBIO_TRACE=1> traces the statement. C<DBIO_TRACE=2> adds the bind values:
each value is run through the C<redact_bind_value> hook
(L<DBIO::Storage::DBI/redact_bind_value>) and cut to 32 characters, with
C<...> marking the cut; C<undef> is traced as C<NULL>. The level is the
leading digits of the value (C<2=/path/name> is level 2); any other true value
is level 1. The synchronous storage, L<DBIO::Replicated> and the asynchronous
transports follow this one rule, and L</debug> holds the level.

If the value is of the form C<N=/path/name> (N the level) then the trace output is
written to the file C</path/name>. The file is opened for append and, when
the trace creates it, is readable by its owner alone (mode 0600). The
statements of connect actions are traced with the secrets they carry shown as
C<***[sha256:E<lt>8 hexE<gt>]>, a fingerprint of the value.

This environment variable is checked when the storage object is first
created (when you call connect on your schema).  So, run-time changes
to this environment variable will not take effect unless you also
re-connect on your schema.

=head2 DBIO_TRACE_PROFILE

If C<DBIO_TRACE_PROFILE> is set,
L<DBIO::Storage::Debug::PrettyTrace> will be used to format the output
from C<DBIO_TRACE>.  The value it
is set to is the C<profile> that it will be used.  If the value is a
filename the file is read with L<Config::Any> and the results are
used as the configuration for tracing.  See L<SQL::Abstract::Tree/new>
for what that structure should look like.

=head1 SEE ALSO

L<DBIO::Storage::DBI> - reference storage implementation using
DBI and a subclass of SQL::Abstract ( or similar )

1;

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
