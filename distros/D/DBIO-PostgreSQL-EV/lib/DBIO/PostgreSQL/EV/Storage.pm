package DBIO::PostgreSQL::EV::Storage;
# ABSTRACT: Async PostgreSQL storage driver using EV::Pg

use strict;
use warnings;
use base 'DBIO::Storage::Async';

use Carp 'croak';
use Future;
use DBIO::PostgreSQL::SQLMaker;
use DBIO::PostgreSQL::EV::ConnectInfo 'conninfo_string';
use DBIO::PostgreSQL::EV::Pool;
use DBIO::PostgreSQL::EV::TransactionContext;
use DBIO::SQL::Util qw(_split_statements _quote_ident);
use namespace::clean;


# --- SQLMaker seams -----------------------------------------------------------
# The inherited DBIO::Storage::Async::sql_maker builds the maker from these.


sub sql_maker_class { 'DBIO::PostgreSQL::SQLMaker' }


sub _sql_maker_args {
  return (
    quote_char    => '"',
    name_sep      => '.',
    limit_dialect => 'LimitOffset',
  );
}


sub _post_insert_sql { ' RETURNING *' }


sub future_class { 'Future' }


sub transport_capabilities { qw(on_connect_replay listen notify copy pipeline) }


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
    # Embedded path: the sync storage feeds its own DBI-form connect_info
    # (['dbi:Pg:...', $user, $pass, \%attrs]). Translate it into the async
    # [ \%conninfo, \%opts ] shape before the normal broker/normalize logic.
    if (ref $info eq 'ARRAY' && defined $info->[0] && !ref $info->[0] && $info->[0] =~ /^dbi:/i) {
      $info = DBIO::PostgreSQL::EV::ConnectInfo::dbi_to_conninfo($info);
    }
    $self->disconnect if $self->{pool} || $self->{_listen_pg};
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


sub _async_broker_conninfo {
  my ($self, $mode) = @_;
  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_current_async_connect_info($mode)
  );
  return $conninfo;
}


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage  => $self,
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::PostgreSQL::EV pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->_conninfo_string;
    }

    DBIO::PostgreSQL::EV::Pool->new(%args);
  };
}

sub _conninfo_string {
  my ($self, $ci) = @_;
  $ci = $self->_current_async_connect_info($self->access_broker_mode)->[0]
    if ! defined $ci;
  return conninfo_string($ci);
}

# --- Transaction context seams ------------------------------------------------


sub _txn_context_class { 'DBIO::PostgreSQL::EV::TransactionContext' }


sub _txn_conn_accessor { 'pg' }

# --- SQL shaping seam ---------------------------------------------------------

# Translate SQL-standard '?' placeholders into PostgreSQL positional '$N'
# placeholders, numbering left-to-right so they line up with the maker's
# @bind. libpq (EV::Pg->query_params) only understands $N, never '?'.
#
# The shared DBIO::PostgreSQL::SQLMaker is also used by the SYNC DBI driver,
# which needs '?', so the maker MUST keep emitting '?'. The translation
# therefore lives here, in the async transport, applied to maker output
# INTERNALLY (in _query_async / _query_async_pinned) before it reaches
# query_params -- the core #70 / ADR 0032 seam contract: '?'-in, dialect-out
# is the transport's own business.
#
# Subtleties this must respect (all verified against the maker's output):
#   * '@?' is the JSONB jsonpath operator, not a placeholder. A '?' that is
#     immediately preceded by '@' is part of an operator and is left alone.
#     Its actual RHS placeholder ('@? ?::jsonpath') is a separate '?' and
#     does get translated.
#   * '?::jsonb' / '?::jsonpath' casts are real placeholders -> '$N::jsonb'.
#   * 'ARRAY[?, ?]' (jsonb_exists_any/all) has one placeholder per '?'.
#   * A '?' inside a single-quoted string literal ('...', with '' escaping)
#     or a double-quoted identifier ("...", with "" escaping) is data/name,
#     not a placeholder, and is skipped. This is defensive against inlined
#     literals that happen to contain '?'.


sub _transform_sql {
  my ($self, $sql) = @_;

  my $out = '';
  my $n   = 0;
  my $len = length $sql;
  my $i   = 0;

  while ($i < $len) {
    my $c = substr($sql, $i, 1);

    if ($c eq "'" || $c eq '"') {
      # Copy a quoted run verbatim, honouring doubled-quote escaping.
      my $quote = $c;
      $out .= $c;
      $i++;
      while ($i < $len) {
        my $d = substr($sql, $i, 1);
        $out .= $d;
        $i++;
        if ($d eq $quote) {
          if ($i < $len && substr($sql, $i, 1) eq $quote) {
            $out .= $quote;   # doubled quote -> escaped, stay inside
            $i++;
          } else {
            last;             # end of quoted run
          }
        }
      }
      next;
    }

    if ($c eq '?') {
      # '@?' operator: the '?' belongs to the operator, not a placeholder.
      if ($i > 0 && substr($sql, $i - 1, 1) eq '@') {
        $out .= $c;
        $i++;
        next;
      }
      $out .= '$' . (++$n);
      $i++;
      next;
    }

    $out .= $c;
    $i++;
  }

  return $out;
}

# --- Async query execution (transport seams) ----------------------------------


sub _query_async {
  my ($self, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  $self->_debug_query($sql, $bind) if $self->{debug};

  return $self->pool->acquire->then(sub {
    my $pg = shift;
    my $f = Future->new;
    $pg->query_params($sql, $bind, sub {
      my ($rows, $err) = @_;
      if ($err) {
        $f->fail($err);
      } else {
        $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows);
      }
      $self->pool->release($pg);
    });
    return $f;
  });
}


sub _query_async_pinned {
  my ($self, $pg, $sql, $bind) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  $self->_debug_query($sql, $bind) if $self->{debug};

  my $f = Future->new;
  $pg->query_params($sql, $bind, sub {
    my ($rows, $err) = @_;
    if ($err) { $f->fail($err) } else { $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows) }
    # Do NOT release — connection is pinned for the duration of the txn
  });
  return $f;
}

sub _debug_query {
  my ($self, $sql, $bind) = @_;
  my $bind_str = join(', ', map { defined $_ ? "'$_'" : 'NULL' } @$bind);
  warn "$sql: $bind_str\n";
}

# --- Pool connect-action replay seam (karr #68) -------------------------------


sub _run_pool_connect_statement {
  my ($self, $conn, $sql, $attrs, @bind) = @_;
  require EV;

  # The connection was just spawned; its async connect may still be in flight.
  # Block the EV loop until it is ready (the core seam's synchronous contract).
  # Prefer the pool's per-connection readiness Future (core
  # DBIO::Storage::PoolBase::_connection_ready_future, karr #75), which is
  # FAILED on a connect error -- so a bad connect surfaces as a thrown error
  # here rather than busy-spinning on is_connected forever. Fall back to
  # is_connected for a pool that does not expose the readiness seam (e.g. a
  # bare test double that is not a PoolBase subclass at all).
  my $pool = $self->pool;
  if ($pool->can('_connection_ready_future')) {
    my $ready = $pool->_connection_ready_future($conn);
    EV::run(EV::RUN_ONCE()) until $ready->is_ready;
    $ready->get;   # rethrows a connect error
  }
  else {
    EV::run(EV::RUN_ONCE()) until $conn->is_connected;
  }

  my $done = 0;
  my $err;
  my $cb = sub { (undef, $err) = @_; $done = 1 };
  if (@bind) {
    $conn->query_params($self->_transform_sql($sql), [@bind], $cb);
  }
  else {
    $conn->query($sql, $cb);
  }
  EV::run(EV::RUN_ONCE()) until $done;

  croak "pool connect statement failed: $err" if defined $err;
  return;
}

# --- Pipeline mode seams ------------------------------------------------------
# The inherited DBIO::Storage::Async::pipeline scaffold acquires a connection,
# brackets the batch with these three seams and releases the connection. EV::Pg
# expresses pipelining natively, so the base scaffold fits exactly -- no
# parallel pipeline() is needed (WP4 decision).


sub _pipeline_enter { $_[1]->enter_pipeline }


sub _pipeline_sync {
  my ($self, $pg) = @_;
  my $f = Future->new;
  $pg->pipeline_sync(sub { $f->done });
  return $f;
}


sub _pipeline_exit { $_[1]->exit_pipeline }

# --- LISTEN/NOTIFY ------------------------------------------------------------


sub listen {
  my ($self, $channel, $cb) = @_;

  $self->{_listeners}{$channel} = $cb;

  # Use a dedicated connection for LISTEN (not from the pool).
  # EV::Pg->new returns before the socket is actually connected; query()
  # dispatched on a not-yet-connected handle throws "not connected".
  # We buffer LISTEN/UNLISTEN until on_connect fires and then flush.
  #
  # karr #15: a second listen() on an already-connected dedicated conn
  # used to dispatch its LISTEN SQL directly via _listen_pg->query().
  # That races the still-in-flight CommandComplete from the first
  # LISTEN — libpq refuses with "another command is already in
  # progress", the LISTEN SQL is lost, and notifications on the new
  # channel are never delivered. Fix: route every LISTEN/UNLISTEN SQL
  # through a single _dispatch_listen_queue serialiser so we never have
  # two in flight at once. on_connect sets _listen_connected and calls
  # us; listen/unlisten push onto _listen_pending and call us; we drain
  # one at a time and re-enter from the in-flight query's callback.
  $self->{_listen_pg} ||= do {
    require EV::Pg;
    $self->{_listen_pending}     = [];
    $self->{_listen_dispatching} = 0;
    $self->{_listen_connected}   = 0;
    my $pg = EV::Pg->new(
      conninfo   => $self->_conninfo_string,
      keep_alive => 1,
      on_connect => sub {
        $self->{_listen_connected} = 1;
        $self->_dispatch_listen_queue;
      },
      on_error   => sub { warn "LISTEN connection error: $_[0]\n" },
      on_notify  => sub {
        my ($ch, $payload, $pid) = @_;
        if (my $handler = $self->{_listeners}{$ch}) {
          $handler->($ch, $payload, $pid);
        }
      },
    );
    $pg;
  };

  my $quoted = $self->sql_maker->_quote($channel);
  my $sql = "LISTEN $quoted";
  push @{ $self->{_listen_pending} }, $sql;
  $self->_dispatch_listen_queue if $self->{_listen_connected};
}

# Drain one SQL off _listen_pending and send it via the dedicated LISTEN
# connection, then chain the next dispatch off its callback. This is the
# single point through which ALL LISTEN/UNLISTEN SQLs flow, so we never
# have two in flight on the same libpq connection. Without this, a second
# listen() issued while the first LISTEN's CommandComplete is still in
# flight races libpq and dies with "another command is already in
# progress", losing the second subscription. (karr #15)
sub _dispatch_listen_queue {
  my ($self) = @_;

  # Not connected yet — on_connect will call us when the socket is up.
  return unless $self->{_listen_connected};
  # A previous dispatch is still in flight; its callback will re-enter
  # us once libpq has consumed its CommandComplete + ReadyForQuery.
  return if $self->{_listen_dispatching};
  # Nothing queued.
  return unless $self->{_listen_pending} && @{$self->{_listen_pending}};

  my $sql = shift @{$self->{_listen_pending}};
  $self->{_listen_dispatching} = 1;
  $self->{_listen_pg}->query($sql, sub {
    $self->{_listen_dispatching} = 0;
    $self->_dispatch_listen_queue;
  });
}


sub unlisten {
  my ($self, $channel) = @_;
  delete $self->{_listeners}{$channel};
  if ($self->{_listen_pg}) {
    my $quoted = $self->sql_maker->_quote($channel);
    my $sql = "UNLISTEN $quoted";
    push @{ $self->{_listen_pending} }, $sql;
    $self->_dispatch_listen_queue if $self->{_listen_connected};
  }
}


sub notify {
  my ($self, $channel, $payload) = @_;

  croak 'Channel name required' unless defined $channel && $channel ne '';

  return $self->pool->acquire->then(sub {
    my $pg = shift;
    my $f = Future->new;

    # pg_notify() with bind params -- NOTIFY itself takes no placeholders,
    # and inlining the payload as a string literal invites quoting bugs.
    $pg->query_params('SELECT pg_notify($1, $2)', [ $channel, $payload // '' ], sub {
      my ($res, $err) = @_;
      $self->pool->release($pg);
      if ($err) {
        $f->fail($err);
      } else {
        $f->done;
      }
    });

    return $f;
  });
}

# --- COPY ---------------------------------------------------------------------


sub copy_in {
  my ($self, $table, $columns, $coderef) = @_;

  my $col_list = join(', ', map { $self->sql_maker->_quote($_) } @$columns);
  my $quoted_table = $self->sql_maker->_quote($table);
  my $sql = "COPY $quoted_table ($col_list) FROM STDIN";

  return $self->pool->acquire->then(sub {
    my $pg = shift;
    my $f = Future->new;

    # EV::Pg fires the COPY query callback TWICE (see EV::Pg::Pg POD,
    # "A COPY command runs in two phases"): first with the string tag
    # "COPY_IN" when libpq has accepted the COPY command and the stream
    # is ready, then a second time with the final cmd_tuples result when
    # libpq has consumed the EOF marker, applied every row, and sent
    # CommandComplete + ReadyForQuery. The connection is NOT safe to
    # hand back to the pool until that second firing — releasing after
    # the first lets the next acquire race libpq's still-pending reply
    # and fail with "another command is already in progress". We track
    # which phase we're in with $phase and only release + complete the
    # Future on the second firing. (karr #13.)
    my $phase = 0;
    my $coderef_err;   # die from the user's coderef, captured to forward
                       # into the Future failure verbatim — libpq wraps
                       # whatever we pass to put_copy_end into its own
                       # "ERROR: COPY from stdin failed: …" envelope, so
                       # callers would see the wrapped string instead of
                       # their original die message unless we keep the
                       # raw $@. See t/18 "dying coderef" assertion.
    $pg->query($sql, sub {
      my ($status, $err) = @_;
      $phase++;

      # Second firing: server has finished the COPY, connection is back
      # at ReadyForQuery and safe to reuse.
      if ($phase == 2) {
        $self->pool->release($pg);
        if ($coderef_err) {
          $f->fail($coderef_err);
        } elsif ($err) {
          $f->fail($err);
        } else {
          $f->done($status);
        }
        return;
      }

      # First firing: COPY stream is ready. Either reject early on a
      # synchronous libpq error, or run the user coderef + end the
      # COPY. EV::Pg will then drive the second firing on its own when
      # the server reports completion.
      if ($err) {
        # Connection is unrecoverable in COPY mode — release anyway so
        # the pool slot isn't pinned; callers see the error via $f.
        $self->pool->release($pg);
        $f->fail($err);
        return;
      }

      my $put = sub {
        my $row = shift;
        my $line = join("\t", map { defined $_ ? $_ : '\N' } @$row) . "\n";
        $pg->put_copy_data($line);
      };

      my $eval_err = eval { $coderef->($put); 1 } ? undef : $@;
      if ($eval_err) {
        $coderef_err = $eval_err;
        # Pass the error to libpq so it aborts the COPY server-side,
        # but keep $coderef_err so we fail the Future with the raw
        # message instead of libpq's wrapped "ERROR: COPY from stdin
        # failed: …" envelope.
        my $rc = $pg->put_copy_end($eval_err);
        if (defined $rc && $rc < 0) {
          $self->pool->release($pg);
          $f->fail("put_copy_end failed");
          return;
        }
        # put_copy_end queued the EOF marker with the abort message;
        # second firing will fire $f with $coderef_err.
        return;
      }

      my $rc = $pg->put_copy_end;
      if (defined $rc && $rc < 0) {
        # put_copy_end could not even queue the EOF marker (hard libpq
        # error). Treat as COPY failure and complete the Future here
        # because the second firing will never arrive.
        $self->pool->release($pg);
        $f->fail("put_copy_end failed");
        return;
      }
      # put_copy_end queued (or was about to queue) the EOF marker.
      # Second callback firing will release the pool and complete $f.
    });

    return $f;
  });
}

# --- Async Deploy -------------------------------------------------------------
#
# WP4 note (karr #22): deploy_async / _execute_ddl_async / _drop_statements_for
# are kept here rather than hoisted into core. They are mostly generic
# (statement-splitting + sequential pinned _query_async inside a txn) and could
# be hoisted, but hoisting is a separate small core ticket and is NOT done here
# -- keeping the driver behaviour identical is the point of this thin-transport
# refactor. If/when core grows a generic deploy_async, this can inherit it.


sub deploy_async {
  my ($self, $schema, $opts) = @_;
  $opts //= {};

  # Generate the install DDL from the schema classes (synchronous, in-memory
  # — no DB roundtrips here; the whole point of routing through the DBIO
  # deploy pipeline is to keep DDL construction out of the storage layer).
  my $ddl = $schema->pg_install_ddl;

  # Optional DROP TABLE pre-pass for idempotent re-runs. Mirrors the
  # {add_drop_table => 1} option that DBIO::Schema->deploy accepts.
  if ($opts->{add_drop_table}) {
    $ddl = join("\n\n", _drop_statements_for($schema), $ddl);
  }

  # Run all DDL on a single pinned connection inside an async transaction.
  # PostgreSQL's transactional DDL means a failure on statement N of M
  # rolls back the previous N-1 — same semantics as
  # DBIO::Deploy::Base::_execute_ddl with _use_transactional_ddl(1),
  # just on the Future side of the wire.
  return $self->txn_do_async(sub {
    my ($ctx) = @_;
    return $self->_execute_ddl_async($ctx->txn_pg, $ddl);
  });
}

# Split a DDL string and execute each statement on a pinned EV::Pg
# connection, one at a time. Returns a Future that resolves on the last
# successful statement or fails on the first libpq error — the surrounding
# txn_do_async then COMMITs or ROLLBACKs accordingly.
#
# The recursion pumps exactly one DDL at a time on the pinned connection:
# libpq never has two in flight on the same handle. Each step waits for
# CommandComplete + ReadyForQuery before dispatching the next. The
# surrounding txn_do_async retain()s the returned Then-Future, which keeps
# the whole chain alive until COMMIT/ROLLBACK fires.
sub _execute_ddl_async {
  my ($self, $pg, $ddl) = @_;

  my @stmts = grep { !/^\s*--/ } _split_statements($ddl);

  my $recur;
  $recur = sub {
    my $stmt;
    unless (defined($stmt = shift @stmts)) {
      return Future->done;
    }
    my $f = Future->new;
    $self->_debug_query($stmt, []) if $self->{debug};
    $pg->query($stmt, sub {
      my (undef, $err) = @_;
      $err ? $f->fail($err) : $f->done;
    });
    return $f->then($recur);
  };
  return $recur->();
}

# Build DROP TABLE IF EXISTS ... CASCADE for every regular table in the
# schema. Skips views, virtual views, and scalar-ref names that aren't
# plain identifiers. Returns a single string the caller prepends to the
# install DDL.
sub _drop_statements_for {
  my ($schema) = @_;
  my @out;
  for my $name ($schema->sources) {
    my $source = $schema->source($name);
    next if $source->isa('DBIO::ResultSource::View');
    my $table = $source->name;
    next if ref $table;
    next if $table =~ /\s|\(/;
    push @out, sprintf 'DROP TABLE IF EXISTS %s CASCADE;', _quote_ident($table);
  }
  return join("\n\n", @out);
}

sub deploy {
  my $self = shift;
  return $self->deploy_async(@_)->get;
}

# --- Schema Integration -------------------------------------------------------
# schema / debug / connected / DESTROY and the sync CRUD/txn ->get fallbacks are
# inherited from DBIO::Storage::Async. disconnect is overridden to also tear down
# the dedicated LISTEN connection.

sub disconnect {
  my $self = shift;
  if ($self->{pool}) {
    $self->{pool}->shutdown;
    $self->{pool} = undef;
  }
  if ($self->{_listen_pg}) {
    $self->{_listen_pg}->finish;
    $self->{_listen_pg} = undef;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::Storage - Async PostgreSQL storage driver using EV::Pg

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The native C<ev> async transport for PostgreSQL (core ADR 0030 / 0031): a
B<thin transport> over L<EV::Pg>, a non-blocking libpq client that speaks the
async wire protocol directly. No DBI, no DBD::Pg, just raw libpq performance.

It resolves as the C<ev> async mode of L<DBIO::PostgreSQL::Storage> (registered
there via C<< register_async_mode( ev => ... ) >>), so a schema connected with
C<< { async => 'ev' } >> answers the six C<*_async> storage methods over EV::Pg
while the same schema keeps serving synchronous queries over DBI/DBD::Pg.

=head2 Thin transport: shared machinery is inherited

The B<Model-B orchestration> (ADR 0030 §4) is inherited unchanged from
L<DBIO::Storage::Async>: the CRUD runner (L<DBIO::Storage::Async/_run_crud>
with its pooled / pinned runners), the INSERT returned-columns mapping,
L<DBIO::Storage::Async/txn_do_async> bracketing, the L<DBIO::Storage::Async/pipeline>
scaffold, the C<sql_maker> plumbing and the sync C<< ->get >> fallbacks. This
class fills B<only> the loop-/wire-specific seams:

=over 4

=item * L</sql_maker_class> / L</_sql_maker_args> / L</_post_insert_sql> --
the PostgreSQL SQLMaker and its C< RETURNING *> insert suffix

=item * L</_transform_sql> -- C<?> to positional C<$N> placeholders, applied
B<internally> by the query seams (the core #70 / ADR 0032 C<?>-in contract)

=item * L</_query_async> / L</_query_async_pinned> -- native EV::Pg query
dispatch (pooled and pinned)

=item * L</_run_pool_connect_statement> -- synchronous connect-action replay on
a freshly-spawned EV::Pg pool connection (karr #68 seam)

=item * L</_pipeline_enter> / L</_pipeline_sync> / L</_pipeline_exit> -- libpq
pipeline mode

=item * L</connect_info> / L</_conninfo_string> -- the libpq conninfo transport
shape

=item * L</_txn_context_class> / L</_txn_conn_accessor> -- the pinned-connection
transaction context

=back

Because the extension-composition point is the core resolver, an async storage
layer composed onto this transport (core #70) inherits every CRUD/txn path for
free; the transport only has to advertise the wire capabilities it really
provides (see L</transport_capabilities>).

=head2 Transport value-add

Beyond the CRUD/txn contract this transport carries the PostgreSQL wire
features the abstract C<future_io> transport cannot: LISTEN/NOTIFY
(L</listen> / L</notify>), COPY (L</copy_in>) and libpq pipelining. These
override the base's croaking defaults and are declared in
L</transport_capabilities> so a layer that requires them composes cleanly
(and core croaks loudly, never silently dropping the feature, when it cannot).

=head1 METHODS

=head2 sql_maker_class

The L<DBIO::PostgreSQL::SQLMaker> subclass used to generate SQL. Shared with
the sync driver and the C<future_io> transport, so the maker keeps emitting
C<?> placeholders (translated to C<$N> internally by L</_transform_sql>).

=head2 _sql_maker_args

PostgreSQL SQLMaker construction args: double-quote identifier quoting, C<.>
name separator, LIMIT/OFFSET dialect. Matches the sync driver and the
C<future_io> transport.

=head2 _post_insert_sql

Returns C< RETURNING *> so an INSERT yields every populated column (autoinc PK
+ retrieve-on-insert defaults); the inherited runner folds the row onto the
supplied data to build the returned-columns hashref (ADR 0031 §3).

=head2 future_class

Returns C<'Future'> -- uses L<Future.pm|Future> from CPAN. Plain
L<Future/Future> C<< ->then >> callbacks auto-wrap a non-Future return value
into a resolved Future (ADR 0031 §4), so ResultSet/Row C<< *_async >>
callbacks that return plain values resolve without an explicit
C<< Future->done(...) >> wrap.

=head2 transport_capabilities

  my @caps = DBIO::PostgreSQL::EV::Storage->transport_capabilities;

Class method (see L<DBIO::Storage::Async/transport_capabilities>). Declares the
wire capabilities this transport really provides, so
L<DBIO::Storage::DBI/_async_storage> lets an async extension layer that requires
any of them compose onto it (and croaks naming the gap otherwise, rather than
silently dropping a feature). This transport provides:

=over 4

=item * C<on_connect_replay> -- its pool (L<DBIO::PostgreSQL::EV::Pool>, a
L<DBIO::Storage::PoolBase>) drives core's
L<DBIO::Storage::Async/_setup_pool_connection> on every freshly-spawned
connection, and L</_run_pool_connect_statement> replays the owning sync
storage's C<on_connect_do>/C<on_connect_call> against it (karr #68).

=item * C<listen> / C<notify> -- LISTEN/NOTIFY (L</listen>, L</unlisten>,
L</notify>).

=item * C<copy> -- COPY FROM STDIN bulk load (L</copy_in>).

=item * C<pipeline> -- libpq pipeline mode (L</_pipeline_enter> /
L</_pipeline_sync> / L</_pipeline_exit> under the inherited scaffold).

=back

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. C<%conninfo> is passed to L<EV::Pg> as libpq
connection parameters (host, dbname, user, ...). When the embedding sync
storage feeds its own DBI-form connect info
(C<< ['dbi:Pg:...', $user, $pass, \%attrs] >>) it is translated into the async
C<< [ \%conninfo, \%opts ] >> shape first. AccessBroker connect info
(C<< [ $broker ] >>) is detected and wired to the per-spawn credential provider
(the base broker seam), exactly as the sync path does.

This override (rather than the inherited base C<connect_info>) is retained
because the EV transport (a) folds the DBI-form DSN into libpq conninfo inline
and (b) also tears down the dedicated LISTEN connection on reconnect.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>): return
one fresh, storage-native libpq conninfo hash for a single new pool connection,
built from the current broker credentials via the inherited normalisation.

=head2 pool

Returns the L<DBIO::PostgreSQL::EV::Pool> connection pool, created lazily on
first access. The pool is wired with C<< storage => $self >> so its
core-shared spawn path (L<DBIO::Storage::PoolBase/_spawn_connection>) replays
the owning sync storage's connect actions on each new connection via
L</_run_pool_connect_statement> (karr #68). Fed the per-spawn
C<conninfo_provider> when an AccessBroker is attached, otherwise the static
conninfo string.

=head2 _txn_context_class

The pinned-connection transaction context the inherited
L<DBIO::Storage::Async/txn_do_async> hands to its coderef:
L<DBIO::PostgreSQL::EV::TransactionContext>.

=head2 _txn_conn_accessor

The constructor key the pinned connection is passed under -- C<pg>, matching
L<DBIO::PostgreSQL::EV::TransactionContext>.

=head2 _transform_sql

Transport-internal SQL shaping (core #70 / ADR 0032). Rewrite C<?> placeholders
to PostgreSQL positional C<$N>, skipping quoted literals / identifiers and the
JSONB C<@?> operator. Called first by L</_query_async> / L</_query_async_pinned>
on the raw C<sql_maker> output; idempotent on already-C<$N> SQL (no bare C<?>
to touch), so a C<$N> passthrough stays intact.

=head2 _query_async

Transport seam. Execute a query on a freshly-acquired pooled connection,
releasing it once the Future is ready. Returns a L<Future> of the raw result
rows (list of column arrayrefs for a result set, or the affected-row count for
plain DML -- ADR 0031 §3), exactly what the inherited C<_run_crud> expects.

Receives SQL in the C<sql_maker> C<?>-placeholder dialect and shapes it into
PostgreSQL's positional C<$N> B<internally> (via L</_transform_sql>) before it
reaches libpq -- the core #70 / ADR 0032 seam contract.

=head2 _query_async_pinned

Transport seam. Like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction. Shapes the incoming C<?>-dialect SQL internally via
L</_transform_sql> exactly as L</_query_async> does.

=head2 _run_pool_connect_statement

  $storage->_run_pool_connect_statement($conn, $sql, $attrs, @bind);

Native-backend override of the core connect-action runner seam
(L<DBIO::Storage::Async/_run_pool_connect_statement>). The base default drives a
blocking DBI C<do> and croaks on a non-DBI connection; an EV::Pg handle is
neither a C<< { dbh => $dbh } >> wrapper nor a do-capable DBI handle, so this
override drives the statement B<synchronously to completion> on that very
connection over the EV loop.

Called once per freshly-spawned pool connection from
L<DBIO::Storage::Async/_setup_pool_connection>, so the owning sync storage's
C<on_connect_do> / C<on_connect_call> (including C<connect_call_*> methods such
as an extension's C<connect_call_load_age>) replay on every new EV pool
connection, identical to the C<future_io> pool. The freshly-spawned EV::Pg
handle may still be mid-connect, so we first drive the loop until it is up, then
run the statement and drive the loop until it completes. C<$attrs> (the DBI
attribute hashref) has no EV::Pg analogue and is ignored.

=head2 _pipeline_enter

Open libpq pipeline mode on the connection.

=head2 _pipeline_sync

Flush the batched queries and resolve once the pipeline sync point has been
acknowledged. EV::Pg's C<pipeline_sync> takes a completion callback; we adapt it
to the Future the inherited scaffold expects.

=head2 _pipeline_exit

Close libpq pipeline mode on the connection.

=head2 listen

  $storage->listen($channel, sub {
      my ($channel, $payload, $sender_pid) = @_;
      # Handle notification
  });

Subscribe to PostgreSQL LISTEN/NOTIFY notifications on the given channel. The
callback fires each time a notification arrives. Transport value-add: overrides
the base's croaking default (declared as the C<listen> capability).

=head2 unlisten

  $storage->unlisten($channel);

Unsubscribe from a notification channel.

=head2 notify

  $storage->notify($channel, $payload?);

Send a PostgreSQL NOTIFY to the given channel with an optional payload.
Returns a L<Future> that resolves when the NOTIFY has been dispatched.

Unlike L</listen>, this does not require a dedicated connection — it uses
a pooled connection from the normal pool.

=head2 copy_in

  $storage->copy_in($table, \@columns, sub {
      my ($put) = @_;
      $put->(['Miles Davis', 'Jazz']);
      $put->(['John Coltrane', 'Jazz']);
  });

Bulk load data via PostgreSQL COPY FROM STDIN. The callback receives a writer
function that accepts arrayrefs of column values. Transport value-add:
overrides the base's croaking default (declared as the C<copy> capability).

=head2 deploy_async

  my $future = $storage->deploy_async($schema, \%opts);
  $future->get;

Deploys C<$schema> via the native DBIO deploy pipeline, executing every
DDL statement on EV::Pg inside a single async transaction. The Future
resolves on success (COMMIT committed) or fails on the first DDL error
(ROLLBACK rolled the whole batch back).

C<%opts>:

=over 4

=item add_drop_table => 1

Prepend C<DROP TABLE IF EXISTS ... CASCADE> for every source in the
schema, so a re-run on a populated database is idempotent. Default 0.

=back

Requires C<$schema> to expose C<pg_install_ddl> — typically a
L<DBIO::PostgreSQL> schema (e.g. via C<< use DBIO Schema => -pg >>). The
DDL is generated locally from the schema classes (no DB roundtrips for
DDL construction); only the execution hits libpq.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
