package DBIO::PostgreSQL::Age::Storage::Async;
# ABSTRACT: Floating async storage layer for Apache AGE (cypher_async)

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Age::Storage ();


sub required_transport_capabilities { qw(on_connect_replay) }


sub cypher_async {
  my ($self, $graph, $query, $columns, $params, $opts) = @_;

  # Reuse the sync layer's PURE builder by composition: it only needs
  # $self->throw_exception (resolved through the composed transport MRO) and the
  # sync file's lexical JSON encoder, so calling it fully-qualified is DRY and
  # stays in lock-step with sync cypher().
  my ($sql, $bind) = DBIO::PostgreSQL::Age::Storage::_cypher_sql_bind(
    $self, $graph, $query, $columns, $params,
  );

  my $decode = $opts && $opts->{auto_decode};

  # Pass the '?'-placeholder SQL straight to the transport: shaping '?' to the
  # wire dialect (e.g. DBD::Pg's $N) is the transport's concern, applied inside
  # its _query_async (core karr #70 / ADR 0032 '?'-seam). The dollar-quoted cypher
  # body and any '$name' reference are not placeholders and survive untouched.
  return $self->_query_async($sql, $bind)->then(sub {
    my @rows = @_;   # raw row arrayrefs, in the declared column order

    my @out;
    for my $raw (@rows) {
      my %row;
      # AGE returns columns named exactly as declared in "AS ($col agtype, ...)",
      # so zipping @$columns reproduces the sync {Slice => {}} hashref shape.
      @row{ @$columns } = @$raw;

      if ($decode) {
        $row{$_} = DBIO::PostgreSQL::Age::Storage::decode_agtype($self, $row{$_})
          for keys %row;
      }

      push @out, \%row;
    }

    # Resolve to the arrayref sync cypher() returns, so cypher_async(...)->get
    # equals cypher(...). done(\@out) keeps the arrayref intact through ->then.
    return $self->future_class->done(\@out);
  });
}


sub create_graph_async {
  my ($self, $name) = @_;
  return $self->_query_async(
    'SELECT * FROM ag_catalog.create_graph(?)', [ $name ],
  );
}


sub drop_graph_async {
  my ($self, $name, $cascade) = @_;
  return $self->_query_async(
    'SELECT * FROM ag_catalog.drop_graph(?, ?)', [ $name, $cascade ? 1 : 0 ],
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Storage::Async - Floating async storage layer for Apache AGE (cypher_async)

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  # Composed automatically for an Age schema opened in ANY async mode whose
  # transport can replay LOAD 'age' -- future_io, ev, ....

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age', async => 'future_io' },  # or 'ev'
  );

  my $async = $schema->storage->async;   # the composed async backend

  $async->create_graph_async('social')->then(sub {
    $async->cypher_async(
      'social',
      q{ MATCH (n:Person {name: $name}) RETURN n },
      ['node'],
      { name => 'Alice' },
      { auto_decode => 1 },
    );
  })->then(sub {
    my ($rows) = @_;   # arrayref of hashrefs, one key per column, already decoded
    ...
  });

=head1 DESCRIPTION

The B<floating async storage layer> for L<Apache AGE|https://age.apache.org/>.
It is a plain method package -- B<not> a transport and B<not> a subclass of any
transport. Core's storage-layer composition mirrors the registered
sync Age layer onto its async sibling by convention
(C<< DBIO::PostgreSQL::Age::Storage >> -> C<< ...::Async >>) and composes B<this>
package (C3) OVER whatever transport the connection's async mode resolves:
L<DBIO::PostgreSQL::Storage::Async> for C<future_io>,
L<DBIO::PostgreSQL::EV::Storage> for C<ev>. The composed backend isa both this
layer and that transport, so C<cypher_async> rides every capable transport
without a per-transport class.

=head2 Required transport capability

AGE mandates C<LOAD 'age'> (and putting C<ag_catalog> on the C<search_path>) on B<every>
pooled connection, replayed through core's pool C<on_connect> seam. This layer
therefore declares C<on_connect_replay> as a
L</required_transport_capabilities>; core's capability gate croaks loudly if a
schema tries to compose AGE over a transport that cannot replay connect actions,
rather than silently losing the session setup. Both shipped PostgreSQL async
transports advertise C<on_connect_replay>.

=head2 Separate sync and async entry points

Graph queries have two entry points, on the two composed storages:

=over 4

=item * B<sync> -- C<< $schema->storage->cypher(...) >>, on the composed sync
storage (the L<DBIO::PostgreSQL::Age::Storage> layer over
L<DBIO::PostgreSQL::Storage>, a L<DBIO::Storage::DBI>), returns an arrayref of
hashrefs.

=item * B<async> -- C<< $schema->storage->async->cypher_async(...) >>, on the
composed async backend (this layer over a L<DBIO::Storage::Async> transport),
returns a L<Future> resolving to the same arrayref of hashrefs. As a convenience
the composed sync storage also carries a C<cypher_async> dispatcher (see
L<DBIO::PostgreSQL::Age::Storage/cypher_async>): C<< $schema->storage->cypher_async(...) >>
routes to this backend on an async connection and degrades in-process under
C<< { async => 'immediate' } >>, exactly like the core CRUD C<*_async> methods.

=back

The sync and async surfaces stay B<separate by design>: this layer is I<not> a
subclass of L<DBIO::PostgreSQL::Age::Storage>, and it never C<use base>s a
storage. Welding the blocking DBI machinery (C<dbh>, C<dbh_do>, C<txn_do>, the
driver registry) onto an async transport is exactly what the layer model avoids
-- the reason is unchanged, but the B<mechanism> is now composition-by-core, not
a parallel-inheritance adapter bolted to one transport. What crosses between the
two surfaces is only the two pure, DB-free helpers of the sync layer -- the SQL
builder C<_cypher_sql_bind> and C<decode_agtype> -- reused by B<composition>,
called as class-level helpers so both entry points build identical SQL and
decode identically. C<auto_decode> therefore behaves identically on both.

=head2 The graph methods are pool-only, not transaction-pinned

C<cypher_async>, C<create_graph_async> and C<drop_graph_async> all run through
the transport's B<pooled> query seam C<_query_async>, which takes a connection
out of the pool for the statement and hands it back when the Future resolves.
None of the three takes a connection or a context argument, so there is no way
to hand them the connection a transaction is pinned to. A pinned seam does
exist one level down -- C<< $storage->_query_async_pinned($conn, $sql, $bind) >>,
the required transport seam core's own pinned CRUD runs on
(L<DBIO::Storage::Async/_query_async_pinned>), implemented by both transports
this layer composes over -- but nothing on this layer reaches it. The
C<cypher_async> dispatcher on the composed B<sync> storage
(L<DBIO::PostgreSQL::Age::Storage/cypher_async>) is the same path: on an async
connection it routes to this pooled backend.

Inside a L<DBIO::Storage::Async/txn_do_async> body a graph method therefore runs
on a B<sibling> pool connection, outside the transaction:

  $schema->storage->txn_do_async(sub {
    my ($ctx) = @_;

    # WRONG: runs on a sibling pool connection OUTSIDE this transaction. It
    # does not see the transaction's uncommitted writes, its own writes commit
    # on their own, and a ROLLBACK does not take them back.
    return $schema->storage->async->cypher_async(
      'social', q{ CREATE (:Person {name: $name}) RETURN 1 }, ['ok'],
      { name => 'Alice' },
    );
  });

B<Nothing warns.> The query succeeds, on the wrong connection. At the default
C<pool_size> of 5 it simply runs beside the transaction; with
C<< pool_size => 1 >> it does not run at all while the transaction is open --
the pool has no second connection to hand out, so the acquire is queued as a
waiter that only a C<release> can resolve, and C<txn_do_async> releases its
connection after the body's Future has resolved.

One layer up this is exactly the failure ADR 0045 closed for L<DBIO::ResultSet>,
L<DBIO::Row> and L<DBIO::ResultSetColumn>, by binding them to the pinned context
explicitly (L<DBIO::ResultSet/with_context>). The graph surface has no such
binding, and cannot borrow that one. The object a C<txn_do_async> coderef is
handed -- L<DBIO::Async::TransactionContext> on C<future_io>, which inherits
the generic L<DBIO::Storage::Async::TransactionContext>, and
L<DBIO::PostgreSQL::EV::TransactionContext> on C<ev>, which mirrors its surface
rather than inheriting it; L<DBIO::Storage::Async::PipelineContext> for a
L<DBIO::Storage::Async/pipeline> batch -- carries a fixed surface: the five
CRUD C<*_async> methods, their blocking twins, a pinned C<_query_async>, and a
handful of delegations. It does B<not> carry C<cypher_async>, because storage
layers are composed onto the B<storage>, never onto a context -- so
C<< $ctx->cypher_async(...) >> dies. Calling this layer's sub with the context
as invocant is no way around that either: the body also needs C<future_class>,
and C<_cypher_sql_bind> needs C<throw_exception>, neither of which the
transaction context answers.

So B<do not use the async graph methods inside C<txn_do_async> or C<pipeline>>.
Graph work that has to be transactional belongs on the B<sync> surface, where
C<< $schema->txn_do(sub { $schema->storage->cypher(...) }) >> runs on the
transaction's own C<dbh>. Whether the async surface should grow a pinned path is
an open design question rather than an oversight: the pinned seam is
there, but offering the graph methods on the context the way core's CRUD is
offered needs a context-extension seam in core first.

=head2 Session setup (LOAD 'age')

This layer does B<nothing> locally for C<LOAD 'age'> -- it defines no
C<connect_call_load_age>. The setup rides core's pool C<on_connect> seam: a
schema connected with C<< { on_connect_call => 'load_age' } >> gives the
pool an owning sync storage (the composed sync Age storage, which defines
C<connect_call_load_age> on its layer), and core replays that connect action
synchronously against each freshly-spawned pool connection -- on whichever
transport was composed under this layer. LOAD logic belongs to the
composed sync Age storage alone.

=head2 The '?' placeholder seam

C<cypher_async> / C<create_graph_async> / C<drop_graph_async> hand the transport
plain C<?>-placeholder SQL. Shaping C<?> to the transport's wire dialect (e.g.
DBD::Pg's positional C<$N>) is the B<transport's> concern, applied inside its
C<_query_async> (ADR 0032 '?'-seam). The dollar-quoted Cypher body
and any C<$name> Cypher parameter reference are not SQL placeholders and survive
untouched; only a real C<?> is rewritten, and only by the transport.

Everything else -- the transport, the connection pool, the CRUD runner,
transactions and the SQLMaker -- comes from whichever transport this layer is
composed over.

=head1 METHODS

=head2 required_transport_capabilities

  my @caps = DBIO::PostgreSQL::Age::Storage::Async->required_transport_capabilities;
  # ('on_connect_replay')

Class method. The transport capabilities this async layer requires. Returns
C<on_connect_replay> because C<LOAD 'age'> must replay on every pooled
connection. Core's composition capability gate (see
L<DBIO::Storage::Async/transport_capabilities>) croaks naming this layer, the
missing capability and the transport if AGE is composed over a transport that
does not advertise it.

=head2 cypher_async

  my $future = $async->cypher_async(
    'social',
    q{ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name },
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $future = $async->cypher_async(
    'social',
    q{ MATCH (n:Person {name: $name}) RETURN n },
    ['node'],
    { name => 'Alice' },
  );

  # Auto-decode each cell into native Perl data (identical to sync cypher):
  my $future = $async->cypher_async(
    'social',
    q{ MATCH (n:Person {name: $name}) RETURN n },
    ['node'],
    { name => 'Alice' },
    { auto_decode => 1 },
  );

The async counterpart of L<DBIO::PostgreSQL::Age::Storage/cypher>. Builds the
same SQL and binds via the shared C<_cypher_sql_bind> and executes them over the
composed transport, returning a L<Future> that resolves to an arrayref of
hashrefs (one key per C<$columns> entry) -- exactly the shape sync C<cypher()>
returns.

C<$params>, if given, is JSON-encoded and passed as AGE's third C<cypher()>
argument. With C<< { auto_decode => 1 } >> every cell is passed through
L<DBIO::PostgreSQL::Age::Storage/decode_agtype> B<inside the Future chain>, so
the resolved arrayref is already decoded -- identical semantics to sync
C<auto_decode>, just async. Without it every cell is a raw agtype string and
decoding is the caller's responsibility.

B<Not transaction-pinned.> Like its two siblings this method always runs on a
B<pooled> connection: inside a L<DBIO::Storage::Async/txn_do_async> body it
executes on a sibling connection B<outside> that transaction, and inside a
L<DBIO::Storage::Async/pipeline> batch it is not batched onto the bracketed
connection -- in both cases silently. See
L</"The graph methods are pool-only, not transaction-pinned">.

=head2 create_graph_async

  my $future = $async->create_graph_async('social');

Async counterpart of L<DBIO::PostgreSQL::Age::Storage/create_graph>: a thin
wrapper that runs C<ag_catalog.create_graph(?)> over the composed transport.
Returns a L<Future>.

B<Not transaction-pinned.> Like its two siblings this method always runs on a
B<pooled> connection: inside a L<DBIO::Storage::Async/txn_do_async> body it
executes on a sibling connection B<outside> that transaction, and inside a
L<DBIO::Storage::Async/pipeline> batch it is not batched onto the bracketed
connection -- in both cases silently. See
L</"The graph methods are pool-only, not transaction-pinned">.

=head2 drop_graph_async

  my $future = $async->drop_graph_async('social');
  my $future = $async->drop_graph_async('social', 1);   # cascade

Async counterpart of L<DBIO::PostgreSQL::Age::Storage/drop_graph>: a thin
wrapper that runs C<ag_catalog.drop_graph(?, ?)> over the composed transport.
Pass a true second argument to cascade the drop. Returns a L<Future>.

B<Not transaction-pinned.> Like its two siblings this method always runs on a
B<pooled> connection: inside a L<DBIO::Storage::Async/txn_do_async> body it
executes on a sibling connection B<outside> that transaction, and inside a
L<DBIO::Storage::Async/pipeline> batch it is not batched onto the bracketed
connection -- in both cases silently. See
L</"The graph methods are pool-only, not transaction-pinned">.

=head1 SEE ALSO

=pod

=over 4

=item * L<DBIO::PostgreSQL::Age::Storage> - the sync storage layer with C<cypher()>

=item * L<DBIO::PostgreSQL::Storage::Async> - the C<future_io> transport this layer composes over

=item * L<DBIO::PostgreSQL::EV::Storage> - the C<ev> transport this layer composes over

=item * L<DBIO::PostgreSQL::Age> - Schema component that activates AGE

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
