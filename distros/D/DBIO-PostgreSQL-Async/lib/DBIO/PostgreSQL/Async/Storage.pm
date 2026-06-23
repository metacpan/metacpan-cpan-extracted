package DBIO::PostgreSQL::Async::Storage;
# ABSTRACT: Async PostgreSQL storage driver using EV::Pg

use strict;
use warnings;
use base 'DBIO::Storage::Async';

use Carp 'croak';
use Future;
use DBIO::PostgreSQL::SQLMaker;
use DBIO::PostgreSQL::Async::ConnectInfo 'conninfo_string';
use DBIO::PostgreSQL::Async::Pool;
use DBIO::PostgreSQL::Async::TransactionContext;
use namespace::clean;


sub new {
  my ($class, $schema, $args) = @_;
  my $self = bless {
    schema          => $schema,
    pool            => undef,
    connect_info    => undef,
    sql_maker       => undef,
    sql_maker_class => 'DBIO::PostgreSQL::SQLMaker',
    _prepared_cache => {},
    _listeners      => {},
    _conninfo_provider => undef,
    debug           => $ENV{DBIO_TRACE} || 0,
    debugobj        => undef,
  }, $class;
  $self;
}


sub future_class { 'Future' }


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
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

sub _current_async_connect_info {
  my ($self, $mode) = @_;

  my $connect_info = $self->current_access_broker_connect_info($mode);
  return [$connect_info, {}] if $connect_info && ref $connect_info eq 'HASH';
  return $connect_info if $connect_info;

  return [ $self->{_conninfo}, $self->{_opts} || {} ];
}

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
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::PostgreSQL::Async pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->_conninfo_string;
    }

    DBIO::PostgreSQL::Async::Pool->new(%args);
  };
}

sub _conninfo_string {
  my ($self, $ci) = @_;
  $ci = $self->_current_async_connect_info($self->access_broker_mode)->[0]
    if ! defined $ci;
  return conninfo_string($ci);
}

# --- SQL Generation ---


sub sql_maker {
  my $self = shift;
  $self->{sql_maker} ||= do {
    my $class = $self->{sql_maker_class};
    $class->new(
      quote_char     => '"',
      name_sep       => '.',
      limit_dialect  => 'LimitOffset',
    );
  };
}

sub _generate_sql {
  my ($self, $op, @args) = @_;
  my $sm = $self->sql_maker;
  my $method = {
    select        => 'select',
    select_single => 'select',
    insert        => 'insert',
    update        => 'update',
    delete        => 'delete',
  }->{$op} or croak "Unknown operation: $op";

  return $sm->$method(@args);
}

# --- Async Query Execution ---


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

# Build SQL for a CRUD op and execute it through $runner, a coderef
# that takes ($sql, \@bind) and returns a Future of result rows.
# All the PG-specific shaping (RETURNING on insert, first-row for
# select_single) lives here exactly once, so the pooled path
# (_pool_runner) and the pinned txn path (a pinned runner supplied by
# TransactionContext) share identical behavior.
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
    my ($sql, @bind) = $sm->insert(@args);
    # PostgreSQL RETURNING for auto-generated columns
    $sql .= ' RETURNING *' unless $sql =~ /RETURNING/i;
    return $runner->($sql, \@bind);
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

# Runner that executes on a freshly-acquired pooled connection and
# releases it when done. This is the normal (non-transactional) path.
sub _pool_runner {
  my $self = shift;
  return sub {
    my ($sql, $bind) = @_;
    return $self->_query_async($sql, $bind);
  };
}

# Runner that executes on a pinned connection without releasing it.
# Used by TransactionContext so CRUD inside a txn hits the same
# connection that BEGIN/COMMIT ran on.
sub _pinned_runner {
  my ($self, $pg) = @_;
  return sub {
    my ($sql, $bind) = @_;
    return $self->_query_async_pinned($pg, $sql, $bind);
  };
}

# Build SQL and run a CRUD op on a pinned connection. Entry point used
# by TransactionContext; shares _run_crud's builders/post-processing.
sub _run_crud_pinned {
  my ($self, $op, $pg, @args) = @_;
  return $self->_run_crud($op, $self->_pinned_runner($pg), @args);
}

# Low-level async query dispatch

sub _query_async {
  my ($self, $sql, $bind) = @_;
  $bind //= [];

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

# Like _query_async but does NOT release the connection.
# Used for queries within a pinned transaction.
sub _query_async_pinned {
  my ($self, $pg, $sql, $bind) = @_;
  $bind //= [];

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

# --- Transactions ---


sub txn_do_async {
  my ($self, $coderef, @args) = @_;

  return $self->pool->acquire_txn->then(sub {
    my $pg = shift;

    my $txn_ctx = DBIO::PostgreSQL::Async::TransactionContext->new(
      storage => $self,
      pg      => $pg,
    );

    my $f = Future->new;

    $pg->query('BEGIN', sub {
      my (undef, $err) = @_;
      if ($err) {
        $self->pool->release($pg);
        $f->fail("BEGIN failed: $err");
        return;
      }

      my $inner = eval { $coderef->($txn_ctx, @args) };
      if ($@) {
        my $error = $@;
        $pg->query('ROLLBACK', sub {
          $self->pool->release($pg);
          $f->fail($error);
        });
        return;
      }

      # If coderef returned a Future, chain COMMIT/ROLLBACK
      if (ref $inner && $inner->can('then')) {
        $inner->then(sub {
          my @result = @_;
          my $commit_f = Future->new;
          $pg->query('COMMIT', sub {
            my (undef, $cerr) = @_;
            $self->pool->release($pg);
            if ($cerr) {
              $commit_f->fail("COMMIT failed: $cerr");
            } else {
              $commit_f->done(@result);
            }
          });
          return $commit_f;
        })->catch(sub {
          my $error = shift;
          my $rb_f = Future->new;
          $pg->query('ROLLBACK', sub {
            $self->pool->release($pg);
            $rb_f->fail($error);
          });
          return $rb_f;
        })->on_done(sub { $f->done(@_) })
          ->on_fail(sub { $f->fail(@_) });
      } else {
        # Coderef returned a plain value — commit immediately
        $pg->query('COMMIT', sub {
          my (undef, $cerr) = @_;
          $self->pool->release($pg);
          if ($cerr) {
            $f->fail("COMMIT failed: $cerr");
          } else {
            $f->done($inner);
          }
        });
      }
    });

    return $f;
  });
}

# --- Pipeline Mode ---


sub pipeline {
  my ($self, $coderef) = @_;

  return $self->pool->acquire->then(sub {
    my $pg = shift;
    $pg->enter_pipeline;

    my $result = eval { $coderef->($self) };
    my $err = $@;

    if ($err) {
      $pg->exit_pipeline;
      $self->pool->release($pg);
      return Future->fail($err);
    }

    # Sync the pipeline — callback fires when all results are in
    my $f = Future->new;
    $pg->pipeline_sync(sub {
      $pg->exit_pipeline;
      $self->pool->release($pg);
      if (ref $result && $result->can('then')) {
        $result->on_done(sub { $f->done(@_) })
               ->on_fail(sub { $f->fail(@_) });
      } else {
        $f->done($result);
      }
    });

    return $f;
  });
}

# --- LISTEN/NOTIFY ---


sub listen {
  my ($self, $channel, $cb) = @_;

  $self->{_listeners}{$channel} = $cb;

  # Use a dedicated connection for LISTEN (not from the pool).
  # EV::Pg->new returns before the socket is actually connected; query()
  # dispatched on a not-yet-connected handle throws "not connected".
  # We buffer LISTEN/UNLISTEN until on_connect fires and then flush.
  $self->{_listen_pg} ||= do {
    require EV::Pg;
    $self->{_listen_pending} = [];
    $self->{_listen_connected} = 0;
    my $pg = EV::Pg->new(
      conninfo   => $self->_conninfo_string,
      keep_alive => 1,
      on_connect => sub {
        $self->{_listen_connected} = 1;
        my $q = delete $self->{_listen_pending} || [];
        $self->{_listen_pending} = [];
        $self->{_listen_pg}->query($_, sub {}) for @$q;
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
  if ($self->{_listen_connected}) {
    $self->{_listen_pg}->query($sql, sub {});
  } else {
    push @{ $self->{_listen_pending} }, $sql;
  }
}


sub unlisten {
  my ($self, $channel) = @_;
  delete $self->{_listeners}{$channel};
  if ($self->{_listen_pg}) {
    my $quoted = $self->sql_maker->_quote($channel);
    my $sql = "UNLISTEN $quoted";
    if ($self->{_listen_connected}) {
      $self->{_listen_pg}->query($sql, sub {});
    } else {
      push @{ $self->{_listen_pending} }, $sql;
    }
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

# --- COPY ---


sub copy_in {
  my ($self, $table, $columns, $coderef) = @_;

  my $col_list = join(', ', map { $self->sql_maker->_quote($_) } @$columns);
  my $quoted_table = $self->sql_maker->_quote($table);
  my $sql = "COPY $quoted_table ($col_list) FROM STDIN";

  return $self->pool->acquire->then(sub {
    my $pg = shift;
    my $f = Future->new;

    $pg->query($sql, sub {
      my ($status, $err) = @_;
      if ($err) {
        $self->pool->release($pg);
        $f->fail($err);
        return;
      }

      my $put = sub {
        my $row = shift;
        my $line = join("\t", map { defined $_ ? $_ : '\N' } @$row) . "\n";
        $pg->put_copy_data($line);
      };

      eval { $coderef->($put) };
      if ($@) {
        $pg->put_copy_end($@);
        $self->pool->release($pg);
        $f->fail($@);
      } else {
        $pg->put_copy_end;
        $self->pool->release($pg);
        $f->done(1);
      }
    });

    return $f;
  });
}

# --- Sync Fallbacks ---
# These allow sync methods (->all, ->first etc.) to work
# by blocking the event loop. Useful for scripts/migrations.

sub select {
  my $self = shift;
  return $self->select_async(@_)->get;
}

sub select_single {
  my $self = shift;
  return $self->select_single_async(@_)->get;
}

sub insert {
  my $self = shift;
  return $self->insert_async(@_)->get;
}

sub update {
  my $self = shift;
  return $self->update_async(@_)->get;
}

sub delete {
  my $self = shift;
  return $self->delete_async(@_)->get;
}

sub txn_do {
  my $self = shift;
  return $self->txn_do_async(@_)->get;
}

# --- Schema Integration ---

sub schema { $_[0]->{schema} }
sub debug  { $_[0]->{debug} }

sub connected { defined $_[0]->{pool} && $_[0]->pool->available > 0 }

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

sub DESTROY {
  my $self = shift;
  $self->disconnect if $self->{pool};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Async::Storage - Async PostgreSQL storage driver using EV::Pg

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Implements L<DBIO::Storage::Async> using L<EV::Pg> — a non-blocking
PostgreSQL client that speaks libpq's async protocol directly.
No DBI, no DBD::Pg, just raw libpq performance.

Features:

=over 4

=item * Pipeline mode — batch queries in a single network round-trip

=item * Prepared statement caching

=item * LISTEN/NOTIFY for real-time event streaming

=item * COPY IN/OUT for bulk data transfer

=item * Connection pooling with transaction pinning

=back

=head1 METHODS

=head2 future_class

Returns C<'Future'> — uses L<Future.pm|Future> from CPAN.

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. C<%conninfo> is passed directly to
L<EV::Pg> as libpq connection parameters (host, dbname, user, etc.).

=head2 pool

Returns the L<DBIO::PostgreSQL::Async::Pool> connection pool.
Created lazily on first access.

=head2 sql_maker

Returns the L<DBIO::PostgreSQL::SQLMaker> instance, configured for PostgreSQL
(double-quote quoting, LIMIT/OFFSET dialect).

=head2 select_async

  my $future = $storage->select_async($source, $select, $where, $attrs);

Execute a SELECT query asynchronously. Returns a L<Future> that
resolves with the result rows (arrayrefs).

=head2 select_single_async

Like L</select_async> but returns only the first row.

=head2 insert_async

  my $future = $storage->insert_async($source, \%vals);

=head2 update_async

  my $future = $storage->update_async($source, \%vals, \%where);

=head2 delete_async

  my $future = $storage->delete_async($source, \%where);

=head2 txn_do_async

  my $future = $storage->txn_do_async(sub {
      my ($storage) = @_;
      # All queries in here use the same connection
      $storage->insert_async(...)->then(sub { ... });
  });

Acquires a connection from the pool, issues BEGIN, executes the
coderef, and issues COMMIT on success or ROLLBACK on Future failure.

=head2 pipeline

  my $future = $storage->pipeline(sub {
      my ($storage) = @_;
      my @futures;
      push @futures, $storage->insert_async('artist', { name => $_ })
          for @names;
      return Future->needs_all(@futures);
  });

Execute multiple queries in pipeline mode. All queries are batched
and sent in a single network round-trip for maximum throughput.

=head2 listen

  $storage->listen($channel, sub {
      my ($channel, $payload, $sender_pid) = @_;
      # Handle notification
  });

Subscribe to PostgreSQL LISTEN/NOTIFY notifications on the given
channel. The callback fires each time a notification arrives.

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

Bulk load data via PostgreSQL COPY FROM STDIN. The callback receives
a writer function that accepts arrayrefs of column values.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
