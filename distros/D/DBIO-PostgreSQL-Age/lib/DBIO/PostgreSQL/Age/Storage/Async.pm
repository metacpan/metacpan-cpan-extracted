package DBIO::PostgreSQL::Age::Storage::Async;
# ABSTRACT: Floating async storage layer for Apache AGE (cypher_async)

use strict;
use warnings;

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
  # its _query_async (core karr #70 / ADR 0032 '?'-seam). The '$$...$$' cypher
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

version 0.900001

=head1 SYNOPSIS

  # Composed automatically for an Age schema opened in ANY async mode whose
  # transport can replay LOAD 'age' -- future_io, ev, ... (core karr #70).

  my $schema = MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age', async => 'future_io' },  # or 'ev'
  );

  my $async = $schema->storage->async;   # the composed async backend

  $async->create_graph_async('social')->then(sub {
    $async->cypher_async(
      'social',
      $$ MATCH (n:Person {name: $name}) RETURN n $$,
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
transport. Core's storage-layer composition (karr #70) mirrors the registered
sync Age layer onto its async sibling by convention
(C<< DBIO::PostgreSQL::Age::Storage >> -> C<< ...::Async >>) and composes B<this>
package (C3) OVER whatever transport the connection's async mode resolves:
L<DBIO::PostgreSQL::Storage::Async> for C<future_io>,
L<DBIO::PostgreSQL::EV::Storage> for C<ev>. The composed backend isa both this
layer and that transport, so C<cypher_async> rides every capable transport
without a per-transport class.

=head2 Required transport capability

AGE mandates C<LOAD 'age'> (and the C<ag_catalog> search_path SET) on B<every>
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

=head2 Session setup (LOAD 'age')

This layer does B<nothing> locally for C<LOAD 'age'> -- it defines no
C<connect_call_load_age>. The setup rides core's pool C<on_connect> seam (karr
#68): a schema connected with C<< { on_connect_call => 'load_age' } >> gives the
pool an owning sync storage (the composed sync Age storage, which defines
C<connect_call_load_age> on its layer), and core replays that connect action
synchronously against each freshly-spawned pool connection -- on whichever
transport was composed under this layer. Installing any LOAD logic on this layer
would be the karr #66 anti-pattern.

=head2 The '?' placeholder seam

C<cypher_async> / C<create_graph_async> / C<drop_graph_async> hand the transport
plain C<?>-placeholder SQL. Shaping C<?> to the transport's wire dialect (e.g.
DBD::Pg's positional C<$N>) is the B<transport's> concern, applied inside its
C<_query_async> (core karr #70 / ADR 0032 '?'-seam). The C<$$...$$> Cypher body
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
    $$ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name $$,
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $future = $async->cypher_async(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
    ['node'],
    { name => 'Alice' },
  );

  # Auto-decode each cell into native Perl data (identical to sync cypher):
  my $future = $async->cypher_async(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
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

=head2 create_graph_async

  my $future = $async->create_graph_async('social');

Async counterpart of L<DBIO::PostgreSQL::Age::Storage/create_graph>: a thin
wrapper that runs C<ag_catalog.create_graph(?)> over the composed transport.
Returns a L<Future>.

=head2 drop_graph_async

  my $future = $async->drop_graph_async('social');
  my $future = $async->drop_graph_async('social', 1);   # cascade

Async counterpart of L<DBIO::PostgreSQL::Age::Storage/drop_graph>: a thin
wrapper that runs C<ag_catalog.drop_graph(?, ?)> over the composed transport.
Pass a true second argument to cascade the drop. Returns a L<Future>.

=seealso

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
