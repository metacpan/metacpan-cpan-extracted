package DBIO::Storage::Async;
# ABSTRACT: Base class for async storage implementations

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage';

use Carp 'croak';
use Scalar::Util qw(blessed weaken refaddr);
use DBIO::Storage::Async::TransactionContext;
use DBIO::Storage::Async::PipelineContext;
use DBIO::Storage::PoolBase ();
use DBIO::SQL::Util ();
use DBIO::Util qw(bare_binds mask_connect_secrets mask_statement_fingerprint);
use DBIO::Exception::Server ();
# Reused for its DDL grouping (deploy_async, ADR 0026 addendum / k132 async
# parity): the async deploy asks the SAME per-statement transactional hook and
# gets the SAME order/grouping as the sync path, so the grouping is a single
# source of truth rather than a re-implementation. DBIO::Deploy::Base itself is
# light -- only DBIO::SQL::Util + Scalar::Util -- and does not pull the deploy
# machinery. Loaded without importing (namespace clean).
use DBIO::Deploy::Base ();
# A backend used as a PRIMARY storage with no embedding sync owner provisions
# its own private sync sibling to prepare SELECT args and anchor context
# ownership (ADR 0051, karr k204). DBIO::Storage::DBI does not use this class at
# compile time, so this is not a circular use.
use DBIO::Storage::DBI ();
use namespace::clean;


sub new {
  my ($class, $schema, $args) = @_;
  my $self = bless {
    schema             => $schema,
    pool               => undef,
    connect_info       => undef,
    sql_maker          => undef,
    _conninfo_provider => undef,
    debug              => $class->_trace_level_of($ENV{DBIO_TRACE}),
    debugobj           => undef,
  }, $class;
  weaken($self->{schema}) if ref $self->{schema};
  $self->_rotate_context_owner_token;
  return $self;
}

# Each backend/pool generation is identified only by this fresh reference. It
# is intentionally opaque: class, DSN and schema equality prove no ownership.
sub _new_context_owner_token {
  my $opaque;
  return \$opaque;
}

sub _context_owner_token {
  my ($self) = @_;
  return $self->{_context_owner_token};
}

# Rotate locally first, then mirror onto the concrete sync owner only if that
# owner still caches this backend. DBIO::Storage::DBI performs the stale-backend
# identity check in _adopt_async_context_owner_token.
sub _rotate_context_owner_token {
  my ($self) = @_;
  my $token = $self->_new_context_owner_token;
  $self->{_context_owner_token} = $token;
  if (my $owner = $self->_owner_storage) {
    $owner->_adopt_async_context_owner_token($self, $token)
      if $owner->can('_adopt_async_context_owner_token');
  }
  # A self-provisioned owner (karr k204) is private to this backend and caches
  # no backend of its own, so the stale-backend guard in
  # _adopt_async_context_owner_token would refuse it -- seed it directly so it
  # stays in lockstep across reconfiguration/disconnect generations.
  if (my $self_owner = $self->{_self_owner_storage}) {
    $self_owner->_async_context_owner_token($token);
  }
  return $token;
}


sub future_class {
  croak 'Subclass must override future_class';
}


sub pool {
  croak 'Subclass must override pool';
}


sub _is_access_broker_connect_info {
  my ($self, $info) = @_;

  return 0 unless ref $info eq 'ARRAY' && @$info == 1;
  return 0 unless blessed($info->[0]);

  return $info->[0]->isa('DBIO::AccessBroker');
}


sub set_access_broker {
  my ($self, $broker, $mode) = @_;

  $self->next::method($broker, $mode);

  delete @{$self}{qw( _conninfo _pool_size _opts _access_broker_call_attributes )};

  weaken(my $storage = $self);
  $self->{_conninfo_provider} = sub {
    croak 'This AccessBroker connect info provider cannot answer: the async '
        . 'storage it was made for is gone'
      unless $storage;
    # The provider outlives a detached broker: on the storage, and in a pool
    # built with it. There is nobody to ask then, and nothing stored to
    # connect from instead (karr k273). The words are the transports' own.
    croak sprintf '%s has no AccessBroker attached to ask for connect info',
      ref $storage
      unless $storage->access_broker;
    return $storage->_async_broker_conninfo($storage->access_broker_mode);
  };

  # A pool built before this attach holds the provider or the static conninfo
  # it was built with. It is handed this provider, so its next connection is
  # opened from the broker attached now. What is open stays open and a
  # transaction stays on its connection, with the broker it began with (karr
  # k331). Read from the slot, not through pool(): that would build a pool, and
  # not every transport has one. A pool without the setter is left as it is.
  my $built = $self->{pool};
  $built->set_conninfo_provider($self->{_conninfo_provider})
    if blessed($built) && $built->can('set_conninfo_provider');

  return $self;
}


sub clear_access_broker {
  my $self = shift;

  delete @{$self}{qw( _pool_size _opts _access_broker_call_attributes )}
    if $self->access_broker;

  return $self->next::method(@_);
}


sub _setup_access_broker {
  my ($self, $broker) = @_;
  return $self->set_access_broker($broker, 'write');
}


sub _clear_access_broker {
  my $self = shift;

  $self->clear_access_broker;
  delete @{$self}{qw(
    _conninfo_provider _conninfo _pool_size _opts _access_broker_call_attributes
  )};

  return $self;
}


sub _conninfo_provider { $_[0]->{_conninfo_provider} }


sub _async_broker_conninfo {
  croak 'Subclass must override _async_broker_conninfo to consume an AccessBroker';
}


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
    # A connect_info setter always opens a new ownership generation. disconnect
    # performs the rotation when a pool exists; without a materialised pool we
    # still rotate here so contexts cannot survive reconfiguration. Listen state
    # goes through disconnect too: its connection was opened with the old info.
    if ($self->{pool} || $self->{_listen}) {
      $self->disconnect;
    }
    else {
      $self->_rotate_context_owner_token;
    }

    # ADR 0050: a connect_info is a full reconfiguration, also one that throws
    # (karr k283). Everything the call before left is forgotten here, before
    # anything of the new connect info is read -- reading can throw: a
    # driver's reshape seam, the refusal of options beside a broker, the
    # broker itself, an answer of nothing or of no usable shape, two pool
    # sizes that disagree. What is set below is this call's.
    $self->_clear_access_broker;
    $self->{connect_info} = undef;

    # Strip DBIO-private attrs before the DB-specific reshape seam,
    # so _normalize_conninfo (and DBI->connect) only see real DBD attributes.
    $info = $self->_strip_private_connect_attrs($info);
    $info = $self->_normalize_conninfo($info);
    my $beside = $self->_access_broker_call_options($info);
    $self->{connect_info} = $info;

    if ($beside || $self->_is_access_broker_connect_info($info)) {
      # No conninfo is kept with a broker attached (karr k252): every
      # connection asks the broker anew (_conninfo_provider), so a stored copy
      # could only ever be an earlier answer -- password included -- which
      # nothing may use.
      $self->_setup_access_broker($info->[0]);
      # What stands beside the broker is kept before the answer is read: with
      # the broker attached, a connection opened after a refused answer must
      # not be opened without it.
      $self->{_access_broker_call_attributes} = $beside->{attributes} if $beside;
      my $answer = $self->_current_async_connect_info($self->access_broker_mode);
      my (undef, $pool_size, $opts) = $self->_normalize_async_connect_info($answer);
      my $given_pool_size = $self->_access_broker_pool_size($answer, $beside);
      $pool_size = $given_pool_size if defined $given_pool_size;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
    else {
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info($info);
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
  }
  return $self->{connect_info};
}


sub _access_broker_call_options {
  my ($self, $info) = @_;

  return undef unless ref $info eq 'ARRAY' && @$info == 2
    && ref $info->[1] eq 'HASH'
    && blessed($info->[0]) && $info->[0]->isa('DBIO::AccessBroker');

  my %attributes = %{ $info->[1] };
  my $pool_size  = delete $attributes{pool_size};

  $self->throw_exception(
    'Transport ' . (ref($self) || $self) . ' does not take connection settings '
  . 'beside an AccessBroker (it does not declare '
  . "'broker_connect_options' among its transport_capabilities): "
  . join(', ', sort keys %{ $info->[1] })
  ) if (%attributes || defined $pool_size)
    && !$self->_takes_broker_connect_options;

  return { pool_size => $pool_size, attributes => \%attributes };
}


sub _access_broker_call_attributes {
  return $_[0]->{_access_broker_call_attributes} || {};
}


sub _access_broker_pool_size {
  my ($self, $answer, $beside) = @_;

  # The answer's attribute hashes, a later one winning -- the slots
  # _strip_private_connect_attrs finds, merged the way
  # DBIO::Storage::DBI::_normalize_connect_info merges them.
  my @attr_hashes;
  if (ref $answer eq 'ARRAY') {
    @attr_hashes = ref $answer->[0] eq 'HASH' ? $answer->[0]        # [ \%conninfo, \%opts ]
                 : ref $answer->[0] eq 'CODE' ? $answer->[1]        # [ $coderef, \%extra ]
                 :                              @{$answer}[3, 4];   # [ $dsn, $user, $pass, \%attrs ]
  }

  my %answered;
  for my $attrs (grep { ref $_ eq 'HASH' } @attr_hashes) {
    $answered{pool_size} = $attrs->{pool_size} if defined $attrs->{pool_size};
  }

  my %given_beside;
  $given_beside{pool_size} = $beside->{pool_size}
    if $beside && defined $beside->{pool_size};

  return $self->_merge_access_broker_settings(\%answered, \%given_beside)->{pool_size};
}


sub _core_read_capabilities { qw(broker_connect_options) }

sub _takes_broker_connect_options {
  my $self = shift;
  return scalar grep { $_ eq 'broker_connect_options' } $self->transport_capabilities;
}


sub _current_async_connect_info {
  my ($self, $mode) = @_;

  return [ $self->{_conninfo}, $self->{_opts} || {} ]
    unless $self->access_broker;

  my $answer = $self->current_access_broker_connect_info($mode);
  return ref $answer eq 'HASH' ? [ $answer, {} ] : $answer;
}

# Split a [ \%conninfo, \%opts ] pair into ($conninfo, $pool_size, $opts),
# working on copies so the caller's structures are never mutated. pool_size
# is stripped out of the conninfo (default 5); opts default to an empty hash.
#
# Connect info that is something, but no array, throws -- naming its shape and,
# with a broker attached, the broker class it is taken to be the answer of;
# never a value (karr k264). $info->[0] on a plain string dies quoting the
# string, and that may be a DSN carrying a password. The refusal sits here
# rather than in _current_async_connect_info so that a transport reading the
# answer there can still name an unusable one in its own words.
sub _normalize_async_connect_info {
  my ($self, $info) = @_;

  if (defined $info && ref $info ne 'ARRAY') {
    my $shape = !ref $info      ? 'a plain scalar'
              : blessed($info)  ? 'an object of class ' . ref $info
              :                   'a ' . ref($info) . ' reference';
    my $broker = ref $self ? $self->access_broker : undef;

    $self->throw_exception(
      $broker
      ? 'AccessBroker ' . ref($broker) . ' answered connect info an async '
      . "storage cannot connect from ($shape). It takes a hash of connection "
      . 'parameters, or an array such as the DBI form '
      . '[ $dsn, $user, $password, \%attrs ].'
      : "An async storage cannot connect from this connect info ($shape). It "
      . 'takes an array, such as [ \%conninfo, \%options ] or the DBI form '
      . '[ $dsn, $user, $password, \%attrs ].'
    );
  }

  my $conninfo = $info->[0];
  $conninfo = ref($conninfo) eq 'HASH' ? { %$conninfo } : $conninfo;

  my $opts = $info->[1];
  $opts = ref($opts) eq 'HASH' ? { %$opts } : {};

  my $pool_size = 5;
  if (ref($conninfo) eq 'HASH') {
    $pool_size = delete $conninfo->{pool_size} // 5;
  }

  return ($conninfo, $pool_size, $opts);
}


sub _normalize_conninfo { return $_[1] }


sub async_option_names { () }


sub declared_async_option_names {
  my ($class) = @_;
  my %seen;
  return grep { !$seen{$_}++ } $class->_core_async_option_names, $class->async_option_names;
}


sub async_option {
  my ($self, $name) = @_;
  return $self->{_async_options} ? $self->{_async_options}{$name} : undef;
}

# The core checks the values of the options it owns; a backend checks its own
# (async_option_names).
sub _assert_async_option {
  my ($self, $name, $value) = @_;
  DBIO::Storage::PoolBase->assert_limit_option($name => $value)
    if grep { $_ eq $name } qw( acquire_timeout max_waiters txn_timeout reset_timeout );
  return;
}


sub _delay {
  my ($self, $seconds) = @_;
  return $self->_listen_delay($seconds);
}

# Pull the DBIO-private connect attributes out of the incoming RAW
# connect info BEFORE the DB-specific _normalize_conninfo seam reshapes it (e.g.
# folds attrs into a libpq hash), so that seam -- and ultimately DBI->connect --
# only ever sees real DBD attributes. The sync path does the equivalent split in
# DBIO::Storage::DBI::_normalize_connect_info; both consume the same private-attr
# name lists on DBIO::Storage (_dbio_storage_option_names /
# _dbio_sql_maker_option_names), so the two paths cannot drift.
#
# The incoming info is the raw DBI array form _async_storage hands us (the same
# shapes _normalize_connect_info parses): dsn/user/pass + \%attrs[+\%extra],
# a single \%hash (Catalyst-style), or a coderef + \%extra. We locate the attr
# hash(es) of whichever form, strip the private attrs out of a COPY, and pass
# everything else through untouched -- never mutating the caller's structure.
# Broker-form info ([$broker]) carries no caller attr hash and is left as-is;
# the connect options beside a broker ([$broker, \%options], karr k243) are
# stripped like any other attr hash.
sub _strip_private_connect_attrs {
  my ($self, $info) = @_;

  # Every call is a new reading of the connect info: what the one before left
  # as async options is gone, whatever form this one comes in (karr core k397).
  $self->{_async_options} = {};
  my %async_options;

  return $info
    if ref $info ne 'ARRAY'
    or $self->_is_access_broker_connect_info($info);

  my @args = @$info;   # shallow copy; the attr hashes below are copied before mutation

  my @attr_slots;
  if (ref $args[0] eq 'CODE') {         # coderef + optional \%extra_attributes
    push @attr_slots, \$args[1] if ref $args[1] eq 'HASH';
  }
  elsif (blessed($args[0]) && $args[0]->isa('DBIO::AccessBroker')) {
    push @attr_slots, \$args[1] if ref $args[1] eq 'HASH';   # broker + \%options
  }
  elsif (ref $args[0] eq 'HASH') {      # single \%hash (Catalyst-style config)
    push @attr_slots, \$args[0];
  }
  else {                                # dsn/user/pass + \%attrs [+ \%extra_attrs]
    push @attr_slots, \$args[$_] for grep ref $args[$_] eq 'HASH', 3, 4;
  }

  my @storage_opt_names = ($self->_dbio_storage_option_names, 'cursor_class');
  my %storage_options;

  for my $slot (@attr_slots) {
    my %attrs = %{ $$slot };   # copy before mutating

    # storage_options + cursor_class -> keep for the storage, out of
    # DBI->connect. Same sink the sync path uses (DBIO::Storage::DBI stashes
    # these as storage_options). Held for the pool on_connect seam
    # (on_connect_do / on_connect_call) to consume; no further processing here.
    $storage_options{$_} = delete $attrs{$_}
      for grep exists $attrs{$_}, @storage_opt_names;

    # quote_char/name_sep/quote_names -> sql_maker config, not DBD attrs. The
    # async sql_maker path (_sql_maker_args) does not source quoting from
    # connect_info yet (driver adapters set quote_char statically), so dropping
    # them is correct for now. Their proper future sink is the backend's
    # sql_maker -- see the TODO block in t/storage/async_connect_info_leak.t so
    # a later async-quoting feature does not pull them back into raw DBD attrs.
    delete @attrs{ $self->_dbio_sql_maker_option_names };

    # async -> mode selector; the backend already knows its own mode, so it must
    # never reach DBI->connect. ignore_version -> consumed by the
    # DeploymentHandler version-storage component, never by the DBD.
    delete @attrs{qw( async ignore_version )};

    # The async options other than pool_size -- the core's and those this
    # backend declares (async_option_names) -- are the backend's own: kept for
    # async_option, out of what reaches the transport's reshape seam and
    # DBI->connect. pool_size stays where it always was, in the conninfo, for
    # _normalize_async_connect_info. A later slot wins, as the attribute hashes
    # of the DBI form merge (karr core k397).
    for my $name (grep { $_ ne 'pool_size' } $self->declared_async_option_names) {
      next unless exists $attrs{$name};
      my $value = delete $attrs{$name};
      next unless defined $value;
      $self->_assert_async_option($name => $value);
      $async_options{$name} = $value;
    }

    $$slot = \%attrs;
  }

  # Slot the storage options aside; nothing consumes them yet.
  $self->{_storage_options} = \%storage_options;
  $self->{_async_options}   = \%async_options;

  return \@args;
}


sub _owner_storage {
  my $self = shift;
  if (@_) {
    $self->{_owner_storage} = $_[0];
    weaken($self->{_owner_storage}) if ref $self->{_owner_storage};
    # An external owner supersedes any self-provisioned sibling: the embedding
    # sync storage is the authoritative owner (it carries the real capabilities,
    # on_connect actions and DSN). Drop the fallback so there is exactly one.
    delete $self->{_self_owner_storage} if ref $self->{_owner_storage};
  }
  return $self->{_owner_storage};
}


sub _effective_owner_storage {
  my ($self) = @_;
  if (my $owner = $self->_owner_storage) {
    return $owner;
  }
  return $self->{_self_owner_storage} ||= $self->_build_self_owner_storage;
}

# Build the private sync owner for a primary (unowned) backend. It is a plain
# DBIO::Storage::DBI -- _select_args is core-only, no driver overrides it -- that
# SHARES this backend's already-configured sql_maker, so the args it prepares
# are byte-identical to the ones the async path would build with its own maker
# (the mock-cursor / real-cursor parity invariant, karr core k55 / ADR 0046).
# It carries this backend's current context-owner token so ownership assertions
# on it succeed, and it is held STRONGLY (unlike the weak _owner_storage
# back-reference) because nothing else keeps it alive. No connection is opened:
# _select_args and the token machinery never touch a dbh.
sub _build_self_owner_storage {
  my ($self) = @_;
  my $owner = DBIO::Storage::DBI->new($self->schema);
  $owner->_sql_maker($self->sql_maker);
  $owner->_async_context_owner_token($self->_context_owner_token);
  return $owner;
}

# Resolve the effective owner of $storage with backward compatibility for a
# storage that fulfils only the older _owner_storage contract and never gained
# _effective_owner_storage -- a bare driver MOCK that plays the backend role for
# a context without subclassing this class (karr k204 addendum). A real async
# storage runs its self-provisioning resolver; such a mock falls back to its
# wired _owner_storage, which IS its effective owner (a wired owner always wins
# over a self-provisioned sibling), and an ownerless mock still yields undef so
# the caller throws the same "requires its owning sync storage" /
# "ownership cannot be proven" message as before. Single source of truth so the
# call-sites (here, TransactionContext, PipelineContext) never drift. A plain
# function, not a method: the invocant may lack the method entirely.
sub _effective_owner_of {
  my ($storage) = @_;
  return $storage->can('_effective_owner_storage')
    ? $storage->_effective_owner_storage
    : $storage->_owner_storage;
}


sub _setup_pool_connection {
  my ($self, $conn) = @_;

  my $owner = $self->_owner_storage or return;
  return unless $owner->can('_run_pool_connect_actions');

  $owner->_run_pool_connect_actions($self->_pool_connect_runner($conn));

  return;
}


sub _teardown_pool_connection {
  my ($self, $conn) = @_;

  my $owner = $self->_owner_storage or return;
  return unless $owner->can('_run_pool_disconnect_actions');

  $owner->_run_pool_disconnect_actions($self->_pool_connect_runner($conn));

  return;
}

# The runner the owning sync storage gets for the statements of the connect and
# disconnect actions: it executes each on $conn through
# _run_pool_connect_statement and traces it like the sync path does
# (_do_query): _debug_query with the statement in its fingerprint form, no
# binds shown, query_end after the statement succeeded. The row queries of a
# connect_call_* (dbio_rows) are not traced and return their rows.
sub _pool_connect_runner {
  my ($self, $conn) = @_;

  return sub {
    my ($sql, $attrs, @bind) = @_;

    my $rows_query = ref $attrs eq 'HASH' && $attrs->{dbio_rows};
    my $end = $rows_query
      ? undef
      : $self->_debug_query(mask_statement_fingerprint($sql), \@bind);

    my @result = $self->_run_pool_connect_statement($conn, $sql, $attrs, @bind);
    $end->() if $end;

    return wantarray ? @result : $result[0];
  };
}


sub _reset_pool_connection {
  my ($self, $conn) = @_;
  return $self->future_class->fail(
    ref($self) . ' has no _reset_pool_connection: the connection is retired'
  );
}


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, @args) = @_;
  my $dbh = $self->_pool_connect_dbh($conn);

  if (ref $args[0] eq 'HASH' and $args[0]{dbio_rows}) {
    my (undef, @bind) = @args;
    return $dbh->selectall_arrayref($sql, undef, @bind);
  }

  $dbh->do($sql, @args);
  return;
}

# Extract a blocking-do-capable DBI handle from a pool connection value. The two
# shapes the DBD-based Model-B backends use are a bare $dbh and the future_io
# { dbh => $dbh } wrapper (DBIO::PostgreSQL::Storage::Async::_create_pool_connection
# and friends). Anything else is a native backend that must override
# _run_pool_connect_statement.
sub _pool_connect_dbh {
  my ($self, $conn) = @_;

  return $conn
    if blessed($conn) && $conn->can('do');

  return $conn->{dbh}
    if ref $conn eq 'HASH' && blessed($conn->{dbh}) && $conn->{dbh}->can('do');

  croak 'Cannot run pool connect action: connection is neither a do-capable '
      . 'DBI handle nor a { dbh => $dbh } wrapper -- override '
      . '_run_pool_connect_statement for this backend';
}


sub sql_maker {
  my $self = shift;
  $self->{sql_maker} ||= do {
    my $class = $self->sql_maker_class;
    $class->new($self->_sql_maker_args);
  };
}


sub sql_maker_class {
  croak 'Subclass must override sql_maker_class';
}


sub _sql_maker_args { () }


sub transport_capabilities { () }


sub select_async {
  my $self = shift;
  return $self->_run_crud_pooled('select', @_);
}


sub select_single_async {
  my $self = shift;
  return $self->_run_crud_pooled('select_single', @_);
}


sub insert_async {
  my $self = shift;
  return $self->_run_crud_pooled('insert', @_);
}


sub update_async {
  my $self = shift;
  return $self->_run_crud_pooled('update', @_);
}


sub delete_async {
  my $self = shift;
  return $self->_run_crud_pooled('delete', @_);
}

# Prepare a SELECT through the owning sync storage, preserving the exact
# validation, join pruning and complex-prefetch rewrite its cursor path uses.
# _select_args returns the operation name first; the async SQLMaker consumes
# only the prepared select arguments that follow it.
sub _prepare_select_args_async {
  my ($self, $ident, $select, $where, $attrs) = @_;
  $attrs = {} unless defined $attrs;

  my $owner = _effective_owner_of($self);
  $self->throw_exception('async SELECT requires its owning sync storage')
    unless $owner && $owner->can('_select_args');

  my @prepared = $owner->_select_args($ident, $select, $where, $attrs);
  shift @prepared;
  return @prepared;
}


# The DB-specific INSERT-column retrieval (_post_insert_sql) and first-row
# post-processing for select_single live here exactly once, so the pooled path
# (_pool_runner) and the pinned txn path (_pinned_runner, used by the
# TransactionContext) share identical behaviour.
sub _run_crud {
  my ($self, $op, $runner, @args) = @_;

  my $sm = $self->sql_maker;
  if ($op eq 'select' || $op eq 'select_single') {
    my $ident = $args[0];
    @args = $self->_prepare_select_args_async(@args);
    my $attrs = $args[3] || {};
    my ($sql, @bind) = $sm->select(@args);
    # as in _gen_sql_bind: the values of the bind attribute go first
    @bind = bare_binds(@{ $attrs->{bind} || [] }, @bind);
    my $bind_attrs = $self->_crud_bind_attrs(select => $ident, \@bind, @args);
    my $future = $runner->($sql, \@bind, $bind_attrs);

    if ($op eq 'select' && $attrs->{software_limit}) {
      my $rows   = $attrs->{rows};
      my $offset = $attrs->{offset} || 0;
      my $fc = $self->future_class;
      $future = $future->then(sub {
        my @raw_rows = @_;
        splice @raw_rows, 0, $offset if $offset;
        splice @raw_rows, $rows if $rows && @raw_rows > $rows;
        return $fc->done(@raw_rows);
      });
    }

    return $self->_hold_derived($future) unless $op eq 'select_single';
    return $self->_hold_derived($future->then(sub {
      my @rows = @_;
      return @rows ? $rows[0] : undef;
    }));
  }
  elsif ($op eq 'insert') {
    # The CRUD contract is insert_async($source, \%rowdata) (ADR 0031 §3),
    # where $source is a result source. SQLMaker wants a plain table name,
    # so unwrap a blessed source to its ->name; a bare string passes through.
    my ($source, @rest) = @args;
    my $to_insert = $rest[0];
    my $table = (blessed($source) && $source->can('name'))
      ? $source->name
      : $source;

    # The sync insert fills an auto_nextval column that has no value through
    # _prefetch_autovalues; this path has no such seam yet, so a missing value
    # is refused here instead of reaching the server as NULL or a NOT NULL
    # error.
    if (blessed($source) && $source->can('columns_info')) {
      my $colinfo = $source->columns_info;
      if (my @missing = grep {
        $colinfo->{$_}{auto_nextval}
          and ! (ref $to_insert eq 'HASH' && exists $to_insert->{$_})
      } sort keys %$colinfo) {
        $self->throw_exception( sprintf(
          'insert_async cannot fill the auto_nextval column%s %s of %s: the '
        . 'asynchronous insert does not fetch the sequence value the '
        . 'synchronous insert fetches. Give %s a value on insert (literal '
        . 'SQL such as \\"nextval(...)" counts), or use the synchronous '
        . 'insert',
          ( @missing > 1 ? 's' : '' ),
          join(', ', map { "'$_'" } @missing),
          $source->source_name,
          ( @missing > 1 ? 'them' : 'it' ),
        ));
      }
    }

    my ($sql, @bind) = $sm->insert($table, _own_options(insert => @rest));
    @bind = bare_binds(@bind);
    my $post = $self->_post_insert_sql;
    $sql .= $post if length $post && $sql !~ /RETURNING/i;
    my $bind_attrs = $self->_crud_bind_attrs(insert => $source, \@bind, $table, @rest);

    # ADR 0031 §3: insert_async must resolve the returned-columns HASHREF --
    # the supplied insert data overlaid with the DB-populated columns (autoinc
    # PK + retrieve-on-insert), exactly what sync $storage->insert returns --
    # so create_async / Row::insert_async can fold it back via
    # _store_inserted_columns. The runner yields the raw RETURNING row(s); map
    # the first onto the insert data. (select_async / select_single_async keep
    # resolving raw arrayrefs, matching the sync cursor shape.)
    return $self->_hold_derived($runner->($sql, \@bind, $bind_attrs)->then(sub {
      my @rows = @_;
      return $self->_insert_returned_columns($source, $to_insert, $rows[0]);
    }));
  }
  elsif ($op eq 'update') {
    # Same CRUD contract shape as insert: update_async($source, \%vals,
    # \%where), $source a result source. SQLMaker wants a plain table name --
    # unwrap a blessed source to its ->name here too, exactly like the insert
    # branch above; a bare string passes through unchanged.
    my ($source, @rest) = @args;
    my $table = (blessed($source) && $source->can('name'))
      ? $source->name
      : $source;

    my ($sql, @bind) = $sm->update($table, _own_options(update => @rest));
    @bind = bare_binds(@bind);
    my $bind_attrs = $self->_crud_bind_attrs(update => $source, \@bind, $table, @rest);

    # update_async must resolve the affected-row COUNT (a plain scalar),
    # matching what sync $storage->update returns -- Row::update_async relies
    # on this to detect "row not found" / "updated more than one row" exactly
    # like sync _update_body does. Extract exactly the one resolved value the
    # transport is contracted to provide for this op (see _query_async POD),
    # the same way the insert branch above extracts $rows[0] rather than
    # handing the caller a raw, unshaped list.
    return $self->_hold_derived($runner->($sql, \@bind, $bind_attrs)->then(sub {
      my ($rows) = @_;
      return $rows;
    }));
  }
  elsif ($op eq 'delete') {
    my ($source, @rest) = @args;
    my $table = (blessed($source) && $source->can('name'))
      ? $source->name
      : $source;

    my ($sql, @bind) = $sm->delete($table, _own_options(delete => @rest));
    @bind = bare_binds(@bind);
    my $bind_attrs = $self->_crud_bind_attrs(delete => $source, \@bind, $table, @rest);

    # Same affected-row-count contract as update_async, above.
    return $self->_hold_derived($runner->($sql, \@bind, $bind_attrs)->then(sub {
      my ($rows) = @_;
      return $rows;
    }));
  }
  croak "Unknown CRUD operation: $op";
}

# The Future a seam hands its caller, derived with ->then from the pool's
# acquire, is held the same way (karr k407): pipeline, the pooled branch of
# deploy_async and a pooled DDL run.
#
# The Future _run_crud hands its caller is derived with ->then from the one
# the transport's query seam returned (karr k331). With Future.pm that is a
# sequence the transport's Future holds only weakly, so a caller that does not
# keep it -- a pooled insert_async in void context, a statement dropped inside
# a pipeline batch -- freed it, and Future.pm warned "lost a sequence Future"
# when the answer came. Same remedy as the transaction context's statements
# (karr k292): hand the Future to itself with retain, which keeps it until it
# is ready -- done, failed or cancelled -- and lets go then. A holder sees no
# difference. Asked through can(): DBIO::Test::Future holds a chain from its
# head and has no retain.
sub _hold_derived {
  my ($self, $future) = @_;
  $future->retain if $future->can('retain');
  return $future;
}

# Shape the row a RETURNING insert yields into the returned-columns hashref
# sync insert() produces (ADR 0031 §3): the supplied insert data overlaid with
# any DB-populated columns. Handles both row shapes a driver's transport may
# yield -- a column=>value hashref (used as-is), or a positional arrayref
# (RETURNING *), zipped against the source's declared column order via
# _returning_columns. A driver whose insert cannot RETURNING (last_insert_id
# only) overrides this to assemble the hashref its own way.
sub _insert_returned_columns {
  my ($self, $source, $to_insert, $row) = @_;

  my %returned = %{ $to_insert || {} };
  return \%returned unless defined $row;

  if (ref $row eq 'HASH') {
    @returned{ keys %$row } = values %$row;
  }
  elsif (ref $row eq 'ARRAY') {
    my @cols = $self->_returning_columns($source);
    @returned{@cols} = @$row if @cols && @cols == @$row;
  }

  return \%returned;
}

# Column names for a positional RETURNING * row, in result order. Default uses
# the result source's declared column order (matches RETURNING * on engines
# that emit columns in declaration order). A driver with a different order, or
# one that emits an explicit RETURNING list, overrides _insert_returned_columns.
sub _returning_columns {
  my ($self, $source) = @_;
  return () unless blessed($source) && $source->can('columns');
  return $source->columns;
}

# _run_crud on the pooled runner: the call the public *_async methods of the
# storage make. The Future it returns waits for a pool connection of its own;
# when that wait is a place in the pool's queue, the pool is told which Future
# waits there (PoolBase::_note_queued_for), so a transaction or pipeline of this
# pool that is handed such a Future by its coderef can tell it cannot settle
# before the transaction ends (_txn_inner_future, karr core k397). Only a pool
# that already exists is asked: a transaction or pipeline holds one by then,
# and so does every storage that has run a statement.
sub _run_crud_pooled {
  my ($self, $op, @args) = @_;

  # An unbound call made while a transaction's coderef runs is not in that
  # transaction. Under debug (DBIO_TRACE) it says so; the text names the
  # operation, never a value or a bind (karr core k400).
  warn "DBIO: ${op}_async on the storage ran while a txn_do_async coderef was"
     . " running; it is not part of the transaction (call it on the context)\n"
    if $self->{_txn_coderef_running} && $self->debug;

  my $pool = $self->{pool};
  return $self->_run_crud($op, $self->_pool_runner, @args)
    unless blessed($pool) && $pool->can('_collect_queued');

  return $self->_note_pooled_derivation(
    sub { $self->_run_crud($op, $self->_pool_runner, @args) }
  );
}

# Runs $code and reports the Future it returns to the pool as waiting wherever
# the calls on the storage inside it queued: a Future that an unbound
# $rs->all_async (or a Row or ResultSetColumn one) derives from the Futures of
# the storage is known to the pool like the storage's own (karr core k397).
sub _note_pooled_derivation {
  my ($self, $code) = @_;

  my $pool = $self->{pool};
  return $code->()
    unless blessed($pool) && $pool->can('_collect_queued');

  my ($future, @waiters) = $pool->_collect_queued($code);
  $pool->_note_queued_for($future, @waiters) if @waiters;
  return $future;
}

# Runner that executes on a freshly-acquired pooled connection and releases
# it when done. This is the normal (non-transactional) path.
sub _pool_runner {
  my $self = shift;
  return sub {
    my ($sql, $bind, $bind_attrs) = @_;
    return $self->_query_async($sql, $bind, $bind_attrs);
  };
}

# Runner that executes on a pinned connection without releasing it. Used by
# TransactionContext so CRUD inside a txn hits the same connection that
# BEGIN/COMMIT ran on.
sub _pinned_runner {
  my ($self, $conn) = @_;
  return sub {
    my ($sql, $bind, $bind_attrs) = @_;
    return $self->_query_async_pinned($conn, $sql, $bind, $bind_attrs);
  };
}


sub _debug_query {
  my ($self, $sql, $bind, $bind_attrs) = @_;

  my $level = $self->_trace_level_of($self->{debug}) or return;

  my $owner    = $self->_owner_storage;
  my $debugobj = $owner && $owner->can('debugobj')
    ? $owner->debugobj
    : $self->debugobj;

  my @trace;
  if ($level >= 2) {
    my $redact = $owner && $owner->can('redact_bind_value')
      ? $owner->redact_bind_value
      : DBIO::Storage::DBI->redact_bind_value;
    my $i = 0;
    @trace = map {
      my $attrs = $bind_attrs && $bind_attrs->[$i++];
      if (defined $_) {
        my $name  = ref $attrs eq 'HASH' ? $attrs->{dbic_colname} : undef;
        my $shown = $redact->($name, $_, $attrs);
        $shown = substr($shown, 0, 32) . '...' if length($shown) > 32;
        qq{'$shown'};
      }
      else {
        q{NULL};
      }
    } @{ $bind || [] };
  }

  # One element at least, or the statistics object prints nothing for a
  # statement without binds (as the sync _query_start does).
  $debugobj->query_start($sql, @trace ? @trace : '');
  return sub { $debugobj->query_end($sql, @trace) };
}

# The arguments of an insert, update or delete after the table name, with a
# flat copy of the options hash: insert ($data, $opts), update ($set, $where,
# $opts), delete ($where, $opts). A driver SQL maker consumes keys of the
# options it receives (on_conflict, insert_or), so each rendering of a
# statement gets a copy of its own and the options of the caller stay as given.
my %OPTIONS_AT = (insert => 1, update => 2, delete => 1);
sub _own_options {
  my ($op, @args) = @_;
  my $at = $OPTIONS_AT{$op};
  $args[$at] = { %{ $args[$at] } } if ref $args[$at] eq 'HASH';
  return @args;
}

# The bind attributes of a statement core built, by the rule of the sync path
# (_gen_sql_bind + _resolve_bindattrs: dbic_colname, sqlt_datatype, redact for
# encode_column). The wire binds stay bare values; the attributes are a second
# list parallel to them and carry no value. Only a trace at level 2 or more
# reads them, so only then is the statement generated a second time, with the
# column names kept in the binds. Anything that does not line up gives undef:
# a trace must never change what a statement does.
sub _crud_bind_attrs {
  my ($self, $op, $ident, $wire, @sm_args) = @_;

  return undef unless $self->_trace_level_of($self->{debug}) >= 2;

  my $owner = _effective_owner_of($self);
  return undef unless $owner && $owner->can('_resolve_bindattrs');

  # A result source gives its columns; the from structure of a select is
  # resolved by _resolve_bindattrs itself, as in _gen_sql_bind.
  my $colinfos = blessed($ident) && $ident->can('columns_info')
    ? $ident->columns_info
    : undef;

  my $sm = $self->sql_maker;
  my $attrs = eval {
    my @pairs = do {
      local $sm->{bindtype} = 'columns';
      my ($sql, @p) = $op eq 'select'
        ? $sm->select(@sm_args)
        : $sm->$op($sm_args[0], _own_options($op, @sm_args[1 .. $#sm_args]));
      unshift @p, @{ $sm_args[3]{bind} || [] } if $op eq q(select);
      @p;
    };
    @pairs == @$wire
      ? [ map { $_->[0] } @{ $owner->_resolve_bindattrs($ident, \@pairs, $colinfos) } ]
      : undef;
  };
  return $attrs;
}

# Build SQL and run a CRUD op on a pinned connection. Entry point used by
# TransactionContext; shares _run_crud's builders / post-processing.
sub _run_crud_pinned {
  my ($self, $op, $conn, @args) = @_;
  return $self->_run_crud($op, $self->_pinned_runner($conn), @args);
}


sub _query_async {
  croak 'Subclass must override _query_async($sql, $bind, $bind_attrs)';
}


sub _seam_future {
  my ($self, $method, @args) = @_;

  my ($f, $err);
  {
    local $@;
    eval { $f = $self->$method(@args); 1 } or $err = $@ || "$method died";
  }
  return $self->future_class->fail($err) if defined $err;
  return $f if blessed($f) && $f->can('then');
  return $self->future_class->fail(
    (ref($self) || $self) . "->$method returned "
  . (defined $f ? 'no Future' : 'undef, not a Future')
  );
}


sub _query_async_pinned {
  croak 'Subclass must override _query_async_pinned($conn, $sql, $bind, $bind_attrs)';
}


sub _await_query_result {
  croak 'Subclass must override _await_query_result($conn, $sql, $bind)';
}


sub _await_conn_ready {
  croak 'Subclass must override _await_conn_ready($conn)';
}


sub _transform_sql {
  croak 'Subclass must override _transform_sql($sql)';
}


sub _post_insert_sql {
  croak 'Subclass must override _post_insert_sql';
}


sub txn_do_async {
  my ($self, $coderef, @args) = @_;

  my $fc = $self->future_class;

  # No transaction through a broker that is not transaction-safe: the rule the
  # sync storage keeps in txn_begin (karr k270). Asked before a connection is
  # taken, and reported the way every other failure of a transaction is.
  my $refusal;
  {
    local $@;
    eval { $self->_assert_transaction_safe_access_broker; 1 } or $refusal = $@;
  }
  return $fc->fail($refusal) if defined $refusal;

  # txn_timeout (karr core k397): the timer is made before the transaction
  # starts, so a storage that cannot time it does not start one it could not
  # end. The timeout ends the transaction through the cancel path, so it needs a
  # Future class that can be cancelled.
  my $timeout = $self->async_option('txn_timeout');
  my $timer;
  if (defined $timeout) {
    my $unable;
    if (!$fc->can('cancel')) {
      $unable = $self->_exception_object(
        "txn_timeout needs a Future class that can be cancelled, and $fc cannot be"
      );
    }
    else {
      $timer = $self->_seam_future(_delay => $timeout);
      $unable = $timer->failure if $timer->is_failed;
    }
    return $fc->fail($unable) if defined $unable;
  }

  # The pool this transaction begins on is the one it ends on: the finalizer
  # hands the connection back to $pool, never to $self->pool asked again
  # (karr dbio-async k46).
  my $pool = $self->pool;
  my $txn_future = $pool->acquire_txn->then(sub {
    my $conn = shift;

    # The one record of what became of $conn: the finalizer, the cancel and the
    # paths that cut a transaction short all go through it (karr k274).
    my $guard = {
      pool => $pool, conn => $conn, done => 0,
      lease => _pool_lease($pool, $conn),
    };

    my ($txn_ctx, $terminal, $thrown);
    {
      local $@;
      my $ok = eval {
        my $txn_ctx_class = $self->_txn_context_class;
        my $accessor = $self->_txn_conn_accessor;
        $txn_ctx = $txn_ctx_class->new(
          storage   => $self,
          $accessor => $conn,
        );
        $txn_ctx->_set_txn_guard($guard) if $txn_ctx->can('_set_txn_guard');
        $terminal = $self->_txn_terminal_chain(
          $txn_ctx,
          $conn,
          $coderef,
          \@args,
        );
        1;
      };
      $thrown = $@ unless $ok;
    }
    $terminal = $fc->fail($thrown) if defined $thrown;

    return $self->_finalize_txn_async($txn_ctx, $conn, $terminal, $pool, $guard);
  });

  # Retain the caller-visible sequence too: it is the downstream Future that
  # encompasses context invalidation and release. Retaining only the terminal
  # upstream chain can still let this finalizer sequence be collected early.
  $txn_future->retain if $txn_future->can('retain');
  return defined $timer ? $self->_txn_timed($txn_future, $timer, $timeout) : $txn_future;
}

# The exception object of a message, for a failed Future.
sub _exception_object {
  my ($self, $message) = @_;
  local $@;
  eval { $self->throw_exception($message); 1 };
  return $@;
}

# The transaction Future of a storage with txn_timeout (karr core k397): the
# Future the caller gets, wrapped around $txn_future. When $timer fires before
# the transaction is over, $txn_future is cancelled -- the cancel path of karr
# k274 runs: ROLLBACK goes out best-effort and is not waited for, the context
# ends, the connection is retired -- and the caller's Future fails with
# "transaction timed out after N seconds". A transaction that ends first
# stops the timer. Cancelling the caller's Future cancels the transaction, as
# without a timeout.
sub _txn_timed {
  my ($self, $txn_future, $timer, $timeout) = @_;

  my $outer = $txn_future->new;
  my $timed_out;

  $txn_future->on_ready(sub {
    my $f = shift;
    $timer->cancel if !$timer->is_ready && $timer->can('cancel');
    return if $outer->is_ready;
    return $outer->cancel if $f->is_cancelled && !$timed_out;
    return if $f->is_cancelled;
    return $outer->fail($f->failure) if $f->is_failed;
    return $outer->done($f->get);
  });
  $outer->on_cancel(sub { $txn_future->cancel unless $txn_future->is_ready });

  my $chain = $timer->then(sub {
    return if $txn_future->is_ready || $outer->is_ready;
    $timed_out = 1;
    $txn_future->cancel;
    $outer->fail($self->_exception_object("transaction timed out after $timeout seconds"));
    return;
  });
  $chain->retain if $chain->can('retain');
  $outer->retain if $outer->can('retain');
  return $outer;
}

# Build the BEGIN/callback/COMMIT-or-ROLLBACK sequence without releasing the
# pinned connection. The outer finalizer owns that one terminal action.
sub _txn_terminal_chain {
  my ($self, $txn_ctx, $conn, $coderef, $args) = @_;

  my $fc = $self->future_class;
  my $chain = $self->_query_async_pinned($conn, 'BEGIN', [])->then(
    sub {
      my ($inner, $callback_error);
      {
        local $@;
        my $ok = eval {
          local $self->{_txn_coderef_running} = ( $self->{_txn_coderef_running} || 0 ) + 1;
          $inner = $coderef->($txn_ctx, @$args);
          1;
        };
        $callback_error = $@ unless $ok;
      }

      if (defined $callback_error) {
        # A connection left unusable gets its ROLLBACK best-effort from
        # _finalize_txn_async, not waited for here (karr k232).
        return $fc->fail($callback_error)
          if $self->_txn_conn_unusable($txn_ctx);
        return $self->_txn_rollback_and_fail($txn_ctx, $conn, $callback_error);
      }

      # blessed, not ref: an unblessed return (the hashref $ctx->insert
      # resolves, say) dies in ->can, and a die here sent neither COMMIT nor
      # ROLLBACK -- the connection went back to the pool mid-transaction
      # (karr k228).
      my $inner_future = blessed($inner) && $inner->can('then')
        ? $inner
        : $fc->done($inner);

      # The driver's chance to refuse the inner Future before it is chained
      # on (_txn_inner_future). A throw is a coderef die; a return that is
      # no Future leaves the coderef's own (karr k334).
      my ($seam_future, $seam_error);
      {
        local $@;
        my $ok = eval {
          $seam_future = $self->_txn_inner_future($txn_ctx, $conn, $inner_future);
          1;
        };
        $seam_error = $@ unless $ok;
      }
      if (defined $seam_error) {
        return $fc->fail($seam_error)
          if $self->_txn_conn_unusable($txn_ctx);
        return $self->_txn_rollback_and_fail($txn_ctx, $conn, $seam_error);
      }
      $inner_future = $seam_future
        if blessed($seam_future) && $seam_future->can('then');

      my $chained = $inner_future->then(
        sub {
          my @result = @_;
          return $self->_txn_commit_refusal($txn_ctx)
            if $self->_txn_conn_unusable($txn_ctx);
          # COMMIT only once every statement the context handed out has an
          # answer, and only if none of them failed (karr k236).
          return $self->_txn_statements_settled($txn_ctx)->then(sub {
            return $self->_txn_commit_if_clean($txn_ctx, $conn, $_[0], @result);
          });
        },
        sub {
          my $error = shift;
          return $fc->fail($error) if $self->_txn_conn_unusable($txn_ctx);
          return $self->_txn_rollback_and_fail($txn_ctx, $conn, $error);
        },
      );
      return $self->_txn_chain_cancelled_with($inner_future, $chained, $txn_ctx, $conn);
    },
    sub { return $fc->fail(_txn_prefixed_error(BEGIN => $_[0])) },
  );

  # Real Future holds a downstream sequence Future only weakly. Keep the
  # terminal chain alive until it settles; immediate Future shims need no such
  # support and may not implement retain.
  $chain->retain if $chain->can('retain');
  return $chain;
}

# The Future of the transaction's coderef, cancelled by itself (karr
# dbio-postgresql-ev k70): Future.pm runs no ->then callback of a cancelled
# Future, so $chained would stay pending for good, with no COMMIT, no ROLLBACK
# and no hand-back. It ends as a cancel of the whole transaction does
# (_txn_retire_on_cancel): ROLLBACK best-effort, connection retired. The
# transaction fails; whether the work took effect is unknown. Returned is the
# Future the chain continues with -- $chained itself when $inner_future cannot
# be cancelled.
sub _txn_chain_cancelled_with {
  my ($self, $inner_future, $chained, $txn_ctx, $conn) = @_;

  return $chained
    unless $inner_future->can('on_cancel') && !$inner_future->is_ready;

  my $fc    = $self->future_class;
  my $guard = $self->_txn_guard($txn_ctx);
  my $gate  = $fc->new;
  $gate->on_cancel($chained);
  $chained->on_ready(sub {
    my $c = shift;
    return if $gate->is_ready;
    return $gate->cancel if $c->is_cancelled;
    return $c->is_failed ? $gate->fail($c->failure) : $gate->done($c->get);
  });
  $inner_future->on_cancel(sub {
    return if $gate->is_ready;
    $self->_txn_retire_on_cancel($txn_ctx, $conn, $guard) if $guard;
    $gate->fail($self->_txn_cancelled_error(
      q{the Future of the transaction's coderef was cancelled}
    ));
    $chained->cancel unless $chained->is_ready;
  });
  return $gate;
}

# The error a transaction fails with when something cancelled it from inside.
sub _txn_cancelled_error {
  my ($self, $what) = @_;
  my $err;
  eval {
    $self->throw_exception(
      "Transaction cancelled: $what. The connection is retired; whether the "
    . 'transaction took effect is unknown.'
    );
    1;
  } or $err = $@;
  return $err;
}

# The failure of a BEGIN or COMMIT with the step's name in front: the text
# "$step failed: $error". A DBIO::Exception::Server stays an object -- a derived
# copy, same class and fields, context set, stringifying with the prefix -- so
# the SQLSTATE of a serialization failure at COMMIT is not lost to the text
# (ADR 0062, decision 2026-10-12). Anything that is no such object stays the
# string it was.
sub _txn_prefixed_error {
  my ($step, $error) = @_;
  my $text = "$step failed: $error";
  return $text
    unless blessed($error) && $error->isa('DBIO::Exception::Server');
  return $error->with_context($step, $text);
}

# Resolves once every statement Future $txn_ctx handed out has settled --
# including any handed out while this waited -- with [ $error ] for the first
# of them, in the order they were handed out, that failed; with nothing when
# none did. One needs_all per round over Futures that cannot fail, so a long
# run of statements that already settled costs no recursion (karr k236). A
# context class of a backend's own is asked through can().
sub _txn_statements_settled {
  my ($self, $txn_ctx, $from, $first_failure) = @_;
  $from //= 0;

  my $fc = $self->future_class;
  my @statements = ($txn_ctx && $txn_ctx->can('_txn_statements'))
    ? $txn_ctx->_txn_statements
    : ();
  if ($from >= @statements) {
    return $first_failure ? $fc->done($first_failure) : $fc->done;
  }

  my @failures;
  my @settled = map {
    _txn_statement_settled($fc, $statements[$_], \@failures, $_)
  } $from .. $#statements;

  my $seen = scalar @statements;
  return $fc->needs_all(@settled)->then(sub {
    if (!$first_failure and my ($first) = grep { defined } @failures) {
      $first_failure = ref $first eq 'HASH'
        ? [ $self->_txn_cancelled_statement_error ]
        : $first;
    }
    return $self->_txn_statements_settled($txn_ctx, $seen, $first_failure);
  });
}

# A Future that is done once the tracked statement $f has settled, whichever
# way, and never fails. A failure is noted at $index as [ $error ]. A Future
# that is cancelled -- Future.pm's wait_any cancels the statement that lost a
# race against a timeout -- runs no catch callback and would be waited on
# forever; it is noted as { cancelled => 1 }. Nobody will see its result, so
# the transaction cannot vouch for it. Cancelling is probed through can(): the
# DBIO::Future contract has no cancel, and a class without one cannot be
# cancelled.
sub _txn_statement_settled {
  my ($fc, $f, $failures, $index) = @_;
  if ($f->can('is_cancelled') && $f->is_cancelled) {
    $failures->[$index] = { cancelled => 1 };
    return $fc->done;
  }
  my $settled = $f->catch(_txn_failure_recorder($fc, $failures, $index));
  $f->on_cancel(_txn_cancel_recorder($settled, $failures, $index))
    if $f->can('on_cancel') && !$f->is_ready;
  return $settled;
}

# The catch callback for one tracked statement: note its error at its
# position. Named subs, so each callback closes over what it names only.
sub _txn_failure_recorder {
  my ($fc, $failures, $index) = @_;
  return sub {
    $failures->[$index] = [ $_[0] ];
    return $fc->done;
  };
}

# The on_cancel callback for one tracked statement. $settled is held weakly:
# it holds $f in turn (a derived Future keeps its source for cancellation), and
# a strong reference back would make a cycle of every statement.
sub _txn_cancel_recorder {
  my ($settled, $failures, $index) = @_;
  weaken($settled);
  return sub {
    $failures->[$index] //= { cancelled => 1 };
    $settled->done if $settled && !$settled->is_ready;
  };
}

# The error a transaction fails with when one of its statements was cancelled
# before it was answered.
sub _txn_cancelled_statement_error {
  my ($self) = @_;
  my $err;
  eval {
    $self->throw_exception(
      'COMMIT not sent: a statement of the transaction was cancelled before it '
    . 'was answered, so whether it took effect is unknown. The transaction is '
    . 'rolled back.'
    );
    1;
  } or $err = $@;
  return $err;
}

# The end of a transaction whose coderef succeeded, once its statements have
# settled. COMMIT -- unless a pipeline left the connection unusable meanwhile,
# then nothing is sent on it and the refusal is the same as when that was known
# before the wait (karr k232), or one of the statements failed, then ROLLBACK
# and that statement's error (karr k236). A COMMIT the transport reports as
# rolled back fails the transaction as well; nothing follows it, the server
# has ended the transaction. The context ends as COMMIT goes out: a statement
# issued on it after that would run after the transaction (karr k237).
sub _txn_commit_if_clean {
  my ($self, $txn_ctx, $conn, $failed, @result) = @_;

  my $fc = $self->future_class;
  return $self->_txn_commit_refusal($txn_ctx)
    if $self->_txn_conn_unusable($txn_ctx);
  if ($failed) {
    return $self->_txn_rollback_and_fail($txn_ctx, $conn, $failed->[0]);
  }
  _txn_context_ends($txn_ctx);
  return $self->_query_async_pinned($conn, 'COMMIT', [])->then(
    sub {
      return $self->_txn_rolled_back_by_server
        if $self->_txn_commit_rolled_back($conn, @_);
      return $fc->done(@result);
    },
    sub { return $self->_txn_abandon_after_failed_commit($txn_ctx, $conn, $_[0]) },
  );
}

# A COMMIT the server refused ends the transaction whatever the server says (a
# deferred constraint is checked at commit time, and a server may keep the
# transaction open): ROLLBACK goes out on the pinned connection, waited for.
# If it works the connection goes back to the pool as usual; if it fails or its
# dispatch throws, the connection is retired, never handed back (the same
# pool retirement a cancelled transaction uses). The transaction fails with the
# error of the COMMIT -- the DBIO::Exception::Server object itself, never that
# of the ROLLBACK (karr k372).
sub _txn_abandon_after_failed_commit {
  my ($self, $txn_ctx, $conn, $commit_error) = @_;

  my $fc    = $self->future_class;
  my $error = _txn_prefixed_error(COMMIT => $commit_error);

  # Only a COMMIT the server refused is a failed COMMIT (ADR 0062). One the
  # transport refused or that was cancelled never got an answer from the
  # server: it stays what it was, the transaction fails with its error and the
  # connection's fate is the finalizer's.
  return $fc->fail($error)
    unless blessed($commit_error) && $commit_error->isa('DBIO::Exception::Server');

  # Gone already (reported dead, handed back by a cancel): nothing to roll
  # back, nothing left to retire.
  return $fc->fail($error) if $self->_txn_conn_gone($txn_ctx, $conn);

  my $retire = sub {
    $self->_txn_retire_conn($txn_ctx, $conn);
    return $fc->fail($error);
  };

  my $sent = $self->_seam_future(_query_async_pinned => $conn, 'ROLLBACK', []);
  return $sent->then(
    sub { return $fc->fail($error) },
    $retire,
  );
}

# Takes the transaction's connection out of circulation: the pool retires it
# when it goes back (guard), else the context marks it unusable for the
# finalizer. Used where a ROLLBACK was not confirmed.
sub _txn_retire_conn {
  my ($self, $txn_ctx, $conn) = @_;
  if (my $guard = $self->_txn_guard($txn_ctx)) {
    unless ($guard->{done}++) {
      local $@;
      eval { $guard->{pool}->_retire_in_use_connection($conn) };
    }
  }
  elsif ($txn_ctx && $txn_ctx->can('_mark_txn_conn_unusable')) {
    $txn_ctx->_mark_txn_conn_unusable;
  }
  return;
}

# The end of a transaction that failed with $error -- its coderef died or its
# Future failed, or one of its statements failed: ROLLBACK, then fail with
# $error. The context ends as ROLLBACK goes out (karr k237). A ROLLBACK that
# fails, or whose dispatch throws, does not replace $error: the transaction
# fails as the synchronous txn_do does when its rollback fails
# (DBIO::Storage::BlockRunner), with both errors, the original first.
sub _txn_rollback_and_fail {
  my ($self, $txn_ctx, $conn, $error) = @_;

  my $fc = $self->future_class;
  _txn_context_ends($txn_ctx);

  my $rollback = sub {
    # No ROLLBACK onto a connection that is gone: it would only be answered
    # with "not sent", and that is no error of the transaction (karr
    # dbio-async k47). The finalizer's release retires it, the pool having
    # been told it is dead. Nor one the cancel has retired already (karr
    # k274), nor one a pipeline could not take out of pipeline mode (karr
    # k232): the finalizer sends that one a ROLLBACK best-effort and retires it.
    return $fc->fail($error) if $self->_txn_conn_gone($txn_ctx, $conn)
      || $self->_txn_conn_unusable($txn_ctx);

    my $sent = $self->_seam_future(_query_async_pinned => $conn, 'ROLLBACK', []);
    return $sent->then(
      sub { return $fc->fail($error) },
      sub {
        # A ROLLBACK nobody confirmed leaves the transaction's state unknown:
        # the connection is retired, never handed back.
        $self->_txn_retire_conn($txn_ctx, $conn);
        return $fc->fail($self->_txn_rollback_failed_error($error, $_[0]));
      },
    );
  };

  # A pipeline run on the transaction whose sync is not answered yet has the
  # connection in pipeline mode: a ROLLBACK sent now goes out there, and the
  # connection would be handed back to the pool in that mode as soon as the
  # ROLLBACK is answered (karr k331). The ROLLBACK waits until each such
  # pipeline is over -- sync answered and pipeline mode left, or the pipeline
  # failed or was cancelled, which leaves the connection to the checks above.
  my @pipelines = $txn_ctx && $txn_ctx->can('_txn_pending_pipelines')
    ? $txn_ctx->_txn_pending_pipelines
    : ();
  return $rollback->() unless @pipelines;

  my @failures;
  return $fc->needs_all(
    map { _txn_statement_settled($fc, $pipelines[$_], \@failures, $_) }
      0 .. $#pipelines
  )->then($rollback);
}

# The error a transaction fails with when its ROLLBACK failed: the text the
# synchronous txn_do uses (DBIO::Storage::BlockRunner), so the same match --
# /Rollback failed/ -- works in every mode, immediate included (ADR 0055
# addendum 2026-09-27, karr k237).
sub _txn_rollback_failed_error {
  my ($self, $error, $rollback_error) = @_;
  my $err;
  eval {
    $self->throw_exception(
      "Transaction aborted: $error. Rollback failed: $rollback_error"
    );
    1;
  } or $err = $@;
  # A server's refusal of the ROLLBACK stays the object (ADR 0062, decision
  # 2026-10-12): a derived copy with the text just thrown and context ROLLBACK.
  return $rollback_error->with_context(ROLLBACK => "$err")
    if blessed($rollback_error) && $rollback_error->isa('DBIO::Exception::Server');
  return $err;
}

# COMMIT or ROLLBACK is going out on the transaction's connection: from here
# on its context refuses every statement (_assert_context_active), which
# would otherwise run after the transaction, outside it (karr k237). The
# finalizer invalidates again before the release; that is a no-op then. A
# context class of a backend's own is asked through can().
sub _txn_context_ends {
  my ($txn_ctx) = @_;
  $txn_ctx->_invalidate if $txn_ctx && $txn_ctx->can('_invalidate');
  return;
}

# Every path after a successful acquire converges here. Invalidate any context
# that was constructed before returning the connection to the pool, then
# preserve the terminal result/error. A release throw replaces success, but
# never an existing error. $pool is the pool $conn was acquired from. $guard
# is the transaction's record of its connection's hand-back (karr k274).
#
# The Future returned is the one a caller cancels: Future.pm runs none of the
# callbacks below for it, so the cancel is answered here
# (_txn_retire_on_cancel).
sub _finalize_txn_async {
  my ($self, $txn_ctx, $conn, $terminal, $pool, $guard) = @_;
  $guard ||= {
    pool => $pool, conn => $conn, done => 0,
    lease => _pool_lease($pool, $conn),
  };

  my $fc = $self->future_class;
  my $final = $terminal->then(
    sub {
      my @result = @_;
      $txn_ctx->_invalidate
        if $txn_ctx && $txn_ctx->can('_invalidate');

      my ($released, $release_error);
      {
        local $@;
        $released = eval {
          $self->_txn_hand_back($txn_ctx, $conn, $pool, $guard);
          1;
        };
        $release_error = $@ unless $released;
      }

      return $released
        ? $fc->done(@result)
        : $fc->fail($release_error);
    },
    sub {
      my $error = shift;
      $txn_ctx->_invalidate
        if $txn_ctx && $txn_ctx->can('_invalidate');
      {
        local $@;
        eval { $self->_txn_hand_back($txn_ctx, $conn, $pool, $guard) };
      }
      return $fc->fail($error);
    },
  );
  $final->on_cancel(sub { $self->_txn_retire_on_cancel($txn_ctx, $conn, $guard) })
    if $final->can('on_cancel') && !$final->is_ready;
  return $final;
}

# The transaction's one hand-back of its connection. Normally a release. A
# connection the transaction context reports unusable -- a pipeline on it could
# not leave pipeline mode (karr k232) -- would break the next borrower, so it is
# retired instead, through the pool's in-use retirement so that a caller queued
# for its slot gets a fresh connection. The ROLLBACK the terminal chain held
# back goes out first, best-effort: it is not waited for, since a connection in
# that state may never answer it, and its outcome changes nothing -- closing the
# session ends the transaction on the server either way. It matters where the
# transport's _shutdown_connection closes nothing.
#
# Both go to $pool, the pool the transaction acquired $conn from -- not to
# $self->pool, which builds a pool where the storage has none: a transaction
# that ends after its storage was disconnected would put a new pool on it
# (karr dbio-async k46). The pool it began on is shut down by then, and takes
# a release or a retirement as a no-op.
#
# Once: a connection the cancel has retired already (_txn_retire_on_cancel) is
# not handed back again (karr k274).
sub _txn_hand_back {
  my ($self, $txn_ctx, $conn, $pool, $guard) = @_;
  return if $guard && $guard->{done}++;

  unless ($self->_txn_conn_unusable($txn_ctx)) {
    $pool->release($conn, $guard ? $guard->{lease} : ());
    return;
  }

  $self->_txn_send_rollback_unwaited($conn, $pool);
  $pool->_retire_in_use_connection($conn);
  return;
}

# The end of a transaction whose Future was cancelled (karr k274). Future.pm
# runs no ->then callback of a cancelled Future, so nothing else would end it:
# the connection stayed checked out, the transaction open on the server, and a
# pool of one waited for good. What is left of the transaction's connection
# cannot be vouched for -- a statement in flight on it may or may not take
# effect, a COMMIT in flight may or may not have committed -- so it is not
# returned to the pool. ROLLBACK goes out best-effort, not waited for (nothing
# may ever answer it), the context is invalidated, and the connection is
# retired, its slot going to a fresh connection. Once per transaction, however
# many paths notice the cancel and whether or not the finalizer ran.
sub _txn_retire_on_cancel {
  my ($self, $txn_ctx, $conn, $guard) = @_;
  return if $guard->{done}++;

  # A ROLLBACK or COMMIT already out has ended the context; there is nothing
  # left to end.
  my $open = !$txn_ctx || !$txn_ctx->can('in_txn') || $txn_ctx->in_txn;
  _txn_context_ends($txn_ctx);
  $self->_txn_send_rollback_unwaited($conn, $guard->{pool}) if $open;

  local $@;
  eval { $guard->{pool}->_retire_in_use_connection($conn) };
  return;
}

# ROLLBACK, best-effort and not waited for. Not onto a connection the pool has
# been told is dead (karr dbio-async k47).
sub _txn_send_rollback_unwaited {
  my ($self, $conn, $pool) = @_;
  return if $pool && $pool->can('_connection_is_dead') && $pool->_connection_is_dead($conn);
  local $@;
  eval {
    my $f = $self->_query_async_pinned($conn, 'ROLLBACK', []);
    $f->on_fail(sub {}) if blessed($f) && $f->can('on_fail');
  };
  return;
}

# Is the transaction's connection past a ROLLBACK: reported dead to its pool,
# or already handed back by the cancel?
sub _txn_conn_gone {
  my ($self, $txn_ctx, $conn) = @_;
  my $guard = $self->_txn_guard($txn_ctx) or return 0;
  return 1 if $guard->{done};
  my $pool = $guard->{pool};
  return ($pool && $pool->can('_connection_is_dead') && $pool->_connection_is_dead($conn)) ? 1 : 0;
}

sub _txn_guard {
  my ($self, $txn_ctx) = @_;
  return unless $txn_ctx && $txn_ctx->can('_txn_guard');
  return $txn_ctx->_txn_guard;
}

# Did something run on the transaction's connection leave it unusable? Asked
# through can(): a backend may bring a context class of its own.
sub _txn_conn_unusable {
  my ($self, $txn_ctx) = @_;
  return 0 unless $txn_ctx && $txn_ctx->can('_txn_conn_unusable');
  return $txn_ctx->_txn_conn_unusable ? 1 : 0;
}

# The failed Future a transaction ends with when its coderef succeeded but its
# connection was left unusable: COMMIT cannot be sent on it.
sub _txn_commit_refusal {
  my ($self, $txn_ctx) = @_;
  # A pipeline that failed passed the error that ended its batch (karr k396):
  # the transaction fails with that one.
  if ($txn_ctx && $txn_ctx->can('_txn_conn_unusable_error')
      && defined(my $batch_error = $txn_ctx->_txn_conn_unusable_error)) {
    return $self->future_class->fail($batch_error);
  }
  my $err;
  eval {
    $self->throw_exception(
      'COMMIT not sent: a pipeline on the transaction connection could not '
    . 'leave pipeline mode (its _pipeline_exit died), so no statement on it '
    . 'can be relied on. The transaction is rolled back and the connection '
    . 'retired.'
    );
    1;
  } or $err = $@;
  return $self->future_class->fail($err);
}


sub _txn_commit_rolled_back { 0 }

# The failed Future a transaction ends with when its COMMIT was answered as a
# rollback (_txn_commit_rolled_back).
sub _txn_rolled_back_by_server {
  my ($self) = @_;
  my $err;
  eval {
    $self->throw_exception(
      'COMMIT was answered with ROLLBACK: the server had already aborted the '
    . 'transaction and committed nothing. A statement in it failed without the '
    . 'transaction seeing the failure -- one sent on its connection past the '
    . 'transaction context, or a pipeline statement whose batch dropped its '
    . 'error.'
    );
    1;
  } or $err = $@;
  return $self->future_class->fail($err);
}


sub _txn_inner_future {
  my ($self, $txn_ctx, $conn, $inner) = @_;
  $self->_refuse_own_pool_waiters($inner, 'transaction');
  return $inner;
}

# The inner Future of a transaction or pipeline waits in the queue of the pool
# the transaction or pipeline holds a connection of: it is withdrawn from the
# queue, failed, and the bracket fails with the throw (karr core k397).
sub _refuse_own_pool_waiters {
  my ($self, $inner, $what) = @_;

  my $pool = $self->{pool};
  return unless blessed($pool) && $pool->can('_refuse_queued_for');

  my $message = "the coderef returned a Future queued for this $what\'s own pool; "
              . 'call it on the context';
  $self->throw_exception($message)
    if $pool->_refuse_queued_for($inner, $message);
  return;
}


sub _txn_context_class { 'DBIO::Storage::Async::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }


sub pipeline {
  my ($self, $coderef) = @_;

  if (my $refusal = $self->_pipeline_refusal) {
    return $refusal;
  }

  # No batch through a broker that is not transaction-safe, as txn_do_async
  # (karr k273): asked before a connection is taken from the pool.
  my $broker_refusal;
  {
    local $@;
    eval { $self->_assert_transaction_safe_access_broker; 1 } or $broker_refusal = $@;
  }
  return $self->future_class->fail($broker_refusal) if defined $broker_refusal;

  # Released to, or retired from, the pool it was acquired from -- not
  # $self->pool asked again when the batch ends (karr dbio-async k46).
  my $pool = $self->pool;
  return $self->_hold_derived($pool->acquire->then(sub {
    my $conn = shift;
    my $lease = _pool_lease($pool, $conn);
    return $self->_pipeline_on_conn(
      $conn, $coderef,
      sub { $pool->release($conn, $lease) },
      sub { $pool->_retire_in_use_connection($conn) },
    );
  }));
}


sub _pipeline_refusal {
  my ($self) = @_;

  my $base_enter = DBIO::Storage::Async->can('_pipeline_enter');
  my $own_enter  = $self->can('_pipeline_enter');
  return undef if $own_enter && $own_enter != $base_enter;

  my $class = ref $self || $self;
  my $err;
  eval {
    $self->throw_exception(
      "$class does not support pipeline() (no _pipeline_enter): this async "
    . "transport cannot batch statements. Issue the statements individually, "
    . "or use an async mode whose transport supports pipelining. (Transport "
    . "authors: override _pipeline_enter/_pipeline_sync/_pipeline_exit to "
    . "support it.)"
    );
    1;
  } or $err = $@;
  return $self->future_class->fail($err);
}


sub _pipeline_on_conn {
  my ($self, $conn, $coderef, $release, $retire) = @_;

  my $fc = $self->future_class;
  $release ||= sub { 1 };
  $retire  ||= $release;

  # Build the context BEFORE entering pipeline mode: a throw from the
  # constructor then cannot strand a connection that is already bracketed.
  # It must still hand the connection back (karr k231).
  my $batch;
  my $built = eval {
    $batch = $self->_pipeline_context_class->new(
      storage       => $self,
      pipeline_conn => $conn,
    );
    1;
  };
  if (!$built) {
    my $ctx_err = $@;
    $release->();
    return $fc->fail($ctx_err);
  }

  my $entered = eval { $self->_pipeline_enter($conn); 1 };
  if (!$entered) {
    my $enter_err = $@;
    # Pipeline mode was never entered (the base seam croaks when a backend
    # declines pipelining) -- release the connection but do NOT call
    # _pipeline_exit, there is nothing to exit.
    $release->();
    return $fc->fail($enter_err);
  }

  my $result = eval { $coderef->($batch) };
  my $err = $@;

  # The driver's chance to refuse the Future the coderef returned
  # (_pipeline_inner_future); a throw is a coderef die (karr core k397).
  if (!$err && blessed($result) && $result->can('then')) {
    my $seam;
    local $@;
    if (eval { $seam = $self->_pipeline_inner_future($batch, $conn, $result); 1 }) {
      $result = $seam if blessed($seam) && $seam->can('then');
    }
    else {
      $err = $@;
    }
  }

  # The pipeline context is valid ONLY for the synchronous run of the batch
  # coderef (dbio-async ADR 0003): statements are batched onto the bracketed
  # connection during that run and synced immediately below. Invalidate the
  # context now so a context-bound ResultSet/Row held past this point fails
  # loudly rather than silently re-issuing on a pooled connection outside the
  # bracket.
  $batch->_invalidate if $batch->can('_invalidate');

  # The connection goes back once every statement of the batch and the Future
  # the coderef returned are decided (karr k396): sync, statement results,
  # returned Future, then the hand-back. A late error therefore never reaches a
  # connection another caller has meanwhile been lent.
  #
  # The bracket is decided exactly once. A failure -- the coderef died, the
  # sync or the returned Future failed, the exit died, the batch Future was
  # cancelled -- retires the connection, never releases it: unsynced or
  # half-read statements leave it in a state nobody may inherit. Inside a
  # transaction $retire only marks the connection unusable and the boundary
  # decides. Every statement Future still open fails with that error; no sync
  # is sent on the failure path, and a transport callback arriving later finds
  # the Future decided and does nothing. Pipeline mode is left best-effort.
  my $handed_back = 0;
  my $exited      = 0;
  my $leave = sub {
    return undef if $exited++;
    my $left = eval { $self->_pipeline_exit($conn); 1 };
    return $left ? undef : $@;
  };
  my $fail = sub {
    my ($error, $exit_died) = @_;
    unless ($handed_back++) {
      $leave->();
      # The error goes to $retire for a transaction to fail with; a connection
      # that could not leave pipeline mode is the transaction's generic case.
      { local $@; eval { $retire->($exit_died ? () : $error) }; }
      $batch->_fail_open_statements($error) if $batch->can('_fail_open_statements');
    }
    return $fc->fail($error);
  };

  return $fail->($err) if $err;

  # A sync that dies before it has a Future -- or returns none -- becomes a
  # failed one and takes the failure branch below, like k229's DDL dispatch
  # (_seam_future, karr k252). The hand-back stays behind the sync Future's
  # completion -- the obligation documented at _pipeline_sync.
  my $synced = $self->_seam_future(_pipeline_sync => $conn);

  my $batch_future = $synced->then(sub {
    # The sync is answered: statement results have been read off the
    # connection. Leave pipeline mode, then wait for the rest.
    if (defined(my $exit_err = $leave->())) {
      return $fail->($exit_err, 1);
    }

    my @settled = map {
      $_->then(sub { return $fc->done }, sub { return $fc->done })
    } grep { !$_->is_ready } ($batch->can('_statements') ? $batch->_statements : ());
    my $thenable = blessed($result) && $result->can('then');
    push @settled, $result->then(sub { return $fc->done }, sub { return $fc->done })
      if $thenable;

    return $fc->needs_all(@settled)->then(sub {
      if ($thenable) {
        return $result->then(sub {
          my @value = @_;
          unless ($handed_back++) { $release->() }
          return $fc->done(@value);
        }, sub {
          return $fail->($_[0]);
        });
      }
      unless ($handed_back++) { $release->() }
      return $fc->done($result);
    });
  }, sub {
    return $fail->($_[0]);
  });

  # Cancelled while the bracket is open (karr k274): Future.pm runs neither
  # branch above, so the connection would stay in pipeline mode and checked
  # out. Whether the batch took effect is unknown and the sync may still be
  # answered on it, so it is retired, never released -- once, and not at all
  # when the bracket finished before the cancel. The statements still open fail
  # with a message of their own: there is no error that ended the batch.
  $batch_future->on_cancel(sub {
    return if $handed_back;
    $handed_back = 1;
    local $@;
    eval { $retire->() };
    eval { $batch->_fail_open_statements('pipeline cancelled') };
  }) if $batch_future->can('on_cancel') && !$batch_future->is_ready;
  return $batch_future;
}


sub _pipeline_context_class { 'DBIO::Storage::Async::PipelineContext' }


sub _pipeline_inner_future {
  my ($self, $batch, $conn, $inner) = @_;
  $self->_refuse_own_pool_waiters($inner, 'pipeline');
  return $inner;
}


sub _pipeline_enter {
  croak 'Subclass must override _pipeline_enter($conn)';
}


sub _pipeline_sync {
  croak 'Subclass must override _pipeline_sync($conn)';
}


sub _pipeline_exit {
  croak 'Subclass must override _pipeline_exit($conn)';
}


__PACKAGE__->mk_group_accessors(simple    => qw(on_listen_error on_listen_reconnect));
__PACKAGE__->mk_group_accessors(inherited => qw(listen_backoff_initial listen_backoff_max));

__PACKAGE__->listen_backoff_initial(1);
__PACKAGE__->listen_backoff_max(30);


sub listen {
  my ($self, $channel, $cb) = @_;
  my $refusal = $self->_listen_refusal('listen', $channel);
  $self->throw_exception($refusal) if defined $refusal;
  $self->throw_exception('listen() requires a callback coderef')
    unless ref $cb eq 'CODE';

  my $L     = $self->_listen_state(1);
  my $fc    = $self->future_class;
  my $known = exists $L->{channels}{$channel};
  $L->{channels}{$channel} = $cb;

  return $fc->done
    if $known && $L->{subscribed}{$channel} && $L->{phase} eq 'up';

  my $f = $fc->new;
  push @{ $L->{waiting}{$channel} }, $f;

  if ($L->{phase} eq 'idle') {
    $self->_listen_connect($L, 0);
  }
  elsif (defined $L->{conn} && !$known) {
    $self->_listen_enqueue($L, $L->{gen}, '_listen_op_subscribe', $L->{conn}, $channel);
  }
  # Otherwise a connection is being opened or awaited: the next one subscribes
  # every registered channel, this one included. A known channel that is not
  # subscribed yet already has its subscribe queued.

  return $self->_listen_handout($L, $f);
}


sub unlisten {
  my ($self, $channel) = @_;
  my $refusal = $self->_listen_refusal('listen', $channel);
  $self->throw_exception($refusal) if defined $refusal;

  my $fc = $self->future_class;
  my $L  = $self->_listen_state or return $fc->done;
  return $fc->done unless exists $L->{channels}{$channel};

  delete $L->{channels}{$channel};
  delete $L->{subscribed}{$channel};
  $self->_listen_settle($L, $channel, 0,
    "unlisten('$channel') was called before its subscription took effect");

  unless (%{ $L->{channels} }) {
    $self->_listen_teardown($L, 'the last channel was unlistened');
    return $fc->done;
  }

  return $fc->done unless defined $L->{conn};
  return $self->_listen_handout($L,
    $self->_listen_enqueue($L, $L->{gen}, '_listen_op_unsubscribe', $L->{conn}, $channel));
}


sub notify {
  my ($self, $channel, $payload) = @_;
  my $refusal = $self->_listen_refusal('notify', $channel);
  $self->throw_exception($refusal) if defined $refusal;
  return $self->_listen_seam_future('_notify_send', $channel, $payload);
}


sub listen_alive {
  my ($self) = @_;
  my $refusal = $self->_listen_refusal('listen');
  $self->throw_exception($refusal) if defined $refusal;

  my $L = $self->_listen_state or return 0;
  return 0 unless $L->{phase} eq 'up' && defined $L->{conn};

  my $dead = $self->_listen_probe_error($L->{conn});
  return 1 unless defined $dead;

  $self->_listen_failed($L, $L->{gen}, $dead);
  return 0;
}


sub listen_reconnect {
  my ($self) = @_;
  my $refusal = $self->_listen_refusal('listen');
  $self->throw_exception($refusal) if defined $refusal;

  my $fc = $self->future_class;
  my $L  = $self->_listen_state or return $fc->done;
  return $fc->done unless %{ $L->{channels} };

  my $f = $fc->new;
  push @{ $L->{ready} }, $f;

  $self->_listen_cancel_timer($L);
  $self->_listen_drop_conn($L);
  $L->{attempt} = 0;
  $self->_listen_connect($L, 1);

  return $self->_listen_handout($L, $f);
}


sub _listen_open {
  croak 'Subclass must override _listen_open';
}


sub _listen_close {
  croak 'Subclass must override _listen_close($conn)';
}


sub _listen_subscribe {
  croak 'Subclass must override _listen_subscribe($conn, $channel)';
}


sub _listen_unsubscribe {
  croak 'Subclass must override _listen_unsubscribe($conn, $channel)';
}


sub _listen_watch {
  croak 'Subclass must override _listen_watch($conn)';
}


sub _listen_unwatch {
  croak 'Subclass must override _listen_unwatch($conn)';
}


sub _listen_probe {
  croak 'Subclass must override _listen_probe($conn)';
}


sub _listen_delay {
  croak 'Subclass must override _listen_delay($seconds)';
}


sub _notify_send {
  croak 'Subclass must override _notify_send($channel, $payload)';
}


sub _listen_dispatch {
  my ($self, $channel, $payload, $sender_pid) = @_;
  my $L = $self->_listen_state or return;
  my $cb = $L->{channels}{$channel} or return;

  local $@;
  eval { $cb->($channel, $payload, $sender_pid); 1 }
    or $self->_listen_report("listen callback for channel '$channel' died: $@");
  return;
}


sub _listen_lost {
  my ($self, $conn, $error) = @_;
  my $L = $self->_listen_state or return;
  return unless defined $L->{conn} && _listen_same_conn($L->{conn}, $conn);
  $self->_listen_failed($L, $L->{gen}, $error // 'listen connection lost');
  return;
}


sub _listen_error {
  my ($self, $error) = @_;
  $self->_listen_state or return;
  $self->_listen_report($error);
  return;
}

# --- LISTEN machinery (private) -----------------------------------------------
#
# State lives in $self->{_listen}, created by the first listen():
#
#   pid        the process that created it; every other process ignores it
#   gen        bumped on every connection change; an async callback carrying an
#              older gen belongs to a superseded attempt and does nothing
#   phase      idle | opening | subscribing | up | waiting (backoff pending)
#   conn       the dedicated listen connection, when one is open
#   watching   whether _listen_watch has been started on conn
#   channels   channel => callback (the registry)
#   subscribed channel => 1, for the current conn
#   waiting    channel => [ Futures handed out by listen() ]
#   ready      [ Futures handed out by listen_reconnect() ]
#   queue      tail of the serialised channel-operation chain on conn
#   delay      the pending backoff timer
#   attempt    consecutive failed attempts, for the backoff
#   proto      the last pending Future a listen seam returned, held weakly: the
#              prototype of the Futures handed to callers (_listen_handout)
#
# Callbacks hold the storage weakly and the state strongly: a storage dropped
# while a reconnect is pending is not kept alive by its own timer, and the
# state it points at is torn down in DESTROY.

# Why a listen-family call must be refused, or undef: the capability gate
# first, then the channel name when the call takes one. Returned, not thrown,
# so the exception names the public method rather than this helper.
sub _listen_refusal {
  my ($self, $capability, @channel) = @_;
  return 'LISTEN/NOTIFY not supported by this storage driver'
    unless grep { $_ eq $capability } $self->transport_capabilities;
  return undef unless @channel;
  my ($channel) = @channel;
  return 'LISTEN/NOTIFY requires a channel name'
    unless defined $channel && !ref $channel && length $channel;
  return undef;
}

# The listen state of THIS process, or undef. State inherited across fork()
# belongs to the parent: it is ignored, never touched, and replaced by a fresh
# one when the child itself listens ($create).
sub _listen_state {
  my ($self, $create) = @_;
  my $L = $self->{_listen};
  undef $L if $L && $L->{pid} != $$;
  return $L if $L || !$create;
  return $self->{_listen} = {
    pid        => $$,
    gen        => 0,
    phase      => 'idle',
    attempt    => 0,
    channels   => {},
    subscribed => {},
    waiting    => {},
    ready      => [],
  };
}

sub _listen_is_current {
  my ($self, $L, $gen) = @_;
  my $cur = $self->{_listen};
  return $cur && $cur == $L && $L->{pid} == $$ && $L->{gen} == $gen;
}

# A plain function: the connection is opaque, a ref or a plain value.
sub _listen_same_conn {
  my ($x, $y) = @_;
  return 0 unless defined $x && defined $y;
  return ref $x
    ? (ref $y && refaddr($x) == refaddr($y))
    : (!ref $y && $x eq $y);
}

# Call a Future-returning seam, turning a throw into a failed Future and a
# plain return into a done one. A pending Future the seam returns is noted as
# the prototype for the Futures handed to callers.
sub _listen_seam_future {
  my ($self, $method, @args) = @_;
  my $fc = $self->future_class;
  my (@r, $err);
  {
    local $@;
    eval { @r = $self->$method(@args); 1 } or $err = $@;
  }
  return $fc->fail($err) if defined $err;
  return $fc->done(@r) unless @r == 1 && blessed($r[0]) && $r[0]->can('then');

  my $L = $self->_listen_state;
  weaken($L->{proto} = $r[0]) if $L && !$r[0]->is_ready;
  return $r[0];
}

# The Future handed to the caller of listen / unlisten / listen_reconnect (karr
# k222, ADR 0056 addendum). Core settles the Futures it hands out, so it must
# construct them, and one constructed from future_class knows no event loop:
# pending, its ->get cannot wait (Future.pm: "is not yet complete and does not
# provide ->await"). So a pending one goes out as $proto->new -- the Future.pm
# idiom for "a new Future of the same kind", which carries the transport's
# class and, where it has one, its loop -- and core's own settles it. Its
# ->get then awaits by driving the loop the transport's seams resolve on.
# Where the transport has shown no pending Future, $f is handed out as it is.
sub _listen_handout {
  my ($self, $L, $f) = @_;
  return $f if $f->is_ready;
  my $proto = $L->{proto} or return $f;

  my $out = $proto->new;
  $self->_listen_retain($f->then(
    $self->_listen_forward($out, 1),
    $self->_listen_forward($out, 0),
  ));
  return $out;
}

# The callback that settles a handed-out Future like core's own. A named sub,
# so it closes over $out and nothing else; the storage is held weakly, as in
# _listen_callback. It never asks whether the attempt is still current: a
# Future handed out is settled whatever happened to the attempt since.
sub _listen_forward {
  my ($self, $out, $ok) = @_;
  my $fc = $self->future_class;
  weaken(my $weak = $self);
  return sub {
    my $self = $weak or return $fc->done;
    $self->_listen_resolve($out, $ok, $_[0]);
    return $fc->done;
  };
}

# Build a Future callback that runs $method($L, $gen, @args, @future_values).
# Built here, in a named sub, so it closes over nothing but these arguments;
# the storage is held weakly.
sub _listen_callback {
  my ($self, $L, $gen, $method, @args) = @_;
  my $fc = $self->future_class;
  weaken(my $weak = $self);
  return sub {
    my $self = $weak or return $fc->done;
    my $r = $self->$method($L, $gen, @args, @_);
    return (blessed($r) && $r->can('then')) ? $r : $fc->done;
  };
}

# Keep a derived Future alive until it settles. A real Future holds its
# sequence Futures only weakly, so an unheld one would never run its callback.
sub _listen_retain {
  my ($self, $f) = @_;
  $f->retain if $f->can('retain');
  return $f;
}

sub _listen_connect {
  my ($self, $L, $reconnect) = @_;
  my $gen = ++$L->{gen};
  $L->{phase} = 'opening';

  $self->_listen_retain(
    $self->_listen_seam_future('_listen_open')->then(
      $self->_listen_callback($L, $gen, '_listen_opened', $reconnect),
      $self->_listen_callback($L, $gen, '_listen_open_failed'),
    )
  );
  return;
}

sub _listen_opened {
  my ($self, $L, $gen, $reconnect, $conn) = @_;

  unless ($self->_listen_is_current($L, $gen)) {
    # A superseded attempt still hands over the connection it opened. It is
    # this process's connection and nobody else will close it.
    if ($L->{pid} == $$ && defined $conn) {
      local $@;
      eval { $self->_listen_close($conn); 1 }
        or $self->_listen_report("closing a superseded listen connection failed: $@");
    }
    return;
  }

  return $self->_listen_failed($L, $gen, '_listen_open resolved without a connection')
    unless defined $conn;

  $L->{conn}       = $conn;
  $L->{phase}      = 'subscribing';
  $L->{subscribed} = {};
  $L->{queue}      = undef;
  $L->{watching}   = 0;

  $self->_listen_enqueue($L, $gen, '_listen_op_subscribe', $conn, $_)
    for sort keys %{ $L->{channels} };
  $self->_listen_enqueue($L, $gen, '_listen_op_arm', $conn, $reconnect);
  return;
}

# The text of a listen-connection error never quotes the connect info's
# credentials, as the pool's connect error does not (ADR 0025 addendum): the
# text is masked as such, and by what the storage knows of its connect info --
# a string conninfo as the DSN slot, a hash with a password as the password
# slot, the DBI form as it is.
sub _listen_masked {
  my ($self, $text) = @_;

  my $info = eval {
    my $answer = $self->_current_async_connect_info($self->access_broker_mode);
    ref $answer eq 'ARRAY' ? $answer->[0] : undef;
  };
  $info = $self->{_conninfo} unless defined $info;

  my @known = ref $info eq 'ARRAY' ? ( $info )
    : ref $info eq 'HASH'
      ? ( [ undef, undef, $info->{password} // $info->{Password} ] )
    : defined $info && !ref $info ? ( [ $info ] )
    : ();

  $text = mask_connect_secrets($text);
  $text = mask_connect_secrets($text, $_) for @known;
  return $text;
}

sub _listen_open_failed {
  my ($self, $L, $gen, $err) = @_;
  $self->_listen_failed($L, $gen, $self->_listen_masked(
    'opening the listen connection failed: ' . ($err // 'unknown error')));
  return;
}

# Serialise one channel operation behind the previous one on this connection.
# It runs whether the previous one succeeded or failed.
sub _listen_enqueue {
  my ($self, $L, $gen, $method, @args) = @_;
  my $prev = $L->{queue} || $self->future_class->done;
  my $cb   = $self->_listen_callback($L, $gen, $method, @args);
  my $run  = sub { $cb->() };
  my $next = $self->_listen_retain($prev->then($run, $run));
  $L->{queue} = $next;
  return $next;
}

sub _listen_op_subscribe {
  my ($self, $L, $gen, $conn, $channel) = @_;
  return unless $self->_listen_is_current($L, $gen);
  return unless exists $L->{channels}{$channel};   # unlistened meanwhile
  return if $L->{subscribed}{$channel};

  return $self->_listen_seam_future('_listen_subscribe', $conn, $channel)->then(
    $self->_listen_callback($L, $gen, '_listen_op_subscribed', $channel),
    $self->_listen_callback($L, $gen, '_listen_op_failed', $conn, $channel, 'LISTEN'),
  );
}

sub _listen_op_subscribed {
  my ($self, $L, $gen, $channel) = @_;
  return unless $self->_listen_is_current($L, $gen);
  return unless exists $L->{channels}{$channel};
  $L->{subscribed}{$channel} = 1;
  # While the connection is still being set up, _listen_op_arm settles it.
  $self->_listen_settle($L, $channel, 1) if $L->{phase} eq 'up';
  return;
}

sub _listen_op_unsubscribe {
  my ($self, $L, $gen, $conn, $channel) = @_;
  return unless $self->_listen_is_current($L, $gen);
  return if exists $L->{channels}{$channel};   # listened again meanwhile

  my $fc = $self->future_class;
  return $self->_listen_seam_future('_listen_unsubscribe', $conn, $channel)->then(
    sub { return $fc->done },
    $self->_listen_callback($L, $gen, '_listen_op_failed', $conn, $channel, 'UNLISTEN'),
  );
}

# A channel operation failed. The probe decides what failed: a dead connection
# goes to self-healing; on a live one the statement itself was refused.
sub _listen_op_failed {
  my ($self, $L, $gen, $conn, $channel, $verb, $err) = @_;
  my $fc = $self->future_class;
  return $fc->done unless $self->_listen_is_current($L, $gen);

  $err = $self->_listen_masked(
    "$verb on channel '$channel' failed: " . ($err // 'unknown error'));

  if (defined $self->_listen_probe_error($conn)) {
    $self->_listen_failed($L, $gen, $err);
    return $fc->fail($err);
  }

  if ($verb eq 'LISTEN' && exists $L->{channels}{$channel}) {
    delete $L->{channels}{$channel};
    $self->_listen_report($err);
    $self->_listen_settle($L, $channel, 0, $err);
    $self->_listen_teardown($L, $err) unless %{ $L->{channels} };
    return $fc->fail($err);
  }

  $self->_listen_report($err);
  return $fc->fail($err);
}

# Last step on a fresh connection, queued behind every subscribe: re-arm.
sub _listen_op_arm {
  my ($self, $L, $gen, $conn, $reconnect) = @_;
  return unless $self->_listen_is_current($L, $gen);

  # Watched from the call on, not from its return (karr k222): the transport
  # may dispatch or report the connection lost from inside _listen_watch, and
  # whatever closes the connection then must unwatch it too.
  $L->{watching} = 1;
  my $err;
  {
    local $@;
    eval { $self->_listen_watch($conn); 1 } or $err = $@;
  }
  $err = "starting to watch the listen connection failed: $err" if defined $err;

  # A callback or a death report during the watch ended this attempt: whatever
  # did so owns the state now.
  unless ($self->_listen_is_current($L, $gen)) {
    $self->_listen_report($err) if defined $err;
    return;
  }
  if (defined $err) {
    $L->{watching} = 0;   # a watch that threw started nothing to stop
    $self->_listen_failed($L, $gen, $err);
    return;
  }

  $L->{phase}   = 'up';
  $L->{attempt} = 0;

  $self->_listen_fire_reconnect if $reconnect;
  return unless $self->_listen_is_current($L, $gen);   # the hook may act

  $self->_listen_settle($L, $_, 1)
    for grep { $L->{subscribed}{$_} } keys %{ $L->{waiting} };
  $self->_listen_settle_ready($L, 1);
  return;
}

# The connection of attempt $gen is dead or could not be set up: close it,
# report, fail what waited on this attempt, schedule the next one.
#
# The state is settled before anything user-visible runs: the hook and the
# failed Futures' callbacks may call back into the API (listen_reconnect from
# on_listen_error is the obvious case), so they must find the dead connection
# already gone, and whatever they start supersedes this path.
sub _listen_failed {
  my ($self, $L, $gen, $err) = @_;
  return unless $self->_listen_is_current($L, $gen);
  $err //= 'listen connection lost';

  my $next = ++$L->{gen};
  my ($conn, $watching) = $self->_listen_detach_conn($L);
  $L->{phase} = %{ $L->{channels} } ? 'waiting' : 'idle';

  $self->_listen_report($err);
  $self->_listen_close_conn($L, $conn, $watching);
  return unless $self->_listen_is_current($L, $next);

  $self->_listen_settle_all($L, 0, $err);
  return unless $self->_listen_is_current($L, $next) && %{ $L->{channels} };

  $self->_listen_schedule($L, $next);
  return;
}

sub _listen_schedule {
  my ($self, $L, $gen) = @_;
  my $seconds = $self->_listen_backoff(++$L->{attempt});
  $L->{phase} = 'waiting';

  my $timer = $self->_listen_seam_future('_listen_delay', $seconds);
  $L->{delay} = $timer;
  $self->_listen_retain($timer->then(
    $self->_listen_callback($L, $gen, '_listen_delay_elapsed'),
    $self->_listen_callback($L, $gen, '_listen_delay_failed'),
  ));
  return;
}

sub _listen_backoff {
  my ($self, $attempt) = @_;
  my $max   = $self->listen_backoff_max;
  my $delay = $self->listen_backoff_initial * 2 ** ($attempt - 1);
  return $delay > $max ? $max : $delay;
}

sub _listen_delay_elapsed {
  my ($self, $L, $gen) = @_;
  return unless $self->_listen_is_current($L, $gen);
  delete $L->{delay};
  $self->_listen_connect($L, 1);
  return;
}

sub _listen_delay_failed {
  my ($self, $L, $gen, $err) = @_;
  return unless $self->_listen_is_current($L, $gen);
  delete $L->{delay};
  $L->{phase} = 'idle';
  $self->_listen_report(
    'the reconnect backoff timer failed, self-healing has stopped '
  . '(listen_reconnect or a new listen resumes it): ' . ($err // 'unknown error')
  );
  return;
}

sub _listen_cancel_timer {
  my ($self, $L) = @_;
  my $timer = delete $L->{delay} or return;
  return unless $L->{pid} == $$;
  $timer->cancel if $timer->can('cancel') && !$timer->is_ready;
  return;
}

# undef when the connection answers the probe, otherwise why it does not.
sub _listen_probe_error {
  my ($self, $conn) = @_;
  my ($alive, $err);
  {
    local $@;
    eval { $alive = $self->_listen_probe($conn); 1 } or $err = $@;
  }
  return "listen connection probe failed: $err" if defined $err;
  return $alive ? undef : 'listen connection probe failed';
}

# Stop watching and close the current connection, if this process owns it.
sub _listen_drop_conn {
  my ($self, $L) = @_;
  $self->_listen_close_conn($L, $self->_listen_detach_conn($L));
  return;
}

# Take the connection out of the state; returns ($conn, $watching).
sub _listen_detach_conn {
  my ($self, $L) = @_;
  my $conn     = delete $L->{conn};
  my $watching = delete $L->{watching};
  $L->{subscribed} = {};
  $L->{queue}      = undef;
  return ($conn, $watching);
}

# The physical half: unwatch and close, only in the process that opened it.
sub _listen_close_conn {
  my ($self, $L, $conn, $watching) = @_;
  return unless defined $conn && $L->{pid} == $$;

  local $@;
  if ($watching) {
    eval { $self->_listen_unwatch($conn); 1 }
      or $self->_listen_report("stopping the listen watch failed: $@");
  }
  eval { $self->_listen_close($conn); 1 }
    or $self->_listen_report("closing the listen connection failed: $@");
  return;
}

# End listening altogether: the last channel went, or the storage disconnects.
# State inherited from a parent process is only forgotten, never acted on.
sub _listen_teardown {
  my ($self, $L, $reason) = @_;
  $L //= $self->{_listen} or return;
  delete $self->{_listen} if $self->{_listen} && $self->{_listen} == $L;
  return unless $L->{pid} == $$;

  $L->{gen}++;
  $self->_listen_cancel_timer($L);
  $self->_listen_drop_conn($L);
  $L->{phase}   = 'idle';
  $L->{attempt} = 0;
  $self->_listen_settle_all($L, 0, $reason // 'listening has ended');
  return;
}

sub _listen_settle {
  my ($self, $L, $channel, $ok, $err) = @_;
  my $futures = delete $L->{waiting}{$channel} or return;
  $self->_listen_resolve($_, $ok, $err) for @$futures;
  return;
}

sub _listen_settle_ready {
  my ($self, $L, $ok, $err) = @_;
  my @futures = @{ $L->{ready} || [] };
  $L->{ready} = [];
  $self->_listen_resolve($_, $ok, $err) for @futures;
  return;
}

sub _listen_settle_all {
  my ($self, $L, $ok, $err) = @_;
  $self->_listen_settle($L, $_, $ok, $err) for keys %{ $L->{waiting} };
  $self->_listen_settle_ready($L, $ok, $err);
  return;
}

# $f may be gone: in global destruction Perl frees objects in no particular
# order, and a Future still waiting in the state can be freed before the
# storage whose DESTROY settles it (karr k237). Nobody can observe it then.
sub _listen_resolve {
  my ($self, $f, $ok, $err) = @_;
  return if !defined $f || $f->is_ready;
  local $@;
  eval { $ok ? $f->done : $f->fail($err); 1 }
    or $self->_listen_report("a callback on a listen Future died: $@");
  return;
}

sub _listen_report {
  my ($self, $err) = @_;
  chomp(my $msg = defined $err ? "$err" : 'unknown listen error');
  my $hook = $self->on_listen_error;
  unless ($hook) {
    warn "DBIO LISTEN error: $msg\n";
    return;
  }
  local $@;
  eval { $hook->($self, $msg); 1 }
    or warn "DBIO on_listen_error hook died: $@";
  return;
}

sub _listen_fire_reconnect {
  my ($self) = @_;
  my $hook = $self->on_listen_reconnect or return;
  local $@;
  eval { $hook->($self); 1 }
    or $self->_listen_report("on_listen_reconnect hook died: $@");
  return;
}


sub deploy_async {
  my ($self, $schema, $opts) = @_;
  $opts //= {};

  # Generate the install DDL from the schema classes (synchronous, in-memory --
  # no DB roundtrips). Uses the same _ddl_class->install_ddl($schema) convention
  # the sync DBIO::Deploy::Base path uses, NOT a driver-specific schema method.
  my $ddl = $self->_install_ddl($schema);

  # Optional DROP TABLE pre-pass for idempotent re-runs.
  if ($opts->{add_drop_table}) {
    $ddl = join("\n\n", $self->_drop_statements_for($schema), $ddl);
  }

  my $fc = $self->future_class;

  # ADR 0026: never blanket-wrap DDL in a transaction. On a non-transactional
  # engine an async transaction is a false atomicity promise (MySQL/Oracle/...
  # implicitly COMMIT each DDL statement), so run the whole batch
  # statement-at-a-time on one pooled connection with a one-shot warning -- the
  # Future-side mirror of DBIO::Deploy::Base::_execute_ddl.
  unless ($self->_use_transactional_ddl) {
    my $class = ref($self) || $self;
    $self->_warn_non_txn_ddl_once(
      "$class -- async DDL loop is not atomic; recovery depends on the driver's version-row gate"
    );

    # Released to the pool it was acquired from, not to $self->pool asked
    # again when the batch ends (karr dbio-async k46).
    my $pool = $self->pool;
    return $self->_hold_derived($pool->acquire->then(sub {
      my $conn = shift;
      # A dispatch that dies before it has a Future must still release $conn
      # (karr k229): as a failed Future it takes the same release below.
      my $ddl_future = $self->_seam_future(_execute_ddl_async => $conn, $ddl);
      my ($release, $retire) = _hand_back_once($pool, $conn);
      return _retire_on_cancel($ddl_future->then(sub {
        $release->();
        return $fc->done(@_);
      }, sub {
        my $err = shift;
        $release->();
        return $fc->fail($err);
      }), $retire);
    }));
  }

  # Transactional engine. ADR 0026 addendum (k132), async parity (k199): the
  # capability answers for the connection, but atomicity is per statement. Ask
  # the SAME per-statement hook the sync path asks -- on the owning sync storage,
  # the one _use_transactional_ddl delegates to and the one that carries the
  # _ddl_statement_is_transactional capability -- and reuse the sync grouping so
  # the runs come out in the SAME order and grouping. A transaction-safe run is
  # bracketed in one txn_do_async on a pinned connection; a run the hook declares
  # non-transactional executes on its own pooled connection, outside any
  # transaction. All statements safe (or no hook) => one run, identical to
  # bracketing the whole loop.
  my @stmts = DBIO::Deploy::Base::_split_ddl($self->_owner_storage, $ddl);
  my @runs  = DBIO::Deploy::Base::_group_ddl_statements($self->_owner_storage, \@stmts);

  if (@runs > 1) {
    my $class = ref($self) || $self;
    my $loose = scalar grep { !$_->[0] } @runs;
    $self->_warn_split_ddl_once(
      "$class -- $loose statement(s) cannot run inside a transaction, so the "
    . "async DDL batch was split into " . scalar(@runs) . " runs and is not "
    . "atomic as a whole; recovery depends on the driver's version-row gate"
    );
  }

  # The pool the deploy begins on is the pool of every run of it (karr k331).
  return $self->_run_ddl_runs_async(\@runs, 0, $self->pool);
}

# Execute the runs of a transactional engine's batch sequentially, in order,
# from run $from on. A failure in any run short-circuits the rest: the ->then
# chain propagates the failure and the next run is never started. Each run
# releases its own connection exactly once -- a txn run through txn_do_async's
# finalizer, an outlier run in both the success and failure continuations
# below.
#
# The next run is this method again, one further on -- not an anonymous sub
# that calls itself through its own variable. Such a sub holds itself, and with
# it the backend and the runs, for good: every deploy left its backend behind,
# and the backend its pool with the connections in it. What chains the runs
# here is held by the Future of the run before only, and goes with it.
#
# $pool is the pool the deploy began on, handed from run to run (karr k331).
# A run that finds it shut down -- the storage was disconnected between two
# runs -- fails the deploy: a later run on a NEW pool would carry on on another
# connection set with the batch's bracket broken, and leave the disconnected
# storage holding a pool nobody asked for. There is no resuming.
sub _run_ddl_runs_async {
  my ($self, $runs, $from, $pool) = @_;
  $from //= 0;
  $pool //= $self->pool;

  my $fc = $self->future_class;

  while (my $run = $runs->[$from]) {
    return $fc->fail('storage disconnected during deploy')
      if _pool_is_shut_down($pool);

    my $run_future = $self->_start_ddl_run_async($run, $pool);

    # Answered at once and without error: the next run is the next turn of this
    # loop, not a further call on top of this one (a ->then on a Future that is
    # ready runs its callback on the spot, so a long batch would otherwise
    # recurse once per run).
    if ($run_future->is_ready && !$run_future->is_failed && !_is_cancelled($run_future)) {
      $from++;
      next;
    }

    # Pending, failed or cancelled: the chain goes on from the Future of this
    # run (a failure passes through without the callback).
    my $next = $from + 1;
    return $run_future->then(sub {
      return $self->_run_ddl_runs_async($runs, $next, $pool);
    });
  }

  return $fc->done;
}

sub _pool_is_shut_down {
  my ($pool) = @_;
  return 0 unless Scalar::Util::blessed($pool) && $pool->can('is_shutdown');
  return $pool->is_shutdown ? 1 : 0;
}

# Start one run of a batch -- $run is [ $transactional, @statements ] -- and
# answer its Future.
sub _start_ddl_run_async {
  my ($self, $run, $pool) = @_;
  my $fc = $self->future_class;
  my ($transactional, @group) = @$run;

  if ($transactional) {
    # The connection BEGIN ran on, asked of the context under the name
    # txn_do_async built it with -- never under txn_conn as such (karr k284).
    my $accessor = $self->_txn_conn_accessor;
    return $self->txn_do_async(sub {
      my ($ctx) = @_;
      return $self->_run_ddl_stmts_async($ctx->$accessor, \@group, undef, $pool);
    });
  }

  # Same as the non-transactional engine branch of deploy_async (karr k229,
  # and karr dbio-async k46 for the pool the release goes to).
  $pool //= $self->pool;
  return $self->_hold_derived($pool->acquire->then(sub {
    my $conn = shift;
    my $ddl_future = $self->_seam_future(_run_ddl_stmts_async => $conn, \@group);
    my ($release, $retire) = _hand_back_once($pool, $conn);
    return _retire_on_cancel($ddl_future->then(sub {
      $release->();
      return $fc->done;
    }, sub {
      my $err = shift;
      $release->();
      return $fc->fail($err);
    }), $retire);
  }));
}

sub _is_cancelled {
  my ($f) = @_;
  return $f->can('is_cancelled') && $f->is_cancelled ? 1 : 0;
}

# The two ways a DDL run on a pooled connection hands it back, sharing one
# record so that it happens once (karr k274): release, when the statements were
# answered; retire, when the Future the caller holds was cancelled with a
# statement in flight -- its outcome is unknown and the connection may still be
# busy with it, so it does not go back into the pool.
# The lease of the borrow $conn is in (karr core k275), taken right after the
# acquire resolved and handed back with the release. A pool that is not a
# DBIO::Storage::PoolBase has none: its release is called as before.
sub _pool_lease {
  my ($pool, $conn) = @_;
  return $pool->can('_lease') ? $pool->_lease($conn) : undef;
}

sub _hand_back_once {
  my ($pool, $conn) = @_;
  my $gone;
  my $lease = _pool_lease($pool, $conn);
  return (
    sub { return if $gone++; $pool->release($conn, $lease); return },
    sub {
      return if $gone++;
      local $@;
      eval { $pool->_retire_in_use_connection($conn) };
      return;
    },
  );
}

# Run $retire when the Future $f is cancelled while pending; returns $f.
sub _retire_on_cancel {
  my ($f, $retire) = @_;
  $f->on_cancel($retire) if $f->can('on_cancel') && !$f->is_ready;
  return $f;
}


sub _install_ddl {
  my ($self, $schema) = @_;
  return $self->_ddl_class->install_ddl($schema);
}


sub _ddl_class {
  croak 'Subclass must override _ddl_class to support deploy_async';
}


sub _use_transactional_ddl {
  my ($self) = @_;
  my $owner = $self->_owner_storage or return 0;
  return 0 unless $owner->can('_use_transactional_ddl');
  return $owner->_use_transactional_ddl ? 1 : 0;
}


sub _execute_ddl_async {
  my ($self, $conn, $ddl) = @_;
  my @stmts = DBIO::Deploy::Base::_split_ddl($self->_owner_storage, $ddl);
  return $self->_run_ddl_stmts_async($conn, \@stmts);
}

# Chain a pre-split list of DDL statements on one connection, sequentially --
# each waits for the previous, so the transport never has two DDL statements in
# flight on one connection. Shared by _execute_ddl_async (the string entry
# point, which splits and skips comment-only statements first) and deploy_async
# (which passes an already-grouped, already-cleaned run of statements).
#
# The next statement is this method again, one further on ($from, which a
# caller does not pass), as _txn_statements_settled goes on -- not an anonymous
# sub calling itself through its own variable, which holds itself and with it
# the backend, the connection and the statements not sent yet, for good (see
# _run_ddl_runs_async). The list is copied once, on the way in: the caller's is
# neither changed nor followed.
#
# $pool, when given, is the pool of the deploy this run belongs to: found shut
# down between two statements, the run fails with 'storage disconnected during
# deploy' and sends nothing more -- the transaction around it rolls back.
sub _run_ddl_stmts_async {
  my ($self, $conn, $stmts, $from, $pool) = @_;
  $stmts = [ @$stmts ] unless defined $from;
  $from //= 0;

  while (defined(my $stmt = $stmts->[$from])) {
    return $self->future_class->fail('storage disconnected during deploy')
      if $from > 0 && $pool && _pool_is_shut_down($pool);

    my $f = $self->_query_async_pinned($conn, $stmt, []);

    # Answered at once and without error: the next statement is the next turn
    # of this loop, not a further call on top of this one -- a ->then on a
    # Future that is ready runs its callback on the spot, so a long run would
    # otherwise recurse once per statement. Never a second statement before
    # this one is answered: the loop only goes on past a ready Future.
    if ($f->is_ready && !$f->is_failed && !_is_cancelled($f)) {
      $from++;
      next;
    }

    # Pending, failed or cancelled: go on from this Future (a failure passes
    # through without the callback, and nothing after it is sent).
    my $next = $from + 1;
    return $f->then(sub {
      return $self->_run_ddl_stmts_async($conn, $stmts, $next, $pool);
    });
  }

  return $self->future_class->done;
}


sub _ddl_quote_ident {
  my ($self, $name) = @_;
  return DBIO::SQL::Util::_quote_ident($name);
}


sub _drop_statements_for {
  my ($self, $schema) = @_;
  return DBIO::SQL::Util::_drop_statements(
    $schema, sub { $self->_ddl_quote_ident($_[0]) }, { cascade => 1 },
  );
}

# ADR 0026: one-shot informational warning when async DDL runs on a
# non-transactional engine, mirroring the sync DBIO::Deploy::Base helper. Kept
# as a local one-time closure (not DBIO::Carp) so nothing leaks into the
# package's method namespace (t/55namespaces_cleaned.t). Keyed on the full
# message so a different class gets its own one-shot.
my %_WARNED_NON_TXN_DDL;
sub _warn_non_txn_ddl_once {
  my ($self, $msg) = @_;
  return if $_WARNED_NON_TXN_DDL{$msg}++;
  warn "non-transactional DDL on $msg\n";
}

# ADR 0026 addendum (k132), async parity (k199): one-shot notice that a
# transactional engine's DDL batch was split into multiple runs because the
# per-statement hook declared some statement non-transactional, so the batch is
# no longer atomic as a whole. Keyed on the CLASS, not the message -- the text
# carries per-batch statement/run counts that vary, so keying on the message
# would re-arm the one-shot for every new upgrade shape (the same reasoning as
# the sync DBIO::Deploy::Base::_warn_split_ddl_once). Local closure, not
# DBIO::Carp, to keep the package method namespace clean (t/55namespaces_cleaned.t).
my %_WARNED_SPLIT_DDL;
sub _warn_split_ddl_once {
  my ($self, $msg) = @_;
  my $key = ref($self) || $self;
  return if $_WARNED_SPLIT_DDL{$key}++;
  warn "split DDL batch on $msg\n";
}

# --- Sync fallbacks ---
# Let sync methods work by blocking on the async result via ->get.
# Useful for scripts/migrations.


sub select        { my $self = shift; return $self->select_async(@_)->get        }
sub select_single { my $self = shift; return $self->select_single_async(@_)->get }
sub insert        { my $self = shift; return $self->insert_async(@_)->get        }
sub update        { my $self = shift; return $self->update_async(@_)->get        }
sub delete        { my $self = shift; return $self->delete_async(@_)->get        }
sub txn_do        { my $self = shift; return $self->txn_do_async(@_)->get        }
sub deploy        { my $self = shift; return $self->deploy_async(@_)->get        }

# --- Schema integration ---

sub schema { $_[0]->{schema} }


sub debug  { $_[0]->{debug} }


sub in_txn { 0 }


sub connected { defined $_[0]->{pool} && $_[0]->pool->available > 0 }


sub disconnect {
  my $self = shift;
  # Rotate before shutdown so no context from the outgoing pool generation can
  # dispatch while or after that pool is being torn down. This also rotates when
  # the pool was never materialised.
  $self->_rotate_context_owner_token;
  $self->_listen_teardown(undef, 'the storage was disconnected')
    if $self->{_listen};
  if ($self->{pool}) {
    $self->{pool}->shutdown;
    $self->{pool} = undef;
  }
}

sub DESTROY {
  my $self = shift;
  $self->disconnect if $self->{pool} || $self->{_listen};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async - Base class for async storage implementations

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Async is chosen per connection, not by naming a storage class:
  my $schema = MyApp::Schema->connect(
      $dsn, $user, $pass,
      { async => 'future_io' },
  );

  # Async queries return Futures
  $schema->resultset('Artist')->all_async->then(sub {
      my @artists = @_;
      say $_->name for @artists;
  });

See F<t/test/09_async.t> for a runnable example.

=head1 DESCRIPTION

Concrete, loop-agnostic base class for async DBIO storage drivers. Extends
L<DBIO::Storage> with async-specific infrastructure: connection pooling,
transaction pinning, and Future-based query execution.

The B<Model-B orchestration> (ADR 0030 §4) lives here: connect-info
normalisation, the shared CRUD builder (C<_run_crud>) with its pooled and
pinned runners, INSERT returned-columns mapping (ADR 0031 §3),
L</txn_do_async> bracketing through the generic
L<DBIO::Storage::Async::TransactionContext>, the L</pipeline> scaffold, and the
self-healing L</LISTEN / NOTIFY> machinery (ADR 0056).
Everything DB- and loop-specific is factored out behind B<transport seam
hooks> a backend overrides -- how to submit an async query
(L</_query_async> / L</_query_async_pinned>), the INSERT returned-columns
suffix (L</_post_insert_sql>), the connection pool (L</pool>), and the Future
implementation (L</future_class>). Placeholder/SQL shaping is B<not> among
them: L</_transform_sql> is transport-B<internal>, called by a transport's own
query seam and never by this orchestration (ADR 0032 §6). A backend therefore
collapses to transport-only: it overrides the seams, not the orchestration.

Async is an explicit, B<per-connection mode> (ADR 0030): the backend class
is chosen at C<connect> time by a named string and fixed for the life of that
instance, so the same schema class runs sync and several async modes side by
side. Each mode is registered against the driver
(L<DBIO::Storage::DBI/register_async_mode>) and resolves to a concrete
subclass of this class:

=over 4

=item * C<future_io> -- L<DBIO::Async::Storage> (dist C<dbio-async>) is the
abstract, loop-agnostic Future::IO base; each driver supplies a concrete adapter
C<< DBIO::X::Storage::Async >> that drives its own non-blocking DBD binding. The
adapter is B<resolved by convention> off the concrete storage class
(C<< ref($storage) . '::Async' >>, e.g. C<DBIO::PostgreSQL::Storage> ->
C<DBIO::PostgreSQL::Storage::Async>); loading C<dbio-async> registers no generic
C<future_io> mode, and a driver without such an adapter croaks early. The event
loop is chosen by installing a C<Future::IO::Impl::*> adapter, B<not> by picking a
different distribution: L<IO::Poll> is the built-in default (no event loop), and
IO::Async, AnyEvent, Mojo, UV or Glib take over when the matching
C<Future::IO::Impl::*> module is installed.

=item * C<ev> -- the per-driver EV add-on, driver-resolved:
L<DBIO::PostgreSQL::EV::Storage> (dist C<dbio-postgresql-ev>, over L<EV::Pg>)
or L<DBIO::MySQL::EV::Storage> (dist C<dbio-mysql-ev>, over C<EV::MariaDB>).
One database per add-on, a native event-loop-bound client.

=item * C<forked> -- L<DBIO::Forked::Storage> (dist C<dbio-forked>): the
ordinary sync driver run inside a C<fork()>, no event loop. Universal.

=item * C<immediate> -- L<DBIO::Future::Immediate> (core): the explicit,
synchronous, immediately-resolved shim (the mock L<DBIO::Test::Storage>
defaults to it so mock tests run with no loop).

=back

A requested mode that is not installed/registered croaks loudly; C<*_async>
on a sync instance (no mode chosen) croaks rather than degrading silently.

=head1 ATTRIBUTES

=head2 on_listen_error

  $storage->on_listen_error(sub {
    my ($storage, $error) = @_;
    ...
  });

Coderef called with the storage and the error text for B<every> error the
listen machinery meets: a lost or dead listen connection, a failed connect or
reconnect attempt, a failed subscribe or unsubscribe, a dying channel callback,
a failure to close the old connection, and the non-fatal errors a transport
reports through L</_listen_error>. Where a Future was handed out for the
same operation it carries the error too; the hook is the one place that sees
all of them, which is what a daemon's log wants. Without a hook the error is
C<warn>ed -- the machinery never drops an error silently. A hook that dies is
itself reported with C<warn>.

=head2 on_listen_reconnect

  $storage->on_listen_reconnect(sub {
    my ($storage) = @_;
    ...
  });

Coderef called with the storage each time the listen connection has been
B<rebuilt> -- after self-healing or a forced L</listen_reconnect> -- once every
registered channel is subscribed again and watching is re-armed. Not called
for the first connection. Notifications sent while the connection was down are
lost (NOTIFY is not durable); this hook is where a consumer re-reads whatever
state it would otherwise have learned from them. A hook that dies is reported
through L</on_listen_error>.

=head2 listen_backoff_initial

=head2 listen_backoff_max

  $storage->listen_backoff_initial(0.5);   # this instance
  My::Transport->listen_backoff_max(60);   # a transport's default

Bounds of the reconnect backoff, in seconds: attempt I<n> waits
C<< min(listen_backoff_initial * 2 ** (n - 1), listen_backoff_max) >>.
Defaults 1 and 30. Inherited class data, so a transport class can set its own
defaults and an instance can override them.

=head1 METHODS

=head2 new

  my $storage = $class->new($schema);

Construct an async storage bound to C<$schema>. The schema reference is held
weakly (the schema owns the storage, not the other way round).

=head2 future_class

Transport seam. Must be overridden by a backend to return the
event-loop-specific Future class (e.g. C<'Future'> for L<Future.pm|Future>).

=head2 pool

Transport seam. Returns the connection pool object. Must be overridden by a
backend.

A transport typically builds its pool here on first use, in the slot
L</disconnect> empties. So calling it is for whatever B<begins> work -- a
query, a transaction, a pipeline, a deploy -- and what begins work keeps the
pool it got. What B<ends> work talks to that pool, the one its connection came
from, and never calls this again: after a L</disconnect>
that pool is shut down, where a release is a no-op, while a second call here
would build a new pool on the disconnected storage and release into it a
connection it never held. L</txn_do_async>, L</pipeline> and L</deploy_async>
keep to this, and a transport's own L</_query_async> must too -- see the
pattern there.

=head2 _is_access_broker_connect_info

  if ($self->_is_access_broker_connect_info($info)) { ... }

True when the supplied connect info is a broker-style invocation: a
single-element arrayref whose sole member is a blessed
L<DBIO::AccessBroker> instance. The DBI side
(L<DBIO::Storage::DBI::AccessBroker>) also takes connect options beside the
broker. Its embedded async backend is handed the broker alone, unless those
options hold settings the backend applies itself and its transport declares
C<broker_connect_options> (L</transport_capabilities>); then it gets
C<< [ $broker, \%options ] >>, which L</connect_info> takes through
L</_access_broker_call_options>. This predicate stays single-element, so a
transport that overrides C<connect_info> never takes that form for the bare
broker form by accident.

=head2 set_access_broker

  $storage->set_access_broker($broker);
  $storage->set_access_broker($broker, $mode);

Attach C<$broker> (L<DBIO::Storage/set_access_broker>, which refuses anything
that is no L<DBIO::AccessBroker> before a thing is changed) -- the one place
an async storage gets a broker. Attaching is a new
configuration, so everything the connect info before left is forgotten first:
the stored conninfo, which must not stand beside a broker,
and the pool size, the options and the connect options beside a broker, which
would otherwise be those of the connect info before, standing beside the new
broker. Then the per-spawn provider is installed (L</_conninfo_provider>).

A pool that is already built is handed the provider as well
(L<DBIO::Storage::PoolBase/set_conninfo_provider>), so its next
connection is opened from this broker, whether it was built through a broker
before or from static conninfo. Open connections and running transactions stay
as they are.

A broker attached by calling this directly is therefore attached in full.
Before, only the broker slot was set: no provider, and the conninfo of a
static connection still stored, from which a transport went on to build its
pool.

=head2 clear_access_broker

  $storage->clear_access_broker;

Detach the broker (L<DBIO::Storage/clear_access_broker>) -- the one place an
async storage loses it. What came with the broker goes with
it: the pool size and the options read from its answer, and the connect
options given beside it. No conninfo is stored while a broker is attached, so
the storage is left with nothing to connect from. A storage with no broker
attached is not touched, as on the sync side
(L<DBIO::Storage::DBI::AccessBroker/clear_access_broker>).

The provider is left where it is, and refuses from now on
(L</_conninfo_provider>): the next pool connection fails -- as a failed
Future, L<DBIO::Storage::PoolBase/acquire> never throws -- saying that no
broker is attached, and so does a listen connection opened through the
provider. Connections that are open stay open, as the sync storage keeps its
handle. L</_clear_access_broker> forgets the provider as well.

=head2 _setup_access_broker

  $self->_setup_access_broker($info->[0]);

Attach the broker in write mode: L</set_access_broker>, under the name a
driver's C<connect_info> calls when L</_is_access_broker_connect_info>
matched. Because attaching forgets what the connect info before left, a
driver that calls this before it reads the broker's answer leaves nothing of
that connect info behind when the reading throws.

=head2 _clear_access_broker

  $self->_clear_access_broker;

Detach any broker (L</clear_access_broker>) and forget everything else a
connect info left: the provider, the stored conninfo, the pool size, the
options and the connect options beside a broker. The storage is then where
one never given connect info is, so a subsequent non-broker connect uses the
static conninfo path with nothing of the connect info before in it. Call from
a driver's C<connect_info> on the non-broker branch, before the new connect
info is read.

=head2 _conninfo_provider

The per-spawn credential coderef installed by L</set_access_broker>, or
C<undef> on a storage that has no broker and never had one since its last
connect info. Hand this to the pool as its C<conninfo_provider> so every NEW
pool connection is built from fresh credentials (see C<_spawn_connection> in
L<DBIO::Storage::PoolBase>).

On each invocation the coderef calls the driver's L</_async_broker_conninfo>
to obtain freshly-refreshed, storage-native connect info for one new
connection, from the broker that is attached at that moment.

With no broker attached it croaks, saying so, and asks the driver nothing.
That happens after L</clear_access_broker>, which leaves the provider on the
storage, and in a pool built with the provider, which keeps it whatever is
done to the storage. Before, the refusal was each transport's to make, in
L</_async_broker_conninfo>; one that did not was handed whatever
L</_current_async_connect_info> answers without a broker, and opened the
connection from no conninfo at all.

The coderef holds this storage B<weakly>. The storage keeps the coderef and
hands it to its pool; held strongly, the storage would hold itself, and a
backend dropped with a broker attached would never be freed, nor its pool
shut down and the connections in it closed. Called once its
storage is gone, the coderef croaks.

=head2 _async_broker_conninfo

  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    ...
    return $conninfo;  # one fresh, storage-native conninfo value
  }

Required driver seam hook when a broker is in use: return one fresh
storage-native connect-info value for a single new pool connection, in the
shape the pool's C<_transform_conninfo> expects (e.g. the libpq parameter
hashref for the PostgreSQL pool). Invoked once per pool spawn by the
L</_conninfo_provider> coderef. Defaults to croaking; a driver that
consumes the broker must override it.

Build it from L</_current_async_connect_info> or from
L<DBIO::Storage/current_access_broker_connect_info>: both refuse a broker that
answers nothing, so the connection is never opened with the conninfo
L</connect_info> stored instead.

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. Handles both broker-style and direct connect
info, normalising each through L</_normalize_conninfo> (a DB-specific seam,
identity by default) and C<_normalize_async_connect_info> (pool-size / opts
extraction). Returns the stored raw connect info.

Before the DB-specific L</_normalize_conninfo> seam runs, the DBIO-private
connect attributes (the async mode selector, C<quote_char>/C<name_sep>/
C<quote_names>, storage options incl. C<cursor_class>, and C<ignore_version>)
are stripped out centrally (C<_strip_private_connect_attrs>), so
the seam and ultimately C<DBI-E<gt>connect> only ever see real DBD attributes.
This mirrors the sync path's
C<_normalize_connect_info> in L<DBIO::Storage::DBI> and both consume one shared
name list on L<DBIO::Storage>, so a strict DBD (e.g. DBD::MariaDB) never
receives an unrecognised private attribute.

Broker-style info is C<< [ $broker ] >>, or C<< [ $broker, \%options ] >>
for a transport that declares C<broker_connect_options>: the options are
stripped the same way, a C<pool_size> among them sizes the pool, and the DBD
attributes left are kept for the transport
(L</_access_broker_call_options>, L</_access_broker_call_attributes>). A
C<pool_size> in the broker's answer sizes the pool too; given both ways, the
two must be the same (L</_access_broker_pool_size>). No conninfo is kept from
the answer: every connection asks the broker again, through
L</_conninfo_provider>. An answer that is neither a hash nor
an array throws, naming the broker class and the shape of the answer, never a
value of it.

Every call is a full reconfiguration (ADR 0050), B<also one that throws>.
Before anything of the new connect info is read, everything the call before
left is forgotten: its broker and provider, its stored conninfo, its pool
size, its options, what stood beside its broker, and the connect info as it
was given. Reading can throw in many places -- a driver's
L</_normalize_conninfo>, the refusal of options beside a broker, the broker
itself, an answer of nothing or of no usable shape, two pool sizes that
disagree -- and none of them leaves a value of the call before for a later
connection. A call that throws before it reaches a broker leaves the storage
where one never given connect info is. One that throws once the new broker is
attached leaves that broker attached, in full: its provider, and what stood
beside it in this call, so a connection opened afterwards asks this broker and
is not opened without those options. Before, the conninfo of the call before
was dropped but its pool size and options stayed beside the new broker, and a
call that threw early left the call before in place as a whole.

=head2 _access_broker_call_options

  my $beside = $storage->_access_broker_call_options([ $broker, \%options ]);
  # { pool_size => 3, attributes => { pg_enable_utf8 => 1 } }

The connect options an embedding sync storage hands this backend beside the
broker (L<DBIO::Storage::DBI/connect_info>, ADR 0030 addendum),
split into C<pool_size> and the DBD C<attributes>; C<undef> for any other
form. L</connect_info> calls it after the DBIO-private keys are stripped
centrally (C<_strip_private_connect_attrs>), so C<async>, the storage and
SQL maker options and C<ignore_version> are gone by then: the owning storage
applies those.

Taking the options is a promise a transport makes by declaring
C<broker_connect_options> (L</transport_capabilities>): C<pool_size> sizes its
pool, which L</connect_info> does here, and the transport merges the DBD
attributes (L</_access_broker_call_attributes>) into every connection it
opens, as it treats the same keys in DBI-form connect info -- as far as its
client library can express them. An attribute the client cannot express (the
C<ev> transports have no DBD, so none of the DBD attributes reaches it) is not
applied to the pooled connections; it stays readable through
L</_access_broker_call_attributes> only. A transport that does not declare the
capability would drop everything, so any non-empty options throw.

=head2 _access_broker_call_attributes

  my $attrs = $storage->_access_broker_call_attributes;

The DBD attributes the connect options beside the broker carried
(L</_access_broker_call_options>), or an empty hashref. A transport declaring
C<broker_connect_options> merges them into the attributes of every connection
it opens from the broker's answer, with
C<< $self->_merge_access_broker_settings($answer_attrs, $self->_access_broker_call_attributes) >>
-- the one rule the sync storage applies too: a setting given both there and
in the broker's answer must have the same value in both, or it throws.

=head2 _access_broker_pool_size

  my $pool_size = $storage->_access_broker_pool_size($answer, $beside);

The pool size a broker-backed backend is given, or C<undef> when it is given
none and the pool keeps its default. C<$answer> is the broker's answer as
C<_current_async_connect_info> returns it, C<$beside> what
L</_access_broker_call_options> made of the options beside the broker, if
any.

The answer gives a pool size as its own C<pool_size> key when it is a hash of
connection parameters, and among its attributes when it is DBI-form --
C<< [ $dsn, $user, $password, \%attrs ] >>, as L<DBIO::AccessBroker::Vault>
answers with C<pool_size> in its C<dbi_attrs>. The owning sync storage keeps
that attribute out of its own C<< DBI->connect >> once the connection has an
async mode; here it sizes the pool. Given both in the answer and
beside the broker, the two must be the same value, or this throws naming
C<pool_size> -- the rule every setting beside a broker follows
(C<_merge_access_broker_settings> on L<DBIO::Storage>, ADR 0030 addendum).

L</connect_info> sizes the pool with it; a transport that overrides
L</connect_info> calls it to size its pool the same way.

=head2 _core_read_capabilities

  DBIO::Storage::Async->_core_read_capabilities;

The names in L</transport_capabilities> that core reads itself and layers do
not: currently C<broker_connect_options>. The layer gate in
L<DBIO::Storage::DBI> refuses a layer whose
C<required_transport_capabilities> names one, on every transport. This is the
one place the list is kept.

=head2 _takes_broker_connect_options

  $transport_class->_takes_broker_connect_options;

True when the transport declares C<broker_connect_options> in
L</transport_capabilities>. Asked by C<_async_storage> in L<DBIO::Storage::DBI>
before it hands the transport C<< [ $broker, \%options ] >>, and by
L</_access_broker_call_options>.

=head2 _current_async_connect_info

  my $info = $storage->_current_async_connect_info($mode);

The connect info a new connection is opened with, for
C<_normalize_async_connect_info> to split: with a broker attached, the
broker's answer as it stands now -- asked again on every call, a hash of
connection parameters paired with an empty options hash -- and otherwise the
static conninfo/options pair L</connect_info> stored. L</connect_info> asks it,
and so does a transport building each pool connection's conninfo in
L</_async_broker_conninfo>.

With a broker attached, only its current answer will do. A broker that answers
nothing -- C<undef>, an empty hash or array, a false value -- throws, naming the
broker class and the shape of the answer, never a value. Taking the
stored conninfo in its place would open the connection with the credentials of
an earlier answer, which the broker may just have rotated out, or of the
storage's previous connection, or with none. The refusal is
L<DBIO::Storage/current_access_broker_connect_info>'s, the one place every
storage asks the broker. A broker that throws is left to throw.

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo($info);

DB-specific connect-info conversion seam, applied before broker detection.
Defaults to an identity pass-through; a driver whose connect info needs
reshaping (e.g. DSN string to libpq hashref) overrides it.

=head2 async_option_names

  package DBIO::MyTransport::Storage;
  use base 'DBIO::Storage::Async';

  sub async_option_names { qw( statement_timeout max_in_flight ) }

Class method. The names of the connect options this backend takes in addition
to the core's, as a list; the default is the empty list. It is asked of the
backend class of the connection's async mode when the owning storage reads the
connect info, before any backend object exists and without connecting, so it
answers from the class alone. Each name given is then

=over 4

=item * kept out of the owning storage's C<< DBI->connect >> and out of the
connect info the transport's reshape seam (L</_normalize_conninfo>) sees,

=item * delivered to the backend, in the hash beside the connection, in a
hash-form connection (C<< { dsn => ..., statement_timeout => 5 } >>), in the
attribute hash of the DBI form, and in the options beside an AccessBroker
(C<< [ $broker, { statement_timeout => 5 } ] >>, with no
C<broker_connect_options> to declare),

=item * and readable from L</async_option> under its name, the value as the
caller gave it. An option given as C<undef> counts as not given.

=back

The backend validates its own names; core validates the core's. A transport that
overrides L</connect_info> keeps this by calling C<_strip_private_connect_attrs>
on the raw connect info first, as core's C<connect_info> does.

=head2 declared_async_option_names

  my @names = DBIO::MyTransport::Storage->declared_async_option_names;

Every async option the backend takes: the core's followed by its
L</async_option_names>, each once.

=head2 async_option

  my $timeout = $storage->async_option('statement_timeout');

The value the connection was given for the async option C<$name>, or C<undef>
when it was given none. The options are those of L</connect_info> as it was
called last: a new C<connect_info> starts from none. C<pool_size> is read by
the transport from the conninfo (C<_normalize_async_connect_info>) and is not
answered here.

=head2 _delay

  my $f = $storage->_delay($seconds);

Transport seam: a Future that resolves after C<$seconds>, from the event loop
and never synchronously. It is the timer of C<acquire_timeout>
(L<DBIO::Storage::PoolBase/new>) and of C<txn_timeout> (L</txn_do_async>). The
default asks L</_listen_delay>, which every transport of the family implements for
its reconnect backoff, so a transport that listens has a timer already; a
transport with another timer overrides this one. Core cancels the Future when the
wait it timed is over before the time is, if the Future can C<cancel>; a Future
that cannot be cancelled just fires with nothing left to do.

A transport with neither seam fails every acquire that has to wait, naming
C<_listen_delay>, unless it is given C<< acquire_timeout => 0 >>.

=head2 _owner_storage

  $async->_owner_storage($sync_storage);   # setter
  my $sync = $async->_owner_storage;       # getter

The sync L<DBIO::Storage::DBI> instance that built this embedded async backend
(set by C<_async_storage> in L<DBIO::Storage::DBI>). Held B<weakly> -- the sync storage
owns the async backend (it caches it in C<_async_storage_obj>), not the reverse,
so a strong ref here would be a cycle. This back-reference is what lets the pool
resolve C<connect_call_*> methods on the class that actually defines them.

=head2 _effective_owner_storage

  my $owner = $async->_effective_owner_storage;

The storage that prepares SELECT arguments (C<_prepare_select_args_async>) and
anchors async-context ownership
(L<DBIO::Storage::Async::TransactionContext>/L<DBIO::Storage::Async::PipelineContext>)
for this backend.

When an embedding sync storage wired itself as the owner
(C<_async_storage> in L<DBIO::Storage::DBI>, the C<< { async => $mode } >> connect
path), that owner is returned unchanged. But a backend used as a B<primary>
storage -- constructed directly at the driver level with no embedding sync
storage, as the native C<ev> backends are (C<< DBIO::PostgreSQL::EV::Storage->new(undef) >>
plus C<connect_info>) -- has no wired owner and could otherwise neither prepare
a SELECT nor prove context ownership (ADR 0051). In that case the
backend provisions and B<owns> a private sync sibling
(C<_build_self_owner_storage>).

=head2 _setup_pool_connection

  $async->_setup_pool_connection($conn);

Run the owning sync storage's C<on_connect_call> / C<on_connect_do> against the
freshly spawned pool connection C<$conn>. Invoked centrally from
C<_spawn_connection> in L<DBIO::Storage::PoolBase>. Resolves the actions (and any
C<connect_call_*> methods) on L</_owner_storage> but executes each emitted
statement against C<$conn> via L</_run_pool_connect_statement>. Each statement
is traced like the sync path traces a connect action: L</_debug_query> with the
text in its fingerprint form (a secret shows as C<***[sha256:E<lt>8 hexE<gt>]>)
from level 1 on, C<query_end> after the statement succeeded, nothing at level
0; the row queries of a C<connect_call_*> (C<dbio_rows>) are not traced. The
trace sits in the runner core hands the owner, so a backend that overrides
L</_run_pool_connect_statement> gets it too. A no-op when no
owner is wired (e.g. a standalone pool).

=head2 _teardown_pool_connection

  $async->_teardown_pool_connection($conn);

Symmetric counterpart of L</_setup_pool_connection>: run the owning sync
storage's C<on_disconnect_call> / C<on_disconnect_do> against C<$conn> while it
is still live. Invoked from L<DBIO::Storage::PoolBase/shutdown> before the
connection is closed.

=head2 _reset_pool_connection

  sub _reset_pool_connection {
    my ($self, $conn) = @_;
    return $self->_query_async_pinned($conn, 'DISCARD ALL')->then(sub {
      return $self->_replay_connect_actions($conn);    # the transport's own
    });
  }

Transport seam, asked by L<DBIO::Storage::PoolBase/release> when a borrow ends
(a statement, a transaction after COMMIT or ROLLBACK, a pipeline). Returns a
Future that resolves when C<$conn> is a connection like a freshly spawned one:
every session setting of the borrower gone, and the connect actions
(C<on_connect_do>, C<on_connect_call>, the connection's schema) in effect again.
A Future that fails -- or does not resolve within C<reset_timeout> seconds
(default 10, C<0> for no limit) -- retires the connection, and the next borrower
gets a fresh one. Until it resolves the connection counts against the pool size
and no one is given it.

The default fails: a transport without a reset of its own gets a fresh
connection for every borrow. A transport whose server can reset a session
overrides this seam.

=head2 _run_pool_connect_statement

  $async->_run_pool_connect_statement($conn, $sql, $attrs, @bind);

Runner seam: execute one connection-action statement B<synchronously> (a
blocking C<do>) on the pool connection C<$conn>. The default handles the two
DBD-based connection shapes -- a bare do-capable DBI handle, and the
C<future_io> wrapper C<< { dbh => $dbh } >> -- and croaks on anything else. A
native backend (e.g. an C<EV::Pg> client) whose connection is neither overrides
this method to drive its own synchronous execution.

The reserved key C<dbio_rows> in C<$attrs> asks for the rows of the statement:
the runner then returns an array reference of rows (array references, as
C<selectall_arrayref> without a slice returns them), read with
C<< $dbh->selectall_arrayref($sql, undef, @bind) >> on the default shapes. The
key is not handed to DBI. Without it the runner executes the statement and
returns nothing. A backend that overrides this method returns the rows when
C<dbio_rows> is set, and nothing otherwise.

=head2 sql_maker

Returns the memoised SQLMaker instance, built from L</sql_maker_class> and
L</_sql_maker_args>.

=head2 sql_maker_class

Transport seam. The L<DBIO::SQLMaker> subclass this backend generates SQL
with. Must be overridden.

=head2 _sql_maker_args

Constructor args for L</sql_maker_class>. Defaults to an empty list; a
backend overrides it to set e.g. C<quote_char> / C<name_sep>.

=head2 transport_capabilities

  my @caps = $backend_class->transport_capabilities;

Class method. The list of named capabilities this transport provides -- the
formal expression of "as far as the transport allows". Async storage extension
layers declare what they need with C<required_transport_capabilities>, and
C<_async_storage> in L<DBIO::Storage::DBI> refuses to compose a layer onto a transport
that is missing a required capability (it croaks naming the gap rather than
silently dropping the feature). The base transport declares none; a concrete
transport overrides this to advertise what it supports (e.g. C<on_connect_replay>,
C<listen>, C<notify>, C<copy>, C<pipeline>).

C<broker_connect_options> is read by core rather than by layers (see
L</_core_read_capabilities>): an async layer that lists it in
C<required_transport_capabilities> is refused on every transport. A transport
declaring it takes the connect options an embedding sync storage was given
beside an L<DBIO::AccessBroker> -- C<< [ $broker, \%options ] >> -- and
applies them to every connection it opens: C<pool_size> to its pool (done by
L</connect_info>), the DBD attributes (L</_access_broker_call_attributes>)
as it treats the same keys in DBI-form connect info, to the extent its client
library can express them. A transport whose client is no DBD (the C<ev>
transports) cannot: those attributes never reach the client library and stay
readable through L</_access_broker_call_attributes> only. Without the capability, a
broker-backed connection whose options carry DBD attributes or C<pool_size>
refuses this transport (C<_async_storage> in L<DBIO::Storage::DBI>, ADR 0030
addendum).

An async layer that declares B<no> C<required_transport_capabilities> at all is
not unchecked: it is taken to require the default query seam L</_query_async>,
because that is what a layer wraps. A transport that does not override the
abstract L</_query_async> -- one that does not own the query path, such as a
backend overriding the six C<*_async> entry points directly -- therefore refuses
such a layer too, rather than composing it into doing nothing. A layer that
genuinely needs nothing from the transport says so with an explicit empty
C<required_transport_capabilities>; only silence is read as needing the seam.

=head2 select_async

  my $future = $storage->select_async($source, $select, $where, $attrs);

Execute a SELECT asynchronously on a freshly-acquired pooled connection.
Returns a L</future_class> that resolves with the raw result rows
(arrayrefs, matching the sync cursor shape).

=head2 select_single_async

Like L</select_async> but resolves with only the first row (or C<undef>).

=head2 insert_async

  my $future = $storage->insert_async($source, \%vals);

Resolves with the B<returned-columns hashref> -- the supplied insert data
overlaid with the columns the database populated (autoinc primary key plus any
retrieve-on-insert columns), exactly the shape sync L</insert> returns (ADR
0031 §3). This is what the core C<create_async> / C<< DBIO::Row->insert_async >>
fold back into the new result object. (Unlike L</select_async> and
L</select_single_async>, which resolve raw row arrayrefs matching the sync
cursor shape.)

A column marked C<< auto_nextval => 1 >> that has no value in C<\%vals> is
refused with an exception, before any statement is built: the synchronous
insert fetches the next sequence value for it, the asynchronous one does not,
and sending the INSERT without the column would leave it NULL or end in a
NOT NULL error from the server. Give the column a value (literal SQL such as
C<< \"nextval('seq')" >> counts), or insert synchronously.

=head2 update_async

  my $future = $storage->update_async($source, \%vals, \%where);

Resolves with the B<affected-row count> (a plain scalar) -- exactly what
sync L</update> returns, and what L<DBIO::Row/update_async> relies on to
detect a zero-row ("row not found") or multi-row ("updated more than one
row") result exactly like sync C<_update_body> does. This is a distinct
resolution shape from L</select_async>/L</select_single_async> (raw row
arrayrefs) and L</insert_async> (a returned-columns hashref): update/delete
have no row data to speak of, only a count. B<Transport authors:> your
L</_query_async> implementation must resolve this count as its sole value
for update/delete SQL -- see L</_query_async>'s own POD.

=head2 delete_async

  my $future = $storage->delete_async($source, \%where);

Resolves with the B<affected-row count>, the same contract as
L</update_async> above.

=head2 _run_crud

  my $future = $storage->_run_crud($op, $runner, @args);

The shared CRUD builder every C<*_async> CRUD method routes through. C<$op>
is C<select>, C<select_single>, C<insert>, C<update> or C<delete>; C<@args>
are that method's arguments; C<$runner> is a coderef taking
C<($sql, \@bind, \@bind_attrs)> and returning a Future of the transport's result.

It builds the SQL with L</sql_maker> -- a SELECT is prepared through the owning
sync storage's C<_select_args> first, so validation, join pruning and the
complex-prefetch rewrite match the sync cursor -- hands it to
C<$runner>, and shapes what the runner resolves to per op (ADR 0031 §3):
C<select> the raw row arrayrefs, sliced by C<offset>/C<rows> under
C<software_limit>; C<select_single> the first row or C<undef>; C<insert> the
returned-columns hashref sync C<insert> returns (L</_post_insert_sql> appended
to the SQL, the row mapped by C<_insert_returned_columns>); C<update> and
C<delete> the affected-row count. An unknown C<$op> croaks.

Each rendering of an insert, update or delete gets a flat copy of the options
hash of the call, so a driver SQL maker that consumes keys of it (C<on_conflict>,
C<insert_or>) leaves the options of the caller as given, and the rendering that
resolves the bind attributes sees the same statement as the one on the wire.

The SQL reaches the runner as raw L</sql_maker> output with C<?>
placeholders; any dialect shaping is the query seam's own (ADR 0032).

The binds reach the runner as bare values. For a select the values of the C<bind> attribute (placeholders in a literal
C<from>, C<select> or C<where>) stand in front of the binds of the SQL maker, in
the order of the sync path. The sync
convention hands a literal bind -- a subquery from C<as_query> -- over as a
pair C<[ \%attrs =E<gt> $value ]>; the builder takes the pair apart by the rule
of the sync path (L<DBIO::Storage::DBI/_resolve_bindattrs>) before the runner
sees it: a two-element arrayref with a HASH or C<undef> in front is a pair, and
the value is its second element. A plain bind value of exactly that form is
therefore read as a pair; any other shape is passed as it is.

The third argument of the runner, C<\@bind_attrs>, is the bind attributes of
the statement: an arrayref of attribute hashes parallel to C<\@bind>, resolved
by the rule of the sync path (C<dbic_colname>, C<sqlt_datatype>, and C<redact>
for an C<encode_column> column), so the trace shows what the sync trace shows.
They carry no value. Only a trace at level 2 or more reads them, so only then
are they built, and C<undef> stands in when they are not (or do not line up
with the binds).

Two runners exist, so both paths share this one builder: the pooled runner
behind the public C<*_async> methods runs each statement through
L</_query_async> on a connection of its own; C<_run_crud_pinned($op, $conn,
@args)> runs it through L</_query_async_pinned> on C<$conn> and does not
release it -- the entry point of L<DBIO::Storage::Async::TransactionContext>
and L<DBIO::Storage::Async::PipelineContext>. See also
L<DBIO::Manual::AsyncStorage/"What _run_crud builds for you">.

=head2 _debug_query

  my $end = $storage->_debug_query($sql, $bind, $bind_attrs);
  ...
  $end->() if $end;

The one trace rule of every async transport (ADR 0025). The level comes from
C<debug> (L<DBIO::Storage/_trace_level_of>): C<0> traces nothing and returns
C<undef>; C<1> traces the statement alone; from C<2> on the bind values follow.
Each value is run through the C<redact_bind_value> hook of the owning sync
storage (L</_owner_storage>; the class-level hook of L<DBIO::Storage::DBI>
without one) as C<< $hook->($column_name, $value, $attrs) >> and the result is
cut to 32 characters, with C<...> marking the cut; C<undef> is traced as
C<NULL>, as the sync storage does (L<DBIO::Storage::DBI/redact_bind_value>).

C<$bind_attrs> is optional: an arrayref of bind attribute hashes parallel to
C<$bind>, as L</_query_async> receives it. The column name is the
C<dbic_colname> of an attribute hash; a statement without attributes -- a raw
one such as C<BEGIN> -- gives the hook C<undef> for name and attributes. The
attributes carry no value and are not kept.

The statements of the connect and disconnect actions of a pool connection
(L</_setup_pool_connection>) are traced through this method in the fingerprint
form of their text (C<mask_statement_fingerprint>), so a secret shows as
C<***[sha256:E<lt>8 hexE<gt>]>; their row queries (C<dbio_rows>) are not traced.

C<query_start> goes to the C<debugobj> of the owner (this storage's own without
one). The return value is a coderef that calls C<query_end> for the same
statement; a transport that times its statements calls it when the statement
has settled, one that does not ignores it.

=head2 _query_async

  my $future = $storage->_query_async($sql, $bind, $bind_attrs);

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready. Must be overridden by a backend.

For C<select>/C<select_single>/C<insert> SQL, returns a L</future_class> of
the raw result rows (row arrayrefs for select, RETURNING row(s) for insert --
see L</insert_async>). For C<update>/C<delete> SQL, there is no row data:
this seam must instead resolve with the B<affected-row count> as its sole
value (see L</update_async>/L</delete_async>) -- typically the same scalar a
synchronous C<< $dbh->do($sql, ..., @$bind) >> (or equivalent execute-and-
count call) would return, not a fetched cursor result. A transport that
naively tries to "fetch rows" for a plain UPDATE/DELETE with no C<RETURNING>
clause will find none, and resolving an empty list here silently breaks
L<DBIO::Row/update_async>'s row-count check (it inspects the scalar to detect
a vanished row: C<0> throws "row not found", C<< >1 >> throws "updated more
than one row"). L<DBIO::Row/delete_async> resolves the same count for
interface uniformity but does not currently inspect it -- matching
synchronous C<delete>, which is a no-op on an already-absent row -- so a
transport must still resolve the count scalar (not an empty list) for both
ops. (See this dist's PR body/Changes for the async-parity-helpers work that
first exercised this seam for update/delete; tracked as a cross-repo driver
ticket, same pattern as the L</insert_async> returned-columns shape in ADR
0031 §3).

B<Bind-value contract:> C<$bind> is an arrayref of bare bind
values, one per C<?>, never of C<[ \%attrs =E<gt> $value ]> pairs. Core unpacks a
pair (what a subquery's C<as_query> carries) before it reaches the seam, by the
rule of the sync path's C<_resolve_bindattrs>: a two-element arrayref with a
HASH or C<undef> in front is read as a pair. A bind value of exactly that form
is therefore taken as a pair too; a transport hands each element to the wire
as it is and does not look inside.

B<Bind attributes:> C<$bind_attrs> is optional: an arrayref of bind attribute
hashes parallel to C<$bind> (one per bind; C<dbic_colname> names the column),
or C<undef>. A statement core did not build -- C<BEGIN>, C<COMMIT>,
C<ROLLBACK>, C<DISCARD ALL>, a raw call -- has none. The attributes are for
L</_debug_query>, which a transport calls with all three arguments; they carry
no value, and the bind-lifetime rule below applies to C<$bind> alone.

B<Placeholder-dialect contract (ADR 0032):> the C<$sql> handed to
this seam is B<always> raw L<DBIO::SQLMaker> output -- the C<sql_maker> dialect
with C<?> placeholders. A transport that needs a different placeholder syntax
(e.g. C<$1>/C<$N> for PostgreSQL) MUST apply that shaping B<internally>, in its
own implementation of this seam, via L</_transform_sql> or an equivalent. The
seam contract is C<?>-in; dialect-out is the transport's private business. Core
does not pre-shape the SQL for the transport.

B<Bind lifetime -- build no callback inside the C<then> closure (ADR 0044):>
the connection is not in hand until L<DBIO::Storage::PoolBase/acquire>
resolves, so this seam's body lives inside a C<< ->then(sub { ... }) >> --
which makes it a B<closure over C<$bind>>. Any anonymous sub created I<inside>
that closure (the completion callback, the C<on_ready> that returns the
connection to the pool) keeps a strong C<CvOUTSIDE> pointer to it and therefore
keeps its whole pad alive, C<$bind> included, even though the callback never
mentions C<$bind>. The bind arrayref then stays reachable for the entire flight
of the query.

That is not the contract. A bind arrayref's life ends when the statement is
B<dispatched> to the transport: by the time C<query_params> / C<execute> has
returned, the values are in the transport's own wire buffer, and nothing on the
Perl side may keep the arrayref reachable afterwards. So build every callback
the transport will hold in a B<named> sub that takes what it needs as
arguments -- a named sub's pad is not a closure pad, so the callback cloned
inside it captures only what it references:

  # WRONG -- the on_ready sub pins the then closure's pad, and $bind with it
  my $pool = $self->pool;
  return $pool->acquire->then(sub {
    my $conn = shift;
    my $lease = $pool->_lease($conn);
    return $self->_await_query_result($conn, $sql, $bind)
      ->on_ready(sub { $pool->release($conn, $lease) });
  });

  # RIGHT -- built in a named sub; the then closure is freed once it has
  # fired, and $bind goes with it
  sub _release_on_ready {
    my ($self, $conn, $pool, $lease) = @_;
    return sub { $pool->release($conn, $lease) };
  }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    my $pool = $self->pool;
    return $self->_hold_derived($pool->acquire->then(sub {
      my $conn = shift;
      my $lease = $pool->_lease($conn);
      my $f = $self->_seam_future(_await_query_result => $conn, $sql, $bind);
      $f->on_ready($self->_release_on_ready($conn, $pool, $lease));
      return $f;
    }));
  }

The release goes to C<$pool>, the pool the connection was acquired from, handed
to the named sub along with the connection -- not to C<< $self->pool >> asked
again when the query settles. L</pool> builds lazily, and
a query that settles after its storage was disconnected would build a new pool
there, only to release into it a connection that pool never held. The same
goes for everything else a settled query tells a pool, a dead connection
(L<DBIO::Storage::PoolBase/_mark_connection_dead>) included.

The release carries the lease of its borrow, taken with
L<DBIO::Storage::PoolBase/_lease> right after the acquire resolved. A release
that arrives after the connection was handed to another caller -- a callback
that fires twice, a cancel racing a settle -- is then told from its current
holder's and is a silent no-op. Without a lease the pool cannot tell, and the
second release is taken as the holder's.

Dispatching through L</_seam_future> is part of the pattern. The release hangs
off the query Future, and that Future exists only once dispatch has returned.
A transport whose C<prepare> or C<query> croaks synchronously -- I<another
operation is in progress>, I<not connected> -- never gets that far, so without
it the connection stays checked out, and a pool of N is wedged for good after
N such calls. As a failed Future the die takes the same C<on_ready> release as
every other outcome, and the caller sees the dispatch's own error. A dispatch
that returns no Future at all fails the same way, with an error naming the
seam.

The C<then> closure still closes over C<$bind> -- it must, to issue the query
-- but it is released the moment it has fired, so the retention window is
"until the acquire resolves", not "the flight of the query". A transport that
genuinely needs the values after dispatch (tracing, retry-on-reconnect) takes
its B<own copy> and says so; it does not keep the caller's arrayref alive by
accident, and it does not mutate it either -- the array belongs to the caller.

B<The Future derived from the wait on the pool holds itself:> what C<<
$pool->acquire->then(sub { ... }) >> returns is the Future this seam hands its
caller, and it is a sequence of the acquire Future, which holds it only
weakly. It is kept alive until it is ready -- done, failed or cancelled -- by
handing it to C<_hold_derived>, which retains it when the Future class has
C<retain> and lets go of it once it is ready. A caller who holds the Future
sees no difference; one who does not -- a statement sent in void context, one
dropped inside a pipeline batch -- still gets the body run and the connection
back in the pool when it is free. The rule holds for every seam that waits on
the pool and hands the Future derived from that wait to a caller:
L</pipeline>, the pooled branch of L</deploy_async> and a pooled DDL run
follow it in core.

=head2 _seam_future

  my $f = $self->_seam_future(_await_query_result => $conn, $sql, $bind);

Call the Future-returning seam C<$method> with C<@args> and return its
Future -- or a failed one, so a caller can always hang the connection's
release off the result. A seam that dies becomes a Future
failed with its error. One that returns no Future at all -- C<undef>, a plain
value -- becomes a Future failed with an error naming the backend class and the
seam. The guard it replaces,
C<< eval { ... } // $fc->fail($@) >>, failed that case with the empty C<$@> of
an C<eval> that did not die: an empty error under L<DBIO::Test::Future>, and
under L<Future>, which refuses a false exception, a die in the caller that
skipped the release.

A named method rather than a closure, so it keeps none of the caller's
variables alive past the call (ADR 0044).

=head2 _query_async_pinned

  my $future = $storage->_query_async_pinned($conn, $sql, $bind, $bind_attrs);

Transport seam. Like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction. Must be overridden by a backend.

The same placeholder-dialect contract and per-op resolution-shape contract
(raw rows for select/insert, affected-row count for update/delete) as
L</_query_async> apply here too: C<$sql> arrives as raw C<sql_maker> output
with C<?> placeholders, and any dialect shaping is the transport's own
internal responsibility.

The bind-value contract of L</_query_async> (bare values, a pair already
taken apart) and its optional C<$bind_attrs> (parallel to C<$bind>, no value,
none for a raw statement) apply here too, and so does the bind-lifetime rule
(ADR 0044), unchanged: the attributes carry no value, so the rule concerns
C<$bind> alone. Build
no callback inside a closure that captures C<$bind>. This seam is handed a
connection rather than acquiring one, so its body need not be a C<then> closure
at all -- but the moment it wraps one, the same trap is back.

=head2 _await_query_result

Transport seam (loop-specific). Submit a query on a connection and resolve
with its result rows once the wire is readable. Used by a backend's
L</_query_async> implementation. Must be overridden by a backend that routes
through this layer.

=head2 _await_conn_ready

Transport seam (loop-specific). Resolve with C<$conn> once it is ready for
queries. Must be overridden by a backend that routes through this layer.

=head2 _transform_sql

Transport-B<internal> helper (ADR 0032). DB-specific SQL shaping
(e.g. C<?E<gt>$N> placeholder rewriting for PostgreSQL, identity for MySQL).

This is B<not> a general seam any more: it is private to a transport's own
implementation of the query seams (L</_query_async> /
L</_query_async_pinned>), which receive raw C<sql_maker> output with C<?>
placeholders and shape it internally. No caller B<outside> a transport
implementation may invoke it -- core orchestration (C<_run_crud>) hands the
transport C<?>-dialect SQL and leaves the shaping to the seam. A transport that
needs shaping overrides this; one that does not (its wire speaks C<?>) may leave
the croaking default in place and never call it.

=head2 _post_insert_sql

Transport seam. SQL appended to an INSERT to retrieve the populated columns
(e.g. C< RETURNING *> for PostgreSQL, empty for a last_insert_id backend).
Must be overridden.

=head2 txn_do_async

  my $future = $storage->txn_do_async(sub {
      my ($txn_ctx) = @_;
      # All queries in here use the same connection
      $txn_ctx->insert_async(...)->then(sub { ... });
  });

Acquire a connection from the pool, issue BEGIN, execute the coderef, and
issue COMMIT on success or ROLLBACK on failure (a raised exception or a
failed Future). The coderef receives a
L<DBIO::Storage::Async::TransactionContext> (see L</_txn_context_class>)
whose CRUD methods are pinned to the transaction connection.

With an L<DBIO::AccessBroker> attached that is not transaction-safe -- one
whose credentials rotate, such as L<DBIO::AccessBroker::Vault> -- no
transaction is started (L<DBIO::AccessBroker/TRANSACTION SAFETY>). The
returned Future fails with the refusal the synchronous
L<DBIO::Storage/txn_begin> throws, before a connection is taken from the pool;
the coderef does not run. C<DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS=1> lets the
transaction run, with a warning at each transaction start. L</deploy_async>
runs transactional DDL through this method and is refused with it.

A returned Future is adopted: the transaction commits when it resolves and
resolves with its values. Anything else the coderef returns is the result
as-is -- a plain scalar, an object that is not a Future, or an unblessed hash
or array reference such as the returned-columns hashref of
C<< $txn_ctx->insert >>: C<COMMIT> is sent and the transaction resolves with
that value.

Success of the coderef is not enough to send C<COMMIT>. The
context keeps the Future of every statement it hands out
(L<DBIO::Storage::Async::TransactionContext/_track_statement>), and
C<COMMIT> goes out only once all of them have settled -- a statement nobody
awaited, still in flight when the coderef's result is in, is waited for. If
any of them failed, C<COMMIT> is not sent: C<ROLLBACK> is, and the transaction
fails with the error of the first statement that failed, in the order they
were issued (with the C<ROLLBACK>'s error added, should that fail too -- see
below). That holds whether or not anything awaited the failed Future, and
also when the coderef caught the failure and returned normally: a failed
statement fails the transaction, on every engine. PostgreSQL has aborted the
transaction by then anyway -- it answers a C<COMMIT> there with the tag
C<ROLLBACK>, not with an error -- and the async layer has no savepoint that
would give "carry on after a failed statement" a meaning. A statement Future
that was cancelled before it was answered counts as failed: its outcome is
unknown. After C<COMMIT>, the transport may still report that the server
rolled back (L</_txn_commit_rolled_back>); the transaction then fails too.

After a successful acquire, every terminal transaction path converges on one
finalizer: any context that was constructed is invalidated B<before> the
connection is released, and the pool's C<release> is called exactly once. If
the context constructor itself throws, there is no context to invalidate; the
same finalizer still releases once and returns that throw as a failed Future.
An acquire failure releases nothing. A completed context reports C<in_txn>
false and refuses direct CRUD, raw-query and nested-transaction entry points
rather than issuing work on the returned connection.

The connection goes back to the pool it was acquired from. L</pool> is asked
once, as the transaction begins, and the finalizer talks to that pool. A
transaction that ends after a L</disconnect> -- it stood between two
statements when the storage was disconnected, and its coderef went on --
therefore hands back to a pool that is shut down, which takes it as a no-op,
and leaves the storage without a pool. Asked again at the end, L</pool> built
a new one on the disconnected storage.

A path that sends C<COMMIT> or C<ROLLBACK> ends the context earlier, as that
statement goes out. A statement issued on the context from
then on -- from a C<then> callback of a statement still in flight, say -- is
refused, where it would otherwise run after the transaction's end, outside it.

C<ROLLBACK> does not wait for a statement still in flight, so a context can
end before such a statement is answered. Its Future is kept until then all the
same (L<DBIO::Storage::Async::TransactionContext/_track_statement>): nobody
else may hold it, and L<Future> warns I<lost a sequence Future> about one that
is gone when its answer arrives.

A statement that failed with a L<DBIO::Exception::Server> -- the transport's
way of reporting a refusal by the server, with its C<sqlstate> (ADR 0062) --
fails the transaction with that same object, whether the coderef returned the
statement's Future, left it unawaited, handled it, or died with it, and
whether the statement ran on the context or in a C<pipeline> on it. Where core
puts text in front of an error (the next paragraph) the object stays an object:
a failed C<BEGIN>, C<COMMIT> or C<ROLLBACK> that is a
L<DBIO::Exception::Server> reaches the caller as a derived copy -- the same
class, C<sqlstate>, C<constraint>, C<table> and C<detail>, plus
L<DBIO::Exception::Server/context> (C<BEGIN>, C<COMMIT>, C<ROLLBACK>) -- that
stringifies with the prefix, so C<< $@ =~ /COMMIT failed/ >> and C<eq> keep
working and the SQLSTATE of a serialization failure at C<COMMIT> is readable. It
is not the object the transport failed with (C<refaddr> differs); an error that
is no such object stays the string it was.

Failures keep their prefixes: a failed C<BEGIN> Future is reported as C<BEGIN
failed: ...>, a failed C<COMMIT> Future as C<COMMIT failed: ...>, and a
synchronous query-seam throw after acquire becomes a failed Future rather than
escaping C<txn_do_async>. A failed C<ROLLBACK> -- its Future failed, or its
dispatch threw -- does not replace the error it was cleaning up after: the
transaction fails with a L<DBIO::Exception> reading C<Transaction aborted:
$error. Rollback failed: $rollback_error>, the text the synchronous
L<DBIO::Storage/txn_do> reports, so C</Rollback failed/> matches in every
async mode, C<immediate> included. Where the C<ROLLBACK>'s own failure is a
L<DBIO::Exception::Server>, that text is carried by a derived copy of it
(context C<ROLLBACK>) instead of a plain C<DBIO::Exception>. A release throw
replaces a successful terminal result, but is secondary to an already existing
transaction failure.

A pipeline run on the transaction that has not had its sync answered when the
block ends in failure holds the connection in pipeline mode.
C<ROLLBACK> is then not sent at once: it waits until that pipeline is over --
sync answered and pipeline mode left -- so it goes out on a connection that
takes it and the connection returns to the pool out of pipeline mode, never
idle in it. A pipeline that failed or was cancelled leaves the connection to
the rules below.

One state changes that ending: a pipeline run on the
transaction (L<DBIO::Storage::Async::TransactionContext/pipeline>) whose
L</_pipeline_exit> died leaves the connection in pipeline mode, where no
statement on it can be relied on to be answered. The transaction then waits
for nothing more on that connection. It fails -- with the error that ended the
batch, or, if the coderef handled that error and returned normally, with a
L<DBIO::Exception> saying C<COMMIT> was not sent -- and in place of the release
the finalizer sends a best-effort C<ROLLBACK> it does not wait for and retires
the connection from the pool
(L<DBIO::Storage::PoolBase/_retire_in_use_connection>): it is never handed out
again, and its slot goes to a fresh connection.

A transaction whose Future is B<cancelled> -- the only way a caller has to stop
waiting, such as the loser of a C<wait_any> against a timeout -- ends the same
way (ADR 0055 addendum). L<Future> runs none of the callbacks
above for a cancelled Future, so the cancel is answered on its own: a
C<ROLLBACK> goes out best-effort and is not waited for, the context is
invalidated, and the connection is B<retired> from the pool, never released
into it. What was in flight on it -- a statement, the C<BEGIN>, the
coderef's own work -- cannot be vouched for, and the cancel still reaches
it. Each cancel costs one reconnect: the slot goes to a fresh connection. It
happens once, however many ways notice the cancel (the transaction's Future,
the Future of the statement in flight, the finalizer). No C<ROLLBACK> is sent
where C<COMMIT> or C<ROLLBACK> is out already. B<A cancel while C<COMMIT> is
pending leaves the outcome unknown>: the transaction may have committed or
not, and the connection is retired either way. Cancelling the Future the
coderef returned, and not the transaction's, ends the transaction in the same
way and fails it with a L<DBIO::Exception> saying it was cancelled. A statement
Future of the context cancelled on its own, while the coderef goes on, is the
case described above: C<ROLLBACK> is awaited and the connection released.

No C<ROLLBACK> is sent on a connection the pool was told is dead
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), where it could only come
back as C<not sent>: the transaction fails with the
error that ended it, and the release retires the connection.

A C<COMMIT> the server refused (a L<DBIO::Exception::Server>) ends the
transaction whatever the server says (a deferred constraint is checked at
commit time); one the transport refused or that was cancelled does not: it
fails the transaction as before, with no C<ROLLBACK>. The context is over, a
C<ROLLBACK> goes out on the pinned connection and is waited for, and the
transaction fails with the error of the C<COMMIT>, never that of the
C<ROLLBACK>. If the C<ROLLBACK> works the connection is released
as usual; if it fails, or its dispatch throws, the connection is retired from
the pool, never handed back.

B<A transaction may be given a time limit>: the connect option
C<txn_timeout>, in seconds (a number above 0), without a default -- a
transaction without the option takes as long as its coderef does. The time is
counted from the call of C<txn_do_async>, the wait for a connection included.
When it runs out before the transaction is over, the transaction is cancelled
through the cancel path described above: C<ROLLBACK> goes out on its connection
best-effort and is not waited for, the context ends, the connection is retired
and its slot goes to a fresh connection. The Future C<txn_do_async> returned
B<fails> with C<transaction timed out after N seconds>; whether the work took
effect is unknown, as after any cancel. The timer is L</_delay>. The option needs
a Future class that can be cancelled (L<Future>); a storage whose class cannot be
answers every C<txn_do_async> with a failed Future saying so, before it takes a
connection. A transaction that ends first stops the timer.

=head2 _txn_commit_rolled_back

  my $rolled_back = $storage->_txn_commit_rolled_back($conn, @commit_result);

Transport seam. Asked when the C<COMMIT> of a
L</txn_do_async> transaction has succeeded on the wire -- from that Future's
success callback, before anything else runs on C<$conn> -- with the pinned
connection and the values the C<COMMIT> Future resolved with. Answers true
when the server did not commit but rolled back. The default answers false:
the C<COMMIT> is taken at its word.

PostgreSQL is why it exists. A C<COMMIT> in an aborted transaction is not an
error there: it ends the transaction and answers with the command tag
C<ROLLBACK>. A PostgreSQL transport fills this seam from that tag -- L<EV::Pg>
has it in C<< $pg->result_meta->{cmd_status} >>, L<DBD::Pg> in the statement
attribute C<pg_cmd_status>. An engine whose C<COMMIT> fails when it cannot
commit leaves the default.

When it answers true the transaction fails with a L<DBIO::Exception> saying
so. No C<ROLLBACK> is sent -- the server has ended the transaction -- and the
connection is released as usual.

The transaction does not depend on this seam to notice a failed statement: it
waits for every statement its context handed out and refuses C<COMMIT> when
one failed (L</txn_do_async>). What the seam adds is the statement the context
never saw -- one sent on the connection past the context, or a pipeline
statement whose batch coderef dropped its failure.

=head2 _txn_inner_future

  my $future = $storage->_txn_inner_future($txn_ctx, $conn, $inner_future);

Driver seam. Asked by L</txn_do_async> once the coderef has
returned and its Future is known -- C<$inner_future>, the Future the coderef
returned (or an already done one wrapping a plain return) -- and before the
transaction chains COMMIT onto it. C<$txn_ctx> is the transaction context,
C<$conn> the pinned connection. It answers the Future the transaction adopts
in its place. It is not asked when the coderef died or the connection is
already unusable.

The default refuses an inner Future that waits in the queue of the
transaction's own pool, the case a transaction can never see
settle: the coderef returns the Future of a call on the STORAGE
(C<< $storage->select_async(...) >>, an unbound C<< $rs->all_async >>) instead
of one on C<$txn_ctx>. That call is not part of the transaction; it is queued
for a pool connection, and with C<pool_size> 1 -- or with as many transactions
open as the pool has connections -- the connection it waits for is one a
transaction holds, this one among them. The pool knows the Futures it queued
the storage's calls for and the aggregates made of them (C<needs_all> and its
kind, through C<pending_futures>;
L<DBIO::Storage::PoolBase/_queued_waiters_for>). The default takes each such
waiter out of the queue and fails it, so the statement behind it never runs,
and throws C<the coderef returned a Future queued for this transaction's own
pool; call it on the context>. That is the coderef dying: ROLLBACK goes out
and L</txn_do_async> fails with that message, the connection goes back to the
pool. A Future the caller derived with C<< ->then >> from such a Future is the
caller's own and is not known to the pool: call the storage's statements on
the context, and chain what follows on the context's Futures.

A driver overrides the seam to refuse more, or to refuse in its own way, and
calls C<< $self->next::method(@_) >> to keep the default.

A failed Future (the one passed in, once refused, or another) takes the normal
error path: ROLLBACK is sent, L</txn_do_async> fails with exactly that
failure, and the connection goes back to the pool. Throwing is the same as the
coderef dying: ROLLBACK, then the transaction fails with the exception (no
ROLLBACK when the connection is unusable). A return that is not a Future is
ignored and C<$inner_future> is used.

=head2 _txn_context_class

The transaction-context class L</txn_do_async> hands to its coderef. Defaults
to the generic L<DBIO::Storage::Async::TransactionContext>, which knows the
pinned connection as C<txn_conn> only. A backend that overrides
L</_txn_conn_accessor> to another name therefore overrides this too, with a
context class that goes by that name: its C<new> takes the connection under
it, and it answers the connection to a method of that name.

=head2 _txn_conn_accessor

The name the L</_txn_context_class> knows the pinned connection by. Defaults
to C<txn_conn>. It is asked both ways: L</txn_do_async> passes the connection
to the context's C<new> under this key, and where core needs the connection
back from a context -- the transactional run of L</deploy_async> sends its
statements on it -- it calls the context's method of this name. Core never
reads C<txn_conn> as such: that used to be what L</deploy_async> did, so a
backend answering another name could not deploy.

=head2 pipeline

  my $future = $storage->pipeline(sub {
      my ($batch) = @_;
      my @futures;
      push @futures, $batch->insert_async('artist', { name => $_ })
          for @names;
      return $batch->future_class->needs_all(@futures);
  });

Execute multiple queries in pipeline mode for reduced round-trips. The
scaffold acquires a connection, brackets the batch with L</_pipeline_enter>,
L</_pipeline_sync> and L</_pipeline_exit>, and releases the connection --
however the batch ends, also when one of those seams dies; a connection whose
exit failed is retired from the pool instead (see L</_pipeline_on_conn>), and
so is one whose Future was cancelled before the sync was answered: whether the
batch took effect is unknown and the sync may still be answered on that
connection, so it never goes back into the pool. Both go to the pool the
connection was acquired from: L</pool> is asked once, as the batch begins, so
a batch that ends after a L</disconnect> builds no new pool on the
disconnected storage. The DB-specific pipeline mechanics are supplied by the
backend via those three seams; a backend that cannot pipeline simply does not
override them, and L</pipeline> then returns a failed Future naming the
transport before it touches the pool (see L</_pipeline_refusal>).

With an L<DBIO::AccessBroker> attached that is not transaction-safe -- one
whose credentials rotate, such as L<DBIO::AccessBroker::Vault> -- the batch is
refused like L</txn_do_async> (L<DBIO::AccessBroker/TRANSACTION SAFETY>): the
returned Future fails with the same refusal, before a connection is taken from
the pool, and the coderef does not run.
C<DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS=1> lets the batch run, with a warning.

The coderef receives a L<DBIO::Storage::Async::PipelineContext> (see
L</_pipeline_context_class>) B<-- not the storage>. Pipeline mode is
per-connection state, so a statement is only batched if it is sent on the one
connection the scaffold bracketed; the context's C<*_async> methods route
through L</_query_async_pinned> onto exactly that connection. Calling
C<< $storage->insert_async >> inside the batch instead goes through the pooled
path, takes a B<different> connection and runs outside the bracket -- so
issue in-batch queries on the object the coderef is handed. This mirrors how
L</txn_do_async> hands its coderef a
L<DBIO::Storage::Async::TransactionContext> for the same reason (dbio-async
ADR 0002 / ADR 0003).

Two limits worth knowing, both inherent to the batching shape rather than
gaps in the scaffold:

=over 4

=item * Only queries issued during the B<synchronous> run of the coderef are
batched. A query chained onto an in-batch Future (C<< ->then(sub { ... }) >>)
fires after the coderef has returned, i.e. after the sync -- it cannot join
the batch, and the context must not be used for it.

=item * The ResultSet/Row async layer (C<< $rs->all_async >> and friends)
resolves the B<pooled> backend unless it is bound to this context, so a bare
C<< $rs->all_async >> is B<not> batched even inside the coderef -- it takes a
different connection and runs outside the bracket. Bind it first
(L<DBIO::ResultSet/with_context>, ADR 0045) and every C<*_async> on that
resultset -- and on clones and rows made from it -- joins the batch. The
binding lasts only as long as the batch: the scaffold invalidates the context
when the coderef returns, and a bound resultset used after that throws instead
of silently re-issuing on a pooled connection. The context's own CRUD methods
batch either way.

=back

=head2 _pipeline_refusal

  if (my $failed = $storage->_pipeline_refusal) { return $failed }

Returns C<undef> when this transport can pipeline, otherwise a failed Future
carrying a L<DBIO::Exception> that names the transport class and says it does
not support C<pipeline()>. A transport can pipeline iff it overrides the
L</_pipeline_enter> seam -- the same seam probe the async layer gate uses for
C<_query_async>, not a C<transport_capabilities> name, so a pipelining
transport that does not advertise C<pipeline> keeps working. L</pipeline> and
L<DBIO::Storage::Async::TransactionContext/pipeline> ask it B<before> they
touch a connection, so a refusal takes nothing from the pool and sends nothing
on a transaction connection. Before that, the caller got the
bare seam's C<Subclass must override _pipeline_enter($conn)>, which is written
for transport authors.

=head2 _pipeline_on_conn

  my $future = $storage->_pipeline_on_conn($conn, $coderef, $release, $retire);

The pipeline scaffold on a connection the caller already holds: builds the
L</_pipeline_context_class> around C<$conn>, brackets the coderef with
L</_pipeline_enter> / L</_pipeline_sync> / L</_pipeline_exit>, and calls the
optional C<$release> coderef at each point where the bracket is finished with
the connection. L</pipeline> passes a release that returns its pooled
connection to the pool it acquired it from (and a C<$retire> bound to that
pool likewise -- neither asks L</pool> again);
L<DBIO::Storage::Async::TransactionContext/pipeline> passes none,
because the transaction connection belongs to the transaction boundary and must
stay pinned until C<COMMIT>/C<ROLLBACK>.

A die in the context constructor, a seam or the coderef comes back as a failed
Future carrying the error that ended the batch, and the connection is handed
back exactly once on every path. It goes back only when the sync, every
statement Future of the batch and the Future the coderef returned are decided;
a batch that fails sends no sync, fails every statement Future still open with
its error, and retires the connection instead of releasing it. Once pipeline
mode has been entered it is exited on every path too, best-effort: a dying
L</_pipeline_exit> skips neither the hand-back nor the original error, and its
own error is reported only when nothing else failed. On success the hand-back
waits for the L</_pipeline_sync> Future, as its obligation requires, and for
the statements and the returned Future after it.

A connection whose L</_pipeline_exit> died is still in pipeline mode, and the
next borrower could not use it (EV::Pg rejects a plain query there). On that
path alone the scaffold calls the optional C<$retire> coderef I<instead of>
C<$release>. L</pipeline> passes one that takes the connection out of the pool
for good through L<DBIO::Storage::PoolBase/_retire_in_use_connection>, so its
slot is freed and the next acquire gets a fresh connection. Without a
C<$retire>, C<$release> runs on that path too.

A batch Future cancelled while the bracket is open takes the same path:
L<Future> runs neither branch of the sync's completion, so the scaffold
answers the cancel itself and calls C<$retire>, once, without leaving pipeline
mode -- the connection is closed, not reused. A cancel after the bracket
finished does nothing; the connection was handed back then.
L<DBIO::Storage::Async::TransactionContext/pipeline> passes a C<$retire> that
only marks the transaction connection unusable: the transaction boundary then
retires it instead of releasing it (L</txn_do_async>).

=head2 _pipeline_context_class

The batch-context class L</pipeline> instantiates around the bracketed
connection and hands to its coderef. Defaults to the generic
L<DBIO::Storage::Async::PipelineContext>; a backend needing a different
pinned-CRUD surface for batches overrides this. Whatever it returns is
constructed with C<< storage => $self, pipeline_conn => $conn >>.

=head2 _pipeline_inner_future

  my $future = $storage->_pipeline_inner_future($batch, $conn, $inner_future);

Driver seam, the pipeline's counterpart of
L</_txn_inner_future>. Asked by L</_pipeline_on_conn> when the batch coderef
has returned a Future, C<$inner_future>, and before the batch waits on it.
C<$batch> is the pipeline context, C<$conn> the bracketed connection. It
answers the Future the batch adopts in its place; a return that is no Future
leaves C<$inner_future>.

The default refuses a Future that waits in the queue of the pipeline's own
pool, as L</_txn_inner_future> does for a transaction: such a Future is the
result of a call on the storage instead of on C<$batch>, it waits for a
connection while the pipeline holds one, and the pipeline would wait for it to
settle. The waiter is taken out of the queue and failed, so its statement never
runs, and the seam throws C<the coderef returned a Future queued for this
pipeline's own pool; call it on the context>. A throw is the coderef dying: the
batch fails with that message, no sync goes out, its open statements fail with
it and its connection is retired (L</_pipeline_on_conn>). Inside a
transaction's pipeline the transaction fails with the same message.

=head2 _pipeline_enter

Transport seam. Open pipeline/batch mode on the connection. Overridden by a
backend that supports pipelining.

=head2 _pipeline_sync

Transport seam. Flush the batched queries and resolve when the batch has been
sent/acknowledged. Overridden by a backend that supports pipelining.

B<Obligation:> it must not resolve before the individual batched result
Futures have been resolved off the connection. L</pipeline> exits pipeline
mode and releases the connection in this Future's completion, and only then
hands back the batch's own aggregate Future -- so a C<_pipeline_sync> that
resolves early puts the connection back in the pool while results are still
being read off it.

A C<_pipeline_sync> that dies instead of returning a Future is handled like one
that returned a failed Future: pipeline mode is exited and the connection
released, and the batch fails with the sync's own error.

=head2 _pipeline_exit

Transport seam. Close pipeline/batch mode on the connection. Overridden by a
backend that supports pipelining. The scaffold calls it best-effort: if it dies,
the connection is still handed back -- retired from the pool rather than
released, since it is still in pipeline mode.

=head2 listen

  my $f = $storage->listen($channel, sub {
    my ($channel, $payload, $sender_pid) = @_;
  });

Register C<$cb> for C<$channel> and subscribe the listen connection to it,
opening that connection first if this is the first channel. Returns a Future
that resolves once the subscription is in effect and fails if the attempt that
carries it fails. Where the transport's Futures can C<await>, C<< ->get >> on it
runs the event loop until then -- and so do the Futures of L</unlisten> and
L</listen_reconnect> (see L</Listen seams>). A failed Future does B<not>
unregister the channel when the connection died: the machinery keeps healing
and subscribes it on the next connection. A subscription the database rejects
on a healthy connection is dropped from the registry instead, and the Future
fails with the reason.

A second L</listen> on an already-registered channel replaces the callback and
issues no second subscribe. C<$sender_pid> is the transport's sender identity
(the PostgreSQL backend pid, or whatever an emulating transport records); it
may be C<undef>.

=head2 unlisten

  my $f = $storage->unlisten($channel);

Drop the callback for C<$channel> and unsubscribe it. When the last channel
goes, watching stops and the listen connection is closed. Returns a Future
that resolves once the unsubscribe has been sent (at once when there is
nothing to send). Unlistening a channel that is not registered is a no-op.

=head2 notify

  my $f = $storage->notify($channel, $payload);

Send a notification. Returns the Future of the transport's L</_notify_send>.
The payload travels as a bind value, never interpolated into SQL; C<undef>
means no payload. Needs the C<notify> capability, not C<listen>: sending does
not use the listen connection.

=head2 listen_alive

  unless ($storage->listen_alive) { ... }

True when the listen connection is present, fully set up (every channel
subscribed, watching armed) and the transport's L</_listen_probe> says it is
alive. A failing probe is treated as a death report: self-healing starts, and
the method returns false. False while a reconnect is pending, when nothing is
being listened to, and in a forked child that has not opened its own
connection.

=head2 listen_reconnect

  my $f = $storage->listen_reconnect;

Force an immediate rebuild of the listen connection, for an external
watchdog: close the current connection (or cut a pending backoff short), open
a new one, subscribe every registered channel, re-arm, fire
L</on_listen_reconnect>. The backoff restarts from L</listen_backoff_initial>.
Returns a Future that resolves when the new connection is up and fails if
this attempt fails -- in which case self-healing carries on as usual. With no
channel registered there is nothing to rebuild and the Future is already
done.

=head2 _listen_open

  my $f = $storage->_listen_open;   # resolves with $conn

Open the dedicated listen connection -- a new one, B<not> from the pool -- and
resolve with it. C<$conn> is opaque to core; it is handed back to every other
listen seam. Open it with the storage's current connect info (a broker-backed
storage fetches fresh credentials here, as a pool spawn does) and B<fork-safe>
(DBD::Pg: C<< AutoInactiveDestroy => 1 >>), so that a child dropping its copy
of the handle leaves the parent's session alone.

=head2 _listen_close

  $storage->_listen_close($conn);

Close the listen connection. Called on a connection that may already be dead,
so it must tolerate that. Watching has been stopped first
(L</_listen_unwatch>) whenever it was started.

=head2 _listen_subscribe

  my $f = $storage->_listen_subscribe($conn, $channel);

Subscribe C<$conn> to C<$channel> (PostgreSQL: C<LISTEN>). The channel name
arrives exactly as the caller passed it: quoting or validating it before it
reaches the wire is the transport's obligation at this seam (ADR 0017 §3). An
emulating transport may implement this as purely local bookkeeping -- recording
a high-water mark, or nothing at all -- and return a done Future.

=head2 _listen_unsubscribe

  my $f = $storage->_listen_unsubscribe($conn, $channel);

The inverse of L</_listen_subscribe> (PostgreSQL: C<UNLISTEN>), with the same
quoting obligation and the same freedom to be local-only.

=head2 _listen_watch

  $storage->_listen_watch($conn);

Start delivering notifications from C<$conn>. From now until
L</_listen_unwatch>, the transport calls L</_listen_dispatch> once per
notification, in arrival order, and L</_listen_lost> as soon as it finds the
connection dead. Returns nothing; a throw counts as a dead connection, and a
watch that threw is not unwatched.

Core counts C<$conn> as watched from the moment it B<calls> this seam, so both
calls back into core may already happen from inside it -- a first drain of
notifications the client library buffered during the subscribe, say. A channel
callback run from there that unlistens the last channel or calls
L</listen_reconnect>, or a L</_listen_lost> report, then gets L</_listen_unwatch>
for C<$conn> -- while this seam is still on the stack -- before
L</_listen_close>.

B<How> the transport watches is its own choice, and both shapes fit this one
seam:

=over 4

=item * B<socket-driven> -- watch the connection's socket for readability,
drain every pending notification, watch again (PostgreSQL over Future::IO:
poll C<pg_socket>, drain C<pg_notifies>).

=item * B<timer-driven> -- for an engine with no server push, emulate: wait a
poll interval (typically through L</_listen_delay>), query the rows newer than
the connection's high-water mark in its subscribed channels, deliver them,
wait again. A failed poll query is a dead connection and goes to
L</_listen_lost>; a failed step that leaves the connection usable -- pruning
old rows, say -- goes to L</_listen_error>. Latency is the poll interval, and
a notification becomes visible when the transaction that wrote it commits --
the same on-commit delivery PostgreSQL gives. An emulation like this may
declare C<listen> and C<notify>, as long as its POD states those semantics.

=back

=head2 _listen_unwatch

  $storage->_listen_unwatch($conn);

Stop what L</_listen_watch> started: no further L</_listen_dispatch> or
L</_listen_lost> for C<$conn> after this returns (cancel the pending poll or
timer). A transport whose watching needs no teardown overrides this with an
empty method -- and says so.

=head2 _listen_probe

  my $alive = $storage->_listen_probe($conn);

Synchronous liveness probe: true when C<$conn> is still usable. False or a
throw means dead. Asked by L</listen_alive> and after a failed channel
operation, to tell a rejected statement from a lost connection.

=head2 _listen_delay

  my $f = $storage->_listen_delay($seconds);

A Future that resolves after C<$seconds> -- the reconnect backoff. Core has no
event loop, so the transport supplies the timer (Future::IO: C<sleep>). It must
resolve B<asynchronously>, from the loop; a synchronously resolved delay would
turn a persistent outage into unbounded recursion. Core cancels it (when the
Future can C<cancel>) if the wait is cut short.

=head2 _notify_send

  my $f = $storage->_notify_send($channel, $payload);

Send one notification and resolve when it has been dispatched. The payload
B<must> travel as a bind value (PostgreSQL: C<SELECT pg_notify($1, $2)>; an
emulating transport: an C<INSERT> with bound values), never interpolated into
SQL. C<$payload> may be C<undef>. Any connection may carry it -- typically a
pooled one; the listen connection is not required.

=head2 _listen_dispatch

  $storage->_listen_dispatch($channel, $payload, $sender_pid);

Called B<by the transport> while watching, once per notification. Core looks
the channel up in the registry and calls its callback in contract order. A
notification for a channel that is no longer registered is dropped. A callback
that dies is reported through L</on_listen_error>; delivery continues. Ignored
in a process other than the one that opened the connection.

=head2 _listen_lost

  $storage->_listen_lost($conn, $error);

Called B<by the transport> when it finds the listen connection C<$conn> dead.
Core closes it and starts self-healing. A report about a connection that is no
longer the current one (already replaced, or closed) is ignored, as is any
report in a process other than the opener.

=head2 _listen_error

  $storage->_listen_error($error);

Called B<by the transport> to report an error that does B<not> end the listen
connection -- a failed housekeeping step next to the notifications, say, such
as an emulating transport's retention cleanup. Core hands C<$error> to
L</on_listen_error> exactly as it reports its own errors: verbatim, without
a trailing newline; C<warn>ed when no hook is set; a hook that dies is itself
C<warn>ed. Nothing else happens: the connection stays up, no reconnect is
scheduled, no Future is settled, and L</listen_alive> answers as before. A
connection that is dead goes to L</_listen_lost> instead.

Ignored when this process is not listening -- in a forked child that has not
opened a listen connection of its own, and once listening has ended -- as a
L</_listen_dispatch> is. Returns nothing.

=head2 deploy_async

  my $future = $storage->deploy_async($schema, \%opts);
  $future->get;

Deploy C<$schema> asynchronously: generate the install DDL and execute every
statement over the async transport. The Future resolves on success or fails on
the first DDL error -- also when the transport dies dispatching a statement,
before it has a Future for it. Every connection taken from the pool goes back
to it either way -- to the pool it was taken from, which
L</pool> is asked for once, as the deploy begins, and not again for a later run
or as one ends: a statement in flight at a L</disconnect> releases into the pool
that was shut down, a no-op, and builds no new one. A
disconnect between two runs fails the deploy with C<storage disconnected during
deploy> rather than carrying on on a new pool; there is no resume.
The pool is asked between the statements of one transactional run as well:
found shut down there, the deploy fails with the same message, the run is
rolled back (C<ROLLBACK>, neither the rest of its statements nor C<COMMIT>)
and nothing more is sent on its connection. A statement in flight at the
L</disconnect> is not touched by this rule: it ends as the transport ends it.
A pool that does not answer L<DBIO::Storage::PoolBase/is_shutdown> counts as
not shut down. On a transactional engine
a transaction-safe run is rolled back on failure; on a non-transactional
engine, or on a statement the per-statement hook declares non-transactional,
no rollback applies (see L</Transactional-DDL discipline>).

A deploy whose Future is cancelled with a statement in flight ends as
L</txn_do_async> does: a transactional run gets a best-effort
C<ROLLBACK> and its connection is retired from the pool; a run on a pooled
connection outside a transaction, or on a non-transactional engine, has its
connection retired. Never released into the pool, and once; what the statement
did is unknown.

Once the Future has settled, nothing of the deploy holds the backend, its
connection or the statements: a backend that has deployed is freed when its
holder lets go of it, like any other. It used to stay for the life of the
process, with its pool and the connections in it -- the runs and the
statements were chained by a sub that called itself through its own variable,
and so held itself.

C<%opts>:

=over 4

=item add_drop_table => 1

Prepend C<DROP VIEW IF EXISTS ...> for every declared view and
C<DROP TABLE IF EXISTS ... CASCADE> for every table source in the schema
(L</_drop_statements_for>), so a re-run on a populated database is
idempotent. Default 0.

=back

=head2 _install_ddl

  my $ddl = $storage->_install_ddl($schema);

The install DDL string for C<$schema>. Default:
C<< _ddl_class->install_ddl($schema) >> -- the same convention the sync
L<DBIO::Deploy::Base/_install_ddl> uses. Override to source the DDL differently.

=head2 _ddl_class

Class name whose C<install_ddl($schema)> returns the install DDL, parallel to
L<DBIO::Deploy::Base/_ddl_class>. Abstract seam: a backend that supports
L</deploy_async> overrides it (e.g. C<'DBIO::PostgreSQL::DDL'>). Defaults to
croaking.

=head2 _use_transactional_ddl

  if ($storage->_use_transactional_ddl) { ... }

Whether the engine behind this transport honours transactional DDL (ADR 0026).
Delegates to the owning sync storage's C<transactional_ddl> capability
(L</_owner_storage>, L<DBIO::Storage::DBI::Capabilities>); false when no owner is
wired or the capability is unset -- the conservative default (do not assume
atomic DDL). Mirrors the sync probe in
C<_storage_uses_transactional_ddl> in L<DBIO::DeploymentHandler>.

=head2 _execute_ddl_async

  my $future = $storage->_execute_ddl_async($conn, $ddl);

Split C<$ddl> into statements and run each
on the pinned connection C<$conn>, one at a time, through the
L</_query_async_pinned> transport seam. The text is cut by the splitter the sync
L<DBIO::Deploy::Base/_execute_ddl> uses (C<DBIO::Deploy::Base::_split_ddl>, over
L<DBIO::SQL::Util/_split_statements>), in the SQL dialect the owning storage
declares through C<_ddl_sql_dialect>: a semicolon inside parentheses or a
C<BEGIN ATOMIC> body does not end a statement, a comment in front of a statement
is taken off it, and a piece that holds only comments is no statement and is not
run. Returns a Future that resolves when the last statement
completes or fails on the first error.

The statements are chained sequentially -- each waits for the previous to
complete -- so the transport never has two DDL statements in flight on one
connection. Routing through C<_query_async_pinned> rather than a native client
call is what lets every Model-B backend that already implements that seam for
CRUD execute DDL with no extra code.

=head2 _ddl_quote_ident

  my $quoted = $storage->_ddl_quote_ident($name);

The identifier C<$name> as the DDL of this storage writes it. The default
leaves a plain identifier bare and double-quotes any other
(L<DBIO::SQL::Util>); a storage whose engine quotes differently overrides this
one method, and L</_drop_statements_for> writes every name through it.

=head2 _drop_statements_for

  my $sql = $storage->_drop_statements_for($schema);

Build the statements of the L</deploy_async> C<add_drop_table> pre-pass: first
C<DROP VIEW IF EXISTS ...;> for every declared view
(L<DBIO::ResultSource::View>) that is a real view of the database, then
C<DROP TABLE IF EXISTS ... CASCADE;> for every regular table source in
C<$schema>. The views go in the reverse of their install order -- the source
names in order, each behind the views its
L<deploy_depends_on|DBIO::ResultSource::View/deploy_depends_on> names -- so a
view is dropped before the views it reads. Virtual views and sources whose name
is not a plain identifier (scalar-ref / subselect names, or names containing
whitespace or parens) are left out. Every name is written through
L</_ddl_quote_ident>. Returns the statements joined into one string, separated
by a blank line. Fully schema-driven -- override for an engine whose DROP syntax
differs.

=head2 select

=head2 select_single

=head2 insert

=head2 update

=head2 delete

=head2 txn_do

=head2 deploy

Blocking forms of L</select_async>, L</select_single_async>,
L</insert_async>, L</update_async>, L</delete_async>, L</txn_do_async> and
L</deploy_async>: each calls its C<*_async> counterpart with the same
arguments and waits for the Future with C<< ->get >>, returning its result
or rethrowing its failure. Useful in scripts and migrations that run
outside an event loop.

=head2 debug

Returns the trace level, initialised from C<DBIO_TRACE> at construction (the
leading digits of the flag, 1 for any other true value; see
L<DBIO::Storage/DBIO_TRACE>).

=head2 in_txn

Always false on the storage itself: an async transaction lives in the
L<DBIO::Storage::Async::TransactionContext> that L</txn_do_async> hands to
its coderef, which answers C<in_txn> for its own lifetime.

=head2 connected

True when a pool has been built and it currently holds at least one idle
connection (its C<available> count).

=head2 disconnect

Invalidates every transaction and pipeline context issued so far (they can no
longer dispatch), ends listening -- the listen connection is closed, the
channel registry cleared, a pending reconnect abandoned and any Future still
waiting on a subscription failed -- then shuts the pool down and drops it. In a
forked child the parent's listen connection is left alone (see
L</LISTEN / NOTIFY>). Also called from C<DESTROY> when a pool or listen state
exists.

=head1 A LAYERED SCHEMA ACROSS ASYNC TRANSPORTS

Because the async mode is chosen B<per connection> (ADR 0030) rather than baked
onto the storage class, one schema -- even a heavily-layered one -- can be driven
across every async execution model at once. This worked example takes a single
PostgreSQL schema defined with B<both> the Apache AGE and PostGIS extensions and
runs it under C<future_io>, C<ev>, C<immediate> and C<forked>, from the same
class, with no per-transport plumbing.

The AGE / PostGIS / EV code below is B<illustrative> -- it shows the shape a real
application sees. What actually runs in THIS distribution's test suite is a
synthetic stand-in that proves the same mechanism with no downstream
dependencies and no database: F<t/composed/async_modes_example.t>. The concrete
AGE+PostGIS+EV realization is exercised by the L<DBIO-PostgreSQL-Age|DBIO::PostgreSQL::Age>
suite -- F<t/40-stacking.t> (AGE and PostGIS compose together),
F<t/41-dual-mode-coexistence.t> (an C<ev> and a C<future_io> connection to one
schema at once), F<t/42-immediate-smoke.t> and F<t/43-ev-integration-live.t>.

=head2 Define the schema once

Both extensions register as storage B<layers> (L<DBIO::Storage::Composed>), so
the composed sync storage C<isa> both extensions I<and> the driver, and their
methods -- AGE's C<cypher>, PostGIS's C<ensure_postgis> -- live on one object:

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age', 'PostgreSQL::PostGIS');

  # $schema->storage now isa DBIO::PostgreSQL::Storage, ...::Age, ...::PostGIS;
  # $schema->storage->cypher(...) and $schema->storage->ensure_postgis both work.

=head2 future_io -- a non-blocking Future::IO loop

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'future_io' });

  # AGE's async layer is composed over the future_io transport; cypher_async is
  # non-blocking on the Future::IO loop:
  $schema->storage->async->cypher_async('MATCH (n:Person) RETURN n')->then(sub {
      my @rows = @_;
      ...
  });

The C<future_io> transport is resolved B<by convention> off the concrete driver
storage (C<< DBIO::PostgreSQL::Storage::Async >>); AGE's C<< ...::Age::Async >>
layer composes on top of it (see L</transport_capabilities>).

=head2 ev -- a native EV::Pg loop, same schema class

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'ev' });

  # Identical API surface, a different loop; LOAD 'age' replays on every pooled
  # connection (see L</"POOL CONNECTION ACTIONS">).
  $schema->storage->async->cypher_async('MATCH (n:Person) RETURN n')->then(sub { ... });

The mode is chosen per C<connect>, not on the class, so the two are independent:
you can hold a C<future_io> connection and an C<ev> connection to the B<same>
schema class at once, each resolving its own B<distinct> composed backend (a
C<future_io> transport with AGE's async layer, and an C<ev> transport with AGE's
async layer). That per-instance distinctness is exactly what
F<t/composed/async_modes_example.t> asserts.

=head2 immediate -- the "no event loop" case

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'immediate' });

  # The *_async methods run in-process and hand back an already-resolved Future
  # (a DBIO::Future::Immediate). No backend is built, no loop is stood up:
  my $rows = $schema->storage->select_async($source, \@cols, \%where)->get;

This is for code that wants the async API uniformly -- the same C<*_async>
call sites -- without depending on an event loop.

=head2 forked

  my $schema = MyApp::Schema->connect($dsn, $user, $pass, { async => 'forked' });

Another loop transport: L<DBIO::Forked::Storage> (dist C<dbio-forked>) runs the
ordinary sync driver inside a C<fork()>. Same per-connection mode selection.

=head2 With no async mode, C<*_async> croaks

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);  # plain sync
  $schema->storage->select_async(...);  # croaks: not an async connection

Async is opt-in per connection: a sync instance has no chosen mode, so C<*_async>
fails loudly rather than degrading silently.

=head2 PostGIS is sync-only

PostGIS ships B<no> C<::Async> layer and says so: its storage layer defines
C<async_layer_class> returning C<undef>, the stated sync-only opt-out (see
L<DBIO::Storage::Composed/Async mirror: async_layer_class>). So under any async
mode B<no> PostGIS async layer is composed onto the backend; geometry CRUD flows
through the transport unchanged. A layer that neither declares this nor ships an
C<::Async> sibling is refused at async compose time rather than skipped. AGE, by contrast, needs its C<LOAD 'age'> session setup replayed on
every pooled connection, so its async layer declares the C<on_connect_replay>
transport capability as B<required>. The capability gate refuses to compose an
async layer over a transport that does not provide what it declares (naming the
layer, the missing capability and the transport); both PostgreSQL async
transports (C<future_io> and C<ev>) provide C<on_connect_replay>, so AGE composes
cleanly over either.

=head1 ACCESSBROKER CONSUMPTION

The async storage tier is the second consumer of the
L<DBIO::AccessBroker> credential seam (the first being L<DBIO::Storage::DBI>;
see L<CONTEXT.md> and the ADRs). The broker-management API itself
(C<set_access_broker>, C<clear_access_broker>,
C<current_access_broker_connect_info>) lives on the base L<DBIO::Storage>.
L</set_access_broker> and L</clear_access_broker> are extended here, because
on an async storage a broker is more than the broker slot.

What this class adds is the I<async> consumption wiring that was previously
re-implemented by every async driver: detecting a broker passed as connect
info, building the per-spawn C<conninfo_provider> coderef that pulls fresh
credentials, and feeding it to the pool so every NEW pool connection gets
freshly-refreshed connect info. Drivers supply only the one storage-native
seam hook, L</_async_broker_conninfo>.

B<One state, set in one place and taken away in one>. What a L</connect_info>
leaves on the storage is spread over several slots -- the broker and its mode,
the provider, the stored conninfo, the pool size, the options, the connect
options given beside the broker -- and they belong together: the conninfo of a
static connection must not stand beside a broker, nor the pool size of the
connect info before beside a new one. So nothing sets a part of it:

=over 4

=item * L</set_access_broker> is where a broker is attached, whoever calls it
-- L</_setup_access_broker> is the same call. It forgets everything the
connect info before left and installs the provider.

=item * L</clear_access_broker> is where a broker is detached, under either
name. What came with the broker goes with it. From then on the storage has
nothing to connect from, and every connection it is asked for is refused,
saying that no broker is attached: the provider refuses, on the storage and
in a pool built with it. L</_clear_access_broker> is the detach followed by
the forgetting of everything else, the provider included -- the state of a
storage that was never given connect info.

=item * L</connect_info> forgets all of it before it reads anything of the
new connect info, so a call that throws leaves nothing of the call before.

=back

=head1 ASYNC OPTIONS

The connect options an async backend takes beside the connection itself form a
declared list. With an C<async> mode set on the connection,
the owning storage keeps every name of the list out of its own C<< DBI->connect >>
and hands it to the backend; a name that is neither on the list nor a DBI
attribute is refused like every unknown connect attribute. Without an async
mode the DBD decides, as before.

The core's names are C<pool_size> (the size of the pool),
C<acquire_timeout> and C<max_waiters> (the bounds of a wait for a pool
connection, L<DBIO::Storage::PoolBase/new>), C<txn_timeout> (the time a
L</txn_do_async> may take) and C<reset_timeout> (the time the reset of a
released connection may take, L</_reset_pool_connection>). A backend adds names of its own with
L</async_option_names>, and reads what it was given with L</async_option>.

=head1 POOL CONNECTION ACTIONS

Every physical pool connection is set up with the SAME C<on_connect_do> /
C<on_connect_call> the owning sync storage was configured with -- and torn down
with the matching C<on_disconnect_do> / C<on_disconnect_call> -- so that a
pooled async connection has identical session semantics (C<search_path>,
timezone, C<SET> variables, extension C<LOAD>s, ...) to the sync path on the
same instance. Without this a user's session setup would silently
apply to C<< $schema->resultset(...) >> (sync) but not to C<*_async> (pool),
violating the fail-loud rule.

The central seam is L</_setup_pool_connection> (and L</_teardown_pool_connection>),
invoked once per physical connection from the shared core pool-spawn / shutdown
path (C<_spawn_connection> in L<DBIO::Storage::PoolBase>, L<DBIO::Storage::PoolBase/shutdown>),
so every Model-B backend whose pool wires this storage as its owner inherits the
behaviour. The action list and its C<connect_call_*> method resolution are read
from the B<owning sync storage> (L</_owner_storage>): the exact same
C<_do_connection_actions> dispatch the sync path uses (coderef / nested arrayref /
scalar method-name / C<do_sql>), so an extension's C<connect_call_load_age>
resolves by convention just as it does synchronously -- but each statement it
emits (via C<< $storage->_do_query >>) is redirected onto the fresh pool
connection instead of the sync C<dbh>.

B<Execution is synchronous> -- a blocking C<do> per statement on the fresh
connection at spawn time (see L</_run_pool_connect_statement>). Pool spawn is
rare, and a blocking C<do> is far simpler and safer than re-entering the async
transport / event loop mid-C<acquire> to route a few setup statements. This
suits every backend whose pool connection is ready at spawn (the DBD-based
C<future_io> adapters open with a blocking C<< DBI->connect >>); a native
backend whose handle cannot run a synchronous C<do>, or is not ready until after
an async connect, overrides L</_run_pool_connect_statement> (and, if needed, the
timing of the whole seam).

=head1 LISTEN / NOTIFY

Database notifications are part of the core async contract (ADR 0056). The
public surface -- L</listen>, L</unlisten>, L</notify>, L</listen_alive>,
L</listen_reconnect> and the two hooks L</on_listen_error> /
L</on_listen_reconnect> -- is defined here once, and so is the
transport-neutral machinery behind it. A transport fills a small set of
B<listen seams>, the same shape as the pipeline precedent above: core
orchestrates, the transport knows its wire.

  my $async = $schema->storage->async;   # e.g. { async => 'future_io' }

  $async->on_listen_error(sub {
    my ($storage, $error) = @_;
    $log->warn("listen: $error");
  });
  $async->on_listen_reconnect(sub {
    my ($storage) = @_;
    $log->info('listen connection rebuilt, every channel re-subscribed');
  });

  $async->listen(jobs => sub {
    my ($channel, $payload, $sender_pid) = @_;
    ...
  })->get;

  $async->notify(jobs => 'wake up');      # a Future

  # an external watchdog
  $async->listen_reconnect unless $async->listen_alive;

=head2 What core does

=over 4

=item * B<One dedicated listen connection>, outside the pool, shared by every
channel of this storage. It is opened by the first L</listen> and closed when
the last channel is unlistened (or on L</disconnect>).

=item * B<A channel registry> -- one callback per channel -- and dispatch in
contract order: C<< $cb->($channel, $payload, $sender_pid) >>.

=item * B<Serialised channel operations.> Every subscribe and unsubscribe runs
through one queue per connection, one at a time, so no transport ever sees two
in flight on the listen connection.

=item * B<Self-healing.> A dead connection -- the transport reports it through
L</_listen_lost>, the probe fails, or a channel operation fails and the probe
then says the connection is gone -- is closed, a reconnect is scheduled after a
bounded exponential backoff (L</listen_backoff_initial>,
L</listen_backoff_max>), B<every> registered channel is subscribed again on
the new connection, watching is re-armed and L</on_listen_reconnect> fires. A
failed reconnect attempt schedules the next one; healing continues until it
succeeds, the last channel is unlistened, or the storage disconnects.

=item * B<Fork safety.> The listen connection belongs to the process that
opened it. Core records that pid; in any other process it never touches the
connection -- no subscribe, no probe, no close. A forked child that calls
L</listen> starts with an empty registry and opens a connection of its own;
L</listen_alive> in a child is false until it does. The transport's half of
that obligation is to open the connection fork-safe, so that dropping the
inherited handle in a child does not tear the parent's session down (DBD::Pg:
C<< AutoInactiveDestroy => 1 >>).

=back

=head2 The capability gate

L</listen>, L</unlisten>, L</listen_alive> and L</listen_reconnect> require the
transport to declare C<listen> in L</transport_capabilities>; L</notify>
requires C<notify>. Without the declaration they throw
C<LISTEN/NOTIFY not supported by this storage driver> -- before touching any
state. A transport that emulates notifications (see L</_listen_watch>) may
declare both.

=head2 Transports that override the public methods

A transport may still override L</listen> / L</unlisten> / L</notify>
wholesale; its override wins and none of the machinery here runs. It must then
also answer L</listen_alive> and L</listen_reconnect> itself, because core's
versions only know the connection core opened. That is a migration state, not
a design option: the seams are the contract (ADR 0056).

=head2 Listen seams

Implemented by a transport that declares C<listen> / C<notify>; each croaks
until provided: L</_listen_open>, L</_listen_close>, L</_listen_subscribe>,
L</_listen_unsubscribe>, L</_listen_watch>, L</_listen_unwatch>,
L</_listen_probe>, L</_listen_delay> and L</_notify_send>. The transport calls
back into core through L</_listen_dispatch>, L</_listen_lost> and
L</_listen_error>. Core calls the seams only in the process that opened the
connection, and never runs two channel operations on one connection at once.
Every seam documented as returning a Future may instead return a plain value
when its work is already complete; core takes that as an already-resolved
Future.

B<The Futures callers get are made from yours.> A Future that L</listen>,
L</unlisten> or L</listen_reconnect> hands out while its work is still in flight
is settled by core, so core has to construct it -- and one constructed from
L</future_class> knows no event loop, so its C<get> could not wait. Core
therefore makes it from the last B<pending> Future one of your listen seams
returned, as C<< $that_future->new >>: the L<Future> idiom for a new pending
Future of the same kind, carrying your class and whatever it keeps with it (an
L<IO::Async::Future> keeps its loop). Its C<get> then awaits by running the loop
your seams resolve on. So a pending Future a listen seam returns must answer
C<new> called on the instance with a new pending Future that core can C<done>
and C<fail>, as every L<Future> subclass does. Where your Futures can
C<await> (L<Future::IO>'s, L<IO::Async>'s), so can the caller's; where they
cannot, a caller drives your loop until the Future is ready, as with any other
Future you return.

=head1 ASYNC DEPLOY

The async counterpart of the sync deploy pipeline (L<DBIO::Deploy::Base>).
L</deploy_async> generates the install DDL from the schema classes -- in
memory, no DB roundtrips -- then splits it into statements and runs each on a
single pinned connection through the L</_query_async_pinned> transport seam. So
every Model-B backend that already implements C<_query_async_pinned> for CRUD
gets DDL execution for free. The DDL generator is resolved via the
same C<< _ddl_class->install_ddl($schema) >> hook the sync path uses
(L<DBIO::Deploy::Base/_install_ddl>), B<not> a driver-specific schema method.

=head2 Transactional-DDL discipline

Following ADR 0026, the DDL batch is B<not> blanket-wrapped in a transaction.
L</deploy_async> probes L</_use_transactional_ddl> first and only brackets the
DDL in L</txn_do_async> on engines whose DDL is transactional (e.g. PostgreSQL)
-- a failure on statement N of M then rolls back the preceding N-1. On engines
whose DDL forces an implicit C<COMMIT> per statement (MySQL and MariaDB on
every version, Oracle, Sybase, Informix) an async transaction buys no
atomicity, so the loop runs
statement-at-a-time on one pooled connection and a one-shot warning is emitted
naming the class -- exactly the sync C<< DBIO::Deploy::Base::_execute_ddl >>
contract, on the Future side of the wire. An engine whose driver declines the
capability for reasons of its own (SQLite, DB2) takes the same path; see
L<DBIO::Deploy::Base/TRANSACTIONAL DDL>. A future non-transactional async
driver therefore inherits the correct (non-atomic, warned) behaviour rather
than a silent false-atomicity footgun.

The capability answers for the connection, but atomicity is decided per
statement (ADR 0026 addendum). On a transactional engine L</deploy_async>
asks the B<same> per-statement C<_ddl_statement_is_transactional> hook the sync
path asks -- on the B<owning sync storage> (L</_owner_storage>), the storage
L</_use_transactional_ddl> already delegates to and the one carrying the
capability -- and reuses C<< DBIO::Deploy::Base::_group_ddl_statements >> so the
runs come out in the B<same order and grouping> as the sync deploy. Each run of
transaction-safe statements is bracketed in one L</txn_do_async> on a pinned
connection; a statement the hook declares non-transactional runs on its own
pooled connection, B<outside> any transaction. A batch where every statement is
transaction-safe -- the usual case, and always when a driver never defines the
hook -- yields exactly one run and is identical to bracketing the whole loop.
Where a batch splits into more than one run the deploy is no longer atomic as a
whole; core announces the split once per class (same recovery story as sync: the
C<__VERSION> gate in L<DBIO::DeploymentHandler>). This is the async mirror of the
per-statement grouping ADR 0026 §Addendum records for the sync path -- a parity
fix, not a new decision.

A backend that inherits L</deploy_async> provides a L</_ddl_class>, and its
L</_txn_context_class> answers the pinned connection under the name
L</_txn_conn_accessor> gives -- C<txn_conn> by default, as the generic
L<DBIO::Storage::Async::TransactionContext> does. A transactional run sends its
statements on that connection through L</_query_async_pinned>, not through the
context: they are not among the statements the context tracks. What decides
whether the run goes on is the pool it began on, which L</deploy_async> asks
between the statements.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
