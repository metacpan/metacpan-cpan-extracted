package DBIO::Storage::Async;
# ABSTRACT: Base class for async storage implementations

use strict;
use warnings;
use base 'DBIO::Storage';

use Carp 'croak';
use Scalar::Util qw(blessed weaken);
use DBIO::Storage::Async::TransactionContext;
use DBIO::SQL::Util ();
use namespace::clean;


sub new {
  my ($class, $schema, $args) = @_;
  my $self = bless {
    schema             => $schema,
    pool               => undef,
    connect_info       => undef,
    sql_maker          => undef,
    _conninfo_provider => undef,
    debug              => $ENV{DBIO_TRACE} || 0,
    debugobj           => undef,
  }, $class;
  weaken($self->{schema}) if ref $self->{schema};
  return $self;
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


sub _setup_access_broker {
  my ($self, $broker) = @_;

  $self->set_access_broker($broker, 'write');
  $self->{_conninfo_provider} = sub {
    return $self->_async_broker_conninfo($self->access_broker_mode);
  };

  return $self;
}


sub _clear_access_broker {
  my $self = shift;

  $self->clear_access_broker;
  $self->{_conninfo_provider} = undef;

  return $self;
}


sub _conninfo_provider { $_[0]->{_conninfo_provider} }


sub _async_broker_conninfo {
  croak 'Subclass must override _async_broker_conninfo to consume an AccessBroker';
}


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
    # karr #66: strip DBIO-private attrs before the DB-specific reshape seam,
    # so _normalize_conninfo (and DBI->connect) only see real DBD attributes.
    $info = $self->_strip_private_connect_attrs($info);
    $info = $self->_normalize_conninfo($info);
    $self->disconnect if $self->{pool};
    $self->{connect_info} = $info;

    if ($self->_is_access_broker_connect_info($info)) {
      $self->_setup_access_broker($info->[0]);
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info(
        $self->_current_async_connect_info($self->access_broker_mode)
      );
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
    else {
      $self->_clear_access_broker;
      my ($conninfo, $pool_size, $opts) = $self->_normalize_async_connect_info($info);
      $self->{_conninfo}  = $conninfo;
      $self->{_pool_size} = $pool_size;
      $self->{_opts}      = $opts;
    }
  }
  return $self->{connect_info};
}

# Resolve the current connect info to normalise: fresh broker credentials
# when a broker is attached, otherwise the last static conninfo/opts pair.
sub _current_async_connect_info {
  my ($self, $mode) = @_;

  my $connect_info = $self->current_access_broker_connect_info($mode);
  return [$connect_info, {}] if $connect_info && ref $connect_info eq 'HASH';
  return $connect_info if $connect_info;

  return [ $self->{_conninfo}, $self->{_opts} || {} ];
}

# Split a [ \%conninfo, \%opts ] pair into ($conninfo, $pool_size, $opts),
# working on copies so the caller's structures are never mutated. pool_size
# is stripped out of the conninfo (default 5); opts default to an empty hash.
sub _normalize_async_connect_info {
  my ($self, $info) = @_;

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

# karr #66: pull the DBIO-private connect attributes out of the incoming RAW
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
# Broker-form info ([$broker]) carries no caller attr hash and is left as-is.
sub _strip_private_connect_attrs {
  my ($self, $info) = @_;

  return $info
    if ref $info ne 'ARRAY'
    or $self->_is_access_broker_connect_info($info);

  my @args = @$info;   # shallow copy; the attr hashes below are copied before mutation

  my @attr_slots;
  if (ref $args[0] eq 'CODE') {         # coderef + optional \%extra_attributes
    push @attr_slots, \$args[1] if ref $args[1] eq 'HASH';
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
    # these as storage_options). Held for karr #68 (pool on_connect seam:
    # on_connect_do / on_connect_call) to consume; no further processing here.
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

    $$slot = \%attrs;
  }

  # Slot the storage options aside for karr #68; nothing consumes them yet.
  $self->{_storage_options} = \%storage_options;

  return \@args;
}


sub _owner_storage {
  my $self = shift;
  if (@_) {
    $self->{_owner_storage} = $_[0];
    weaken($self->{_owner_storage}) if ref $self->{_owner_storage};
  }
  return $self->{_owner_storage};
}


sub _setup_pool_connection {
  my ($self, $conn) = @_;

  my $owner = $self->_owner_storage or return;
  return unless $owner->can('_run_pool_connect_actions');

  $owner->_run_pool_connect_actions(sub {
    $self->_run_pool_connect_statement($conn, @_);
  });

  return;
}


sub _teardown_pool_connection {
  my ($self, $conn) = @_;

  my $owner = $self->_owner_storage or return;
  return unless $owner->can('_run_pool_disconnect_actions');

  $owner->_run_pool_disconnect_actions(sub {
    $self->_run_pool_connect_statement($conn, @_);
  });

  return;
}


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, @args) = @_;
  my $dbh = $self->_pool_connect_dbh($conn);
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
  return $self->_run_crud('select', $self->_pool_runner, @_);
}


sub select_single_async {
  my $self = shift;
  return $self->_run_crud('select_single', $self->_pool_runner, @_);
}


sub insert_async {
  my $self = shift;
  return $self->_run_crud('insert', $self->_pool_runner, @_);
}


sub update_async {
  my $self = shift;
  return $self->_run_crud('update', $self->_pool_runner, @_);
}


sub delete_async {
  my $self = shift;
  return $self->_run_crud('delete', $self->_pool_runner, @_);
}

# Build SQL for a CRUD op and execute it through $runner, a coderef that
# takes ($sql, \@bind) and returns a Future of result rows. The DB-specific
# INSERT-column retrieval (_post_insert_sql) and first-row post-processing for
# select_single live here exactly once, so the pooled path (_pool_runner) and
# the pinned txn path (_pinned_runner, used by the TransactionContext) share
# identical behaviour. Placeholder-dialect shaping (?->$N) is NOT applied here:
# the query seams receive raw sql_maker '?' SQL and shape it internally (karr
# #70 / ADR 0032), so the runner is handed the raw $sql.
sub _run_crud {
  my ($self, $op, $runner, @args) = @_;

  my $sm = $self->sql_maker;
  if ($op eq 'select' || $op eq 'select_single') {
    my ($sql, @bind) = $sm->select(@args);
    my $f = $runner->($sql, \@bind);
    return $f unless $op eq 'select_single';
    return $f->then(sub {
      my @rows = @_;
      return @rows ? $rows[0] : undef;
    });
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

    my ($sql, @bind) = $sm->insert($table, @rest);
    my $post = $self->_post_insert_sql;
    $sql .= $post if length $post && $sql !~ /RETURNING/i;

    # ADR 0031 §3: insert_async must resolve the returned-columns HASHREF --
    # the supplied insert data overlaid with the DB-populated columns (autoinc
    # PK + retrieve-on-insert), exactly what sync $storage->insert returns --
    # so create_async / Row::insert_async can fold it back via
    # _store_inserted_columns. The runner yields the raw RETURNING row(s); map
    # the first onto the insert data. (select_async / select_single_async keep
    # resolving raw arrayrefs, matching the sync cursor shape.)
    return $runner->($sql, \@bind)->then(sub {
      my @rows = @_;
      return $self->_insert_returned_columns($source, $to_insert, $rows[0]);
    });
  }
  elsif ($op eq 'update') {
    my ($sql, @bind) = $sm->update(@args);
    return $runner->($sql, \@bind);
  }
  elsif ($op eq 'delete') {
    my ($sql, @bind) = $sm->delete(@args);
    return $runner->($sql, \@bind);
  }
  croak "Unknown CRUD operation: $op";
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

# Runner that executes on a freshly-acquired pooled connection and releases
# it when done. This is the normal (non-transactional) path.
sub _pool_runner {
  my $self = shift;
  return sub {
    my ($sql, $bind) = @_;
    return $self->_query_async($sql, $bind);
  };
}

# Runner that executes on a pinned connection without releasing it. Used by
# TransactionContext so CRUD inside a txn hits the same connection that
# BEGIN/COMMIT ran on.
sub _pinned_runner {
  my ($self, $conn) = @_;
  return sub {
    my ($sql, $bind) = @_;
    return $self->_query_async_pinned($conn, $sql, $bind);
  };
}

# Build SQL and run a CRUD op on a pinned connection. Entry point used by
# TransactionContext; shares _run_crud's builders / post-processing.
sub _run_crud_pinned {
  my ($self, $op, $conn, @args) = @_;
  return $self->_run_crud($op, $self->_pinned_runner($conn), @args);
}


sub _query_async {
  croak 'Subclass must override _query_async($sql, $bind)';
}


sub _query_async_pinned {
  croak 'Subclass must override _query_async_pinned($conn, $sql, $bind)';
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

  return $self->pool->acquire_txn->then(sub {
    my $conn = shift;

    my $txn_ctx_class = $self->_txn_context_class;
    my $accessor = $self->_txn_conn_accessor;
    my $txn_ctx = $txn_ctx_class->new(
      storage   => $self,
      $accessor => $conn,
    );

    # BEGIN
    return $self->_query_async_pinned($conn, 'BEGIN', [])->then(sub {
      my $inner = eval { $coderef->($txn_ctx, @args) };
      if ($@) {
        my $error = $@;
        return $self->_query_async_pinned($conn, 'ROLLBACK', [])->then(sub {
          $self->pool->release($conn);
          $fc->fail($error);
        }, sub {
          my $rerr = shift;
          $self->pool->release($conn);
          $fc->fail($rerr);
        });
      }

      # karr #10: the coderef's Future is almost always the tail of a
      # ->then chain. Real Future holds a downstream sequence Future only
      # WEAKLY, so unless we keep a strong ref it gets GC'd the moment this
      # callback returns -- Future warns "lost a sequence Future",
      # COMMIT/ROLLBACK never fires, and the await loop busy-spins forever.
      # ->retain gives $chain_f a self-reference until it is ready, keeping
      # the whole chain alive. Not every future_class implements ->retain
      # (an immediately-resolved shim has no GC window), so guard the call.
      if (ref $inner && $inner->can('then')) {
        my $chain_f = $inner->then(sub {
          my @result = @_;
          return $self->_query_async_pinned($conn, 'COMMIT', [])->then(sub {
            $self->pool->release($conn);
            $fc->done(@result);
          }, sub {
            my $cerr = shift;
            $self->pool->release($conn);
            $fc->fail("COMMIT failed: $cerr");
          });
        }, sub {
          my $error = shift;
          return $self->_query_async_pinned($conn, 'ROLLBACK', [])->then(sub {
            $self->pool->release($conn);
            $fc->fail($error);
          }, sub {
            my $rerr = shift;
            $self->pool->release($conn);
            $fc->fail($rerr);
          });
        });
        $chain_f->retain if $chain_f->can('retain');
        return $chain_f;
      }
      else {
        # Coderef returned a plain value -- commit immediately
        return $self->_query_async_pinned($conn, 'COMMIT', [])->then(sub {
          $self->pool->release($conn);
          $fc->done($inner);
        }, sub {
          my $cerr = shift;
          $self->pool->release($conn);
          $fc->fail("COMMIT failed: $cerr");
        });
      }
    }, sub {
      my $err = shift;
      $self->pool->release($conn);
      $fc->fail("BEGIN failed: $err");
    });
  });
}


sub _txn_context_class { 'DBIO::Storage::Async::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }


sub pipeline {
  my ($self, $coderef) = @_;

  my $fc = $self->future_class;

  return $self->pool->acquire->then(sub {
    my $conn = shift;
    $self->_pipeline_enter($conn);

    my $result = eval { $coderef->($self) };
    my $err = $@;

    if ($err) {
      $self->_pipeline_exit($conn);
      $self->pool->release($conn);
      return $fc->fail($err);
    }

    return $self->_pipeline_sync($conn)->then(sub {
      $self->_pipeline_exit($conn);
      $self->pool->release($conn);
      if (ref $result && $result->can('then')) {
        return $result;
      }
      return $fc->done($result);
    }, sub {
      my $sync_err = shift;
      $self->_pipeline_exit($conn);
      $self->pool->release($conn);
      return $fc->fail($sync_err);
    });
  });
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


sub listen { croak 'LISTEN/NOTIFY not supported by this storage driver' }


sub unlisten { croak 'LISTEN/NOTIFY not supported by this storage driver' }


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

  # ADR 0026: never blanket-wrap DDL in a transaction. Only bracket the batch in
  # an async transaction when the engine's DDL is actually transactional;
  # otherwise the wrap is a false atomicity promise (MySQL/Oracle/... implicitly
  # COMMIT each DDL statement), so run statement-at-a-time on one pooled
  # connection with a one-shot warning -- the Future-side mirror of
  # DBIO::Deploy::Base::_execute_ddl.
  if ($self->_use_transactional_ddl) {
    return $self->txn_do_async(sub {
      my ($ctx) = @_;
      return $self->_execute_ddl_async($ctx->txn_conn, $ddl);
    });
  }

  my $class = ref($self) || $self;
  $self->_warn_non_txn_ddl_once(
    "$class -- async DDL loop is not atomic; recovery depends on the driver's version-row gate"
  );

  my $fc = $self->future_class;
  return $self->pool->acquire->then(sub {
    my $conn = shift;
    return $self->_execute_ddl_async($conn, $ddl)->then(sub {
      $self->pool->release($conn);
      return $fc->done(@_);
    }, sub {
      my $err = shift;
      $self->pool->release($conn);
      return $fc->fail($err);
    });
  });
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

  my @stmts = grep { !/^\s*--/ } DBIO::SQL::Util::_split_statements($ddl);
  my $fc = $self->future_class;

  my $recur;
  $recur = sub {
    my $stmt = shift @stmts;
    return $fc->done unless defined $stmt;
    return $self->_query_async_pinned($conn, $stmt, [])->then($recur);
  };
  return $recur->();
}


sub _drop_statements_for {
  my ($self, $schema) = @_;
  my @out;
  for my $name ($schema->sources) {
    my $source = $schema->source($name);
    next if $source->isa('DBIO::ResultSource::View');
    my $table = $source->name;
    next if ref $table;
    next if $table =~ /\s|\(/;
    push @out, sprintf 'DROP TABLE IF EXISTS %s CASCADE;', DBIO::SQL::Util::_quote_ident($table);
  }
  return join("\n\n", @out);
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
  if ($self->{pool}) {
    $self->{pool}->shutdown;
    $self->{pool} = undef;
  }
}

sub DESTROY {
  my $self = shift;
  $self->disconnect if $self->{pool};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async - Base class for async storage implementations

=head1 VERSION

version 0.900001

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
normalisation, the shared CRUD builder (L</_run_crud>) with its pooled and
pinned runners, INSERT returned-columns mapping (ADR 0031 §3),
L</txn_do_async> bracketing through the generic
L<DBIO::Storage::Async::TransactionContext>, and the L</pipeline> scaffold.
Everything DB- and loop-specific is factored out behind B<transport seam
hooks> a backend overrides -- how to submit an async query
(L</_query_async> / L</_query_async_pinned>), the SQL shaping
(L</_transform_sql> / L</_post_insert_sql>), the connection pool (L</pool>),
and the Future implementation (L</future_class>). A backend therefore
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

=head2 _is_access_broker_connect_info

  if ($self->_is_access_broker_connect_info($info)) { ... }

True when the supplied connect info is a broker-style invocation: a
single-element arrayref whose sole member is a blessed
L<DBIO::AccessBroker> instance. Mirrors the same check on the DBI side
(L<DBIO::Storage::DBI::AccessBroker>).

=head2 _setup_access_broker

  $self->_setup_access_broker($info->[0]);

Attach the broker (via the inherited L<DBIO::Storage/set_access_broker>)
and install the per-spawn C<conninfo_provider> coderef. Call this from a
driver's C<connect_info> when L</_is_access_broker_connect_info> matched.
The coderef closes over C<$self> and, on each invocation, calls the
driver's L</_async_broker_conninfo> to obtain freshly-refreshed,
storage-native connect info for one new pool connection.

=head2 _clear_access_broker

  $self->_clear_access_broker;

Detach any broker (via the inherited L<DBIO::Storage/clear_access_broker>)
and tear down the C<conninfo_provider>, so a subsequent non-broker
connect uses the static conninfo path. Call from a driver's
C<connect_info> on the non-broker branch.

=head2 _conninfo_provider

The per-spawn credential coderef installed by L</_setup_access_broker>, or
C<undef> when no broker is attached. Hand this to the pool as its
C<conninfo_provider> so every NEW pool connection is built from fresh
credentials (see L<DBIO::Storage::PoolBase/_spawn_connection>).

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

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. Handles both broker-style and direct connect
info, normalising each through L</_normalize_conninfo> (a DB-specific seam,
identity by default) and L</_normalize_async_connect_info> (pool-size / opts
extraction). Returns the stored raw connect info.

Before the DB-specific L</_normalize_conninfo> seam runs, the DBIO-private
connect attributes (the async mode selector, C<quote_char>/C<name_sep>/
C<quote_names>, storage options incl. C<cursor_class>, and C<ignore_version>)
are stripped out centrally (L</_strip_private_connect_attrs>, karr #66), so
the seam and ultimately C<DBI-E<gt>connect> only ever see real DBD attributes.
This mirrors the sync path's
L<DBIO::Storage::DBI/_normalize_connect_info> and both consume one shared
name list on L<DBIO::Storage>, so a strict DBD (e.g. DBD::MariaDB) never
receives an unrecognised private attribute.

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo($info);

DB-specific connect-info conversion seam, applied before broker detection.
Defaults to an identity pass-through; a driver whose connect info needs
reshaping (e.g. DSN string to libpq hashref) overrides it.

=head2 _owner_storage

  $async->_owner_storage($sync_storage);   # setter
  my $sync = $async->_owner_storage;       # getter

The sync L<DBIO::Storage::DBI> instance that built this embedded async backend
(set by L<DBIO::Storage::DBI/_async_storage>). Held B<weakly> -- the sync storage
owns the async backend (it caches it in C<_async_storage_obj>), not the reverse,
so a strong ref here would be a cycle. This back-reference is what lets the pool
resolve C<connect_call_*> methods on the class that actually defines them.

=head2 _setup_pool_connection

  $async->_setup_pool_connection($conn);

Run the owning sync storage's C<on_connect_call> / C<on_connect_do> against the
freshly spawned pool connection C<$conn>. Invoked centrally from
L<DBIO::Storage::PoolBase/_spawn_connection>. Resolves the actions (and any
C<connect_call_*> methods) on L</_owner_storage> but executes each emitted
statement against C<$conn> via L</_run_pool_connect_statement>. A no-op when no
owner is wired (e.g. a standalone pool).

=head2 _teardown_pool_connection

  $async->_teardown_pool_connection($conn);

Symmetric counterpart of L</_setup_pool_connection>: run the owning sync
storage's C<on_disconnect_call> / C<on_disconnect_do> against C<$conn> while it
is still live. Invoked from L<DBIO::Storage::PoolBase/shutdown> before the
connection is closed.

=head2 _run_pool_connect_statement

  $async->_run_pool_connect_statement($conn, $sql, $attrs, @bind);

Runner seam: execute one connection-action statement B<synchronously> (a
blocking C<do>) on the pool connection C<$conn>. The default handles the two
DBD-based connection shapes -- a bare do-capable DBI handle, and the
C<future_io> wrapper C<< { dbh => $dbh } >> -- and croaks on anything else. A
native backend (e.g. an C<EV::Pg> client) whose connection is neither overrides
this method to drive its own synchronous execution.

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
L<DBIO::Storage::DBI/_async_storage> refuses to compose a layer onto a transport
that is missing a required capability (it croaks naming the gap rather than
silently dropping the feature). The base transport declares none; a concrete
transport overrides this to advertise what it supports (e.g. C<on_connect_replay>,
C<listen>, C<notify>, C<copy>, C<pipeline>).

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

=head2 update_async

  my $future = $storage->update_async($source, \%vals, \%where);

=head2 delete_async

  my $future = $storage->delete_async($source, \%where);

=head2 _query_async

  my $future = $storage->_query_async($sql, $bind);

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready. Returns a L</future_class> of the raw
result rows. Must be overridden by a backend.

B<Placeholder-dialect contract (karr #70, decision 2):> the C<$sql> handed to
this seam is B<always> raw L<DBIO::SQLMaker> output -- the C<sql_maker> dialect
with C<?> placeholders. A transport that needs a different placeholder syntax
(e.g. C<$1>/C<$N> for PostgreSQL) MUST apply that shaping B<internally>, in its
own implementation of this seam, via L</_transform_sql> or an equivalent. The
seam contract is C<?>-in; dialect-out is the transport's private business. Core
does not pre-shape the SQL for the transport.

=head2 _query_async_pinned

  my $future = $storage->_query_async_pinned($conn, $sql, $bind);

Transport seam. Like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction. Must be overridden by a backend.

The same placeholder-dialect contract as L</_query_async> applies: C<$sql>
arrives as raw C<sql_maker> output with C<?> placeholders, and any dialect
shaping is the transport's own internal responsibility.

=head2 _await_query_result

Transport seam (loop-specific). Submit a query on a connection and resolve
with its result rows once the wire is readable. Used by a backend's
L</_query_async> implementation. Must be overridden by a backend that routes
through this layer.

=head2 _await_conn_ready

Transport seam (loop-specific). Resolve with C<$conn> once it is ready for
queries. Must be overridden by a backend that routes through this layer.

=head2 _transform_sql

Transport-B<internal> helper (karr #70, decision 2). DB-specific SQL shaping
(e.g. C<?E<gt>$N> placeholder rewriting for PostgreSQL, identity for MySQL).

This is B<not> a general seam any more: it is private to a transport's own
implementation of the query seams (L</_query_async> /
L</_query_async_pinned>), which receive raw C<sql_maker> output with C<?>
placeholders and shape it internally. No caller B<outside> a transport
implementation may invoke it -- core orchestration (L</_run_crud>) hands the
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

=head2 _txn_context_class

The transaction-context class L</txn_do_async> hands to its coderef. Defaults
to the generic L<DBIO::Storage::Async::TransactionContext>; a backend needing
a different pinned-connection accessor overrides L</_txn_conn_accessor> (and,
if it needs a wholly different context, this).

=head2 _txn_conn_accessor

The constructor key L</txn_do_async> passes the pinned connection under when
building the L</_txn_context_class>. Defaults to C<txn_conn>.

=head2 pipeline

  my $future = $storage->pipeline(sub {
      my ($storage) = @_;
      my @futures;
      push @futures, $storage->insert_async('artist', { name => $_ })
          for @names;
      return $storage->future_class->needs_all(@futures);
  });

Execute multiple queries in pipeline mode for reduced round-trips. The
scaffold acquires a connection, brackets the batch with L</_pipeline_enter>,
L</_pipeline_sync> and L</_pipeline_exit>, and releases the connection. The
DB-specific pipeline mechanics are supplied by the backend via those three
seams; a backend that cannot pipeline simply does not override them and the
scaffold croaks on the first seam it touches.

=head2 _pipeline_enter

Transport seam. Open pipeline/batch mode on the connection. Overridden by a
backend that supports pipelining.

=head2 _pipeline_sync

Transport seam. Flush the batched queries and resolve when the batch has been
sent/acknowledged. Overridden by a backend that supports pipelining.

=head2 _pipeline_exit

Transport seam. Close pipeline/batch mode on the connection. Overridden by a
backend that supports pipelining.

=head2 listen

  $storage->listen($channel, sub { my ($channel, $payload, $pid) = @_; });

Subscribe to database notifications (e.g. PostgreSQL LISTEN/NOTIFY).
Optional -- not all databases support this. Default croaks.

=head2 unlisten

  $storage->unlisten($channel);

Unsubscribe from a notification channel.

=head2 deploy_async

  my $future = $storage->deploy_async($schema, \%opts);
  $future->get;

Deploy C<$schema> asynchronously: generate the install DDL and execute every
statement over the async transport. The Future resolves on success or fails on
the first DDL error (on a transactional engine the whole batch is rolled back).

C<%opts>:

=over 4

=item add_drop_table => 1

Prepend C<DROP TABLE IF EXISTS ... CASCADE> for every table source in the
schema (L</_drop_statements_for>), so a re-run on a populated database is
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
L<DBIO::DeploymentHandler/_storage_uses_transactional_ddl>.

=head2 _execute_ddl_async

  my $future = $storage->_execute_ddl_async($conn, $ddl);

Split C<$ddl> into statements (L<DBIO::SQL::Util/_split_statements>, skipping
comment-only statements) and run each on the pinned connection C<$conn>, one at
a time, through the L</_query_async_pinned> transport seam. Returns a Future
that resolves when the last statement completes or fails on the first error.

The statements are chained sequentially -- each waits for the previous to
complete -- so the transport never has two DDL statements in flight on one
connection. Routing through C<_query_async_pinned> rather than a native client
call is what lets every Model-B backend that already implements that seam for
CRUD execute DDL with no extra code (karr #73).

=head2 _drop_statements_for

  my $sql = $storage->_drop_statements_for($schema);

Build C<DROP TABLE IF EXISTS ... CASCADE> for every regular table source in
C<$schema>, for the L</deploy_async> C<add_drop_table> pre-pass. Skips views
(L<DBIO::ResultSource::View>) and sources whose name is not a plain identifier
(scalar-ref / subselect names, or names containing whitespace or parens).
Returns the statements joined into one string. Fully schema-driven -- override
for an engine whose DROP syntax differs.

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

PostGIS ships B<no> C<::Async> layer, so under any async mode B<no> PostGIS async
layer is composed onto the backend; geometry CRUD flows through the transport
unchanged. AGE, by contrast, needs its C<LOAD 'age'> session setup replayed on
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
C<current_access_broker_connect_info>) lives on the base L<DBIO::Storage>,
so it is inherited here unchanged.

What this class adds is the I<async> consumption wiring that was previously
re-implemented by every async driver: detecting a broker passed as connect
info, building the per-spawn C<conninfo_provider> coderef that pulls fresh
credentials, and feeding it to the pool so every NEW pool connection gets
freshly-refreshed connect info. Drivers supply only the one storage-native
seam hook, L</_async_broker_conninfo>.

=head1 POOL CONNECTION ACTIONS

Every physical pool connection is set up with the SAME C<on_connect_do> /
C<on_connect_call> the owning sync storage was configured with -- and torn down
with the matching C<on_disconnect_do> / C<on_disconnect_call> -- so that a
pooled async connection has identical session semantics (C<search_path>,
timezone, C<SET> variables, extension C<LOAD>s, ...) to the sync path on the
same instance (karr #68). Without this a user's session setup would silently
apply to C<< $schema->resultset(...) >> (sync) but not to C<*_async> (pool),
violating the fail-loud rule.

The central seam is L</_setup_pool_connection> (and L</_teardown_pool_connection>),
invoked once per physical connection from the shared core pool-spawn / shutdown
path (L<DBIO::Storage::PoolBase/_spawn_connection>, L<DBIO::Storage::PoolBase/shutdown>),
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

=head1 ASYNC DEPLOY

The async counterpart of the sync deploy pipeline (L<DBIO::Deploy::Base>).
L</deploy_async> generates the install DDL from the schema classes -- in
memory, no DB roundtrips -- then splits it into statements and runs each on a
single pinned connection through the L</_query_async_pinned> transport seam. So
every Model-B backend that already implements C<_query_async_pinned> for CRUD
gets DDL execution for free (karr #73). The DDL generator is resolved via the
same C<< _ddl_class->install_ddl($schema) >> hook the sync path uses
(L<DBIO::Deploy::Base/_install_ddl>), B<not> a driver-specific schema method.

=head2 Transactional-DDL discipline

Following ADR 0026, the DDL batch is B<not> blanket-wrapped in a transaction.
L</deploy_async> probes L</_use_transactional_ddl> first and only brackets the
DDL in L</txn_do_async> on engines whose DDL is transactional (e.g. PostgreSQL)
-- a failure on statement N of M then rolls back the preceding N-1. On engines
whose DDL forces an implicit C<COMMIT> per statement (MySQL pre-8.0, Oracle,
DB2, Sybase, Informix) an async transaction buys no atomicity, so the loop runs
statement-at-a-time on one pooled connection and a one-shot warning is emitted
naming the class -- exactly the sync C<< DBIO::Deploy::Base::_execute_ddl >>
contract, on the Future side of the wire. A future non-transactional async
driver therefore inherits the correct (non-atomic, warned) behaviour rather
than a silent false-atomicity footgun.

A backend that inherits L</deploy_async> must expose the pinned connection as
C<txn_conn> on its L</_txn_context_class> (the generic
L<DBIO::Storage::Async::TransactionContext> does) and provide a L</_ddl_class>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
