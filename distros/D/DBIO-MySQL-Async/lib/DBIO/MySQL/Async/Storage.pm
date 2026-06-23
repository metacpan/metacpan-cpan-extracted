package DBIO::MySQL::Async::Storage;
# ABSTRACT: Async MySQL/MariaDB storage driver using EV::MariaDB

use strict;
use warnings;
use base 'DBIO::Storage::Async';

use Carp 'croak';
use Future;
use DBIO::MySQL::SQLMaker;
use namespace::clean;


my $PREPARED_COUNTER = 0;

sub new {
  my ($class, $schema, $args) = @_;
  my $self = bless {
    schema          => $schema,
    pool            => undef,
    executor        => undef,
    connect_info    => undef,
    sql_maker       => undef,
    sql_maker_class => 'DBIO::MySQL::SQLMaker',
    _prepared_cache => {},
    _conninfo_provider => undef,
    _last_insert_id => undef,
    debug           => $ENV{DBIO_TRACE} || 0,
    debugobj        => undef,
  }, $class;
  $self;
}


sub future_class { 'Future' }


sub connect_info {
  my ($self, $info) = @_;
  if ($info) {
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

sub _current_async_connect_info {
  my ($self, $mode) = @_;

  my $connect_info = $self->current_access_broker_connect_info($mode);
  return [$connect_info, {}] if $connect_info && ref $connect_info eq 'HASH';
  return $connect_info if $connect_info;

  return [ $self->{_conninfo}, $self->{_opts} || {} ];
}

# Driver seam hook for the inherited async AccessBroker mechanics
# (DBIO::Storage::Async::_setup_access_broker installs a conninfo_provider
# that invokes this once per pool spawn). Returns ONE fresh, normalized,
# EV::MariaDB-native conninfo hashref — the shape the pool's identity
# _transform_conninfo passes straight to _create_connection.
sub _async_broker_conninfo {
  my ($self, $mode) = @_;

  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_current_async_connect_info($mode)
  );
  return $conninfo;
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
    # MySQL uses 'database', not 'dbname'
    $conninfo->{database} = delete $conninfo->{dbname} if exists $conninfo->{dbname};
  }

  return ($conninfo, $pool_size, $opts);
}


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    require DBIO::MySQL::Async::Pool;
    my %args = (
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::MySQL::Async pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->{_conninfo};
    }

    my $pool = DBIO::MySQL::Async::Pool->new(%args);
    $self->{executor} = DBIO::MySQL::Async::QueryExecutor->new(
      pool  => $pool,
      debug => $self->{debug},
    );
    $pool;
  };
}

sub _conninfo_hash {
  my ($self, $ci) = @_;
  # Use already-normalized stored conninfo; only do fallback resolution
  # when called in contexts where _conninfo is not yet set
  my $conninfo = defined($ci) ? $ci : $self->{_conninfo};
  return unless defined $conninfo;
  return $conninfo if ref $conninfo ne 'HASH';
  # Already normalized by _normalize_async_connect_info; return as-is
  return $conninfo;
}

# --- SQL Generation ---


sub sql_maker {
  my $self = shift;
  $self->{sql_maker} ||= do {
    my $class = $self->{sql_maker_class};
    $class->new(
      quote_char     => '`',
      name_sep       => '.',
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
  return $self->_run_crud('select', undef, @_);
}


sub select_single_async {
  my $self = shift;
  return $self->_run_crud('select_single', undef, @_);
}


sub insert_async {
  my $self = shift;
  return $self->_run_crud('insert', undef, @_);
}


sub update_async {
  my $self = shift;
  return $self->_run_crud('update', undef, @_);
}


sub delete_async {
  my $self = shift;
  return $self->_run_crud('delete', undef, @_);
}

# Build SQL for a CRUD op and run it on a connection. When $mdb is
# undef, a pooled connection is acquired and released around the query;
# when $mdb is given, the query runs pinned on that connection (no
# release) — used by the transaction context so all CRUD inside a
# txn_do_async hits the BEGIN/COMMIT connection.
sub _run_crud {
  my ($self, $op, $mdb, @args) = @_;

  if ($op eq 'select_single') {
    my ($sql, @bind) = $self->sql_maker->select(@args);
    return $self->_run_on_conn($mdb, sub {
      my $conn = shift;
      $self->_query_on($conn, $sql, \@bind);
    })->then(sub {
      my @rows = @_;
      return @rows ? $rows[0] : undef;
    });
  }

  if ($op eq 'insert') {
    my ($sql, @bind) = $self->sql_maker->insert(@args);
    return $self->_run_on_conn($mdb, sub {
      my $conn = shift;
      $self->_query_on($conn, $sql, \@bind)->then(sub {
        # LAST_INSERT_ID() must run on the SAME connection as the INSERT.
        my $lii_f = $self->_query_on($conn, 'SELECT LAST_INSERT_ID()', []);
        $lii_f->on_done(sub {
          my @rows = @_;
          $self->{_last_insert_id} = $rows[0]->[0] if @rows && defined $rows[0]->[0];
        });
        return $lii_f;
      });
    });
  }

  my $method = { select => 'select', update => 'update', delete => 'delete' }->{$op}
    or croak "Unknown CRUD operation: $op";
  my ($sql, @bind) = $self->sql_maker->$method(@args);
  return $self->_run_on_conn($mdb, sub {
    my $conn = shift;
    $self->_query_on($conn, $sql, \@bind);
  });
}

# Resolve a connection and run $cb->($conn) on it. When $mdb is given the
# connection is pinned: $cb runs on it and it is NOT released (the txn
# owner manages its lifecycle). When $mdb is undef a pooled connection is
# acquired via acquire->then — honoring the pool's waiter queue when the
# pool is full — and released once $cb's Future is ready, on success or
# failure, so connections never leak.
sub _run_on_conn {
  my ($self, $mdb, $cb) = @_;

  if (defined $mdb) {
    return Future->call(sub { $cb->($mdb) });
  }

  return $self->pool->acquire->then(sub {
    my $conn = shift;
    my $f = Future->call(sub { $cb->($conn) });
    $f->on_ready(sub { $self->pool->release($conn) });
    return $f;
  });
}

# Run a single query on a concrete connection. No acquire, no release.
sub _query_on {
  my ($self, $mdb, $sql, $bind) = @_;
  $bind //= [];
  $self->_debug_query($sql, $bind) if $self->{debug};
  return $self->{executor}->execute($mdb, $sql, $bind);
}

# Low-level async query dispatch on a freshly-acquired pooled connection,
# released once ready. Retained for callers that already hold raw SQL.
sub _query_async {
  my ($self, $sql, $bind) = @_;
  return $self->_run_on_conn(undef, sub {
    my $conn = shift;
    $self->_query_on($conn, $sql, $bind);
  });
}

# Run a query on a specific connection without releasing it back to the
# pool. Used by the transaction context for the pinned connection and
# for sub-queries that must share a connection (e.g. LAST_INSERT_ID).
sub _query_async_pinned {
  my ($self, $mdb, $sql, $bind) = @_;
  return $self->_query_on($mdb, $sql, $bind);
}

# Build SQL and run a CRUD op pinned on a given connection. Entry point
# used by TransactionContext so CRUD inside a txn hits the same
# connection BEGIN/COMMIT ran on, without duplicating SQL generation.
sub _run_crud_pinned {
  my ($self, $op, $mdb, @args) = @_;
  return $self->_run_crud($op, $mdb, @args);
}

sub _debug_query {
  my ($self, $sql, $bind) = @_;
  my $bind_str = join(', ', map { defined $_ ? "'$_'" : 'NULL' } @$bind);
  warn "$sql: $bind_str\n";
}

# --- Transactions ---


sub txn_do_async {
  my ($self, $coderef, @args) = @_;

  require DBIO::MySQL::Async::TransactionContext;

  return $self->pool->acquire_txn->then(sub {
    my $mdb = shift;

    my $txn_ctx = DBIO::MySQL::Async::TransactionContext->new(
      storage => $self,
      mdb     => $mdb,
    );

    my $f = Future->new;

    $mdb->query('BEGIN', sub {
      my (undef, $err) = @_;
      if ($err) {
        $self->pool->release($mdb);
        $f->fail("BEGIN failed: $err");
        return;
      }

      my $inner = eval { $coderef->($txn_ctx, @args) };
      if ($@) {
        my $error = $@;
        $mdb->query('ROLLBACK', sub {
          $self->pool->release($mdb);
          $f->fail($error);
        });
        return;
      }

      # If coderef returned a Future, chain COMMIT/ROLLBACK
      if (ref $inner && $inner->can('then')) {
        $inner->then(sub {
          my @result = @_;
          my $commit_f = Future->new;
          $mdb->query('COMMIT', sub {
            my (undef, $cerr) = @_;
            $self->pool->release($mdb);
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
          $mdb->query('ROLLBACK', sub {
            $self->pool->release($mdb);
            $rb_f->fail($error);
          });
          return $rb_f;
        })->on_done(sub { $f->done(@_) })
          ->on_fail(sub { $f->fail(@_) });
      } else {
        # Coderef returned a plain value — commit immediately
        $mdb->query('COMMIT', sub {
          my (undef, $cerr) = @_;
          $self->pool->release($mdb);
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
    my $mdb = shift;
    $mdb->query('SET autocommit=0');  # MariaDB pipelining needs explicit tx mode

    my $result = eval { $coderef->($self) };
    my $err = $@;

    if ($err) {
      $mdb->query('ROLLBACK', sub {});  # we don't care about the result here
      $self->pool->release($mdb);
      return Future->fail($err);
    }

    # Sync the pipeline — callback fires when all results are in
    my $f = Future->new;
    $mdb->query('COMMIT', sub {
      $mdb->query('SET autocommit=1', sub {});  # reset
      $self->pool->release($mdb);
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


sub in_txn { 0 }


sub last_insert_id {
  my ($self, $source, @cols) = @_;
  return $self->{_last_insert_id};
}

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

DBIO::MySQL::Async::Storage - Async MySQL/MariaDB storage driver using EV::MariaDB

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Implements L<DBIO::Storage::Async> using L<EV::MariaDB> — a non-blocking
MariaDB/MySQL client that speaks the MariaDB C client library directly.
No DBI, no DBD::MySQL, just raw MariaDB performance.

Features:

=over 4

=item * Pipeline mode — batch queries in a single network round-trip

=item * Prepared statement caching

=item * Connection pooling with transaction pinning

=back

=head1 METHODS

=head2 future_class

Returns C<'Future'> — uses L<Future.pm|Future> from CPAN.

=head2 connect_info

  $storage->connect_info([ \%conninfo, \%opts ]);

Set connection parameters. C<%conninfo> is passed directly to
L<EV::MariaDB> as connection parameters (host, user, password, database, etc.).

=head2 pool

Returns the L<DBIO::MySQL::Async::Pool> connection pool.
Created lazily on first access.

=head2 sql_maker

Returns the L<DBIO::MySQL::SQLMaker> instance, configured for MySQL
(backtick quoting, MySQL C<LIMIT offset, rows> pagination).

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
EV::MariaDB supports up to 64 pipelined queries.

=head2 in_txn

Returns true when invoked on a L<DBIO::MySQL::Async::TransactionContext>
(the coderef inside L</txn_do_async>), false on the storage itself.
Used by sub-queries that need to know whether the current connection
is pinned.

=head2 last_insert_id

  my $id = $storage->last_insert_id;

Returns the auto-increment value from the last INSERT performed
on this storage instance. Valid after L<insert_async|/insert_async>
or L<insert|/insert> succeeds.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
