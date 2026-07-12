package DBIO::PostgreSQL::Age::Storage;
# ABSTRACT: PostgreSQL storage with Apache AGE graph support

use strict;
use warnings;

use JSON::MaybeXS ();

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);


sub connect_call_load_age {
  my $self = shift;
  $self->_do_query(q{LOAD 'age'});
  $self->_do_query(q{SET search_path = ag_catalog, "$user", public});
}


sub create_graph {
  my ($self, $name) = @_;
  $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->do('SELECT * FROM ag_catalog.create_graph(?)', undef, $name);
  });
}


sub drop_graph {
  my ($self, $name, $cascade) = @_;
  $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->do(
      'SELECT * FROM ag_catalog.drop_graph(?, ?)',
      undef, $name, $cascade ? 1 : 0,
    );
  });
}


sub cypher {
  my ($self, $graph, $query, $columns, $params, $opts) = @_;

  my ($sql, $bind) = $self->_cypher_sql_bind($graph, $query, $columns, $params);

  my $rows = $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    return $dbh->selectall_arrayref($sql, { Slice => {} }, @$bind);
  });

  if ($opts && $opts->{auto_decode}) {
    for my $row (@$rows) {
      for my $col (keys %$row) {
        $row->{$col} = $self->decode_agtype($row->{$col});
      }
    }
  }

  return $rows;
}

# Async dispatchers for the graph methods, mirroring core's CRUD *_async
# (DBIO::Storage::select_async etc.): each is a thin shift->_run_async($op)
# whose three-way contract is (1) route ${op}_async to the embedded async
# backend when one is live (future_io/ev -> the composed Age async layer's real
# cypher_async), (2) in 'immediate' mode run the sync method in-process and wrap
# its result in an immediately-resolved Future (no event loop), (3) on a plain
# sync connection croak "not an async connection". This is why cypher() (and the
# graph lifecycle methods) can also be reached as *_async on the live storage,
# degrading cleanly under { async => 'immediate' } exactly like select_async.
# Graph async methods have a sync equivalent (cypher/create_graph/drop_graph),
# so unlike backend-only ops (listen/copy) they belong in the degrade-capable
# tier alongside the core CRUD methods.
sub cypher_async       { shift->_run_async('cypher', @_) }
sub create_graph_async { shift->_run_async('create_graph', @_) }
sub drop_graph_async   { shift->_run_async('drop_graph', @_) }


# Build the AGE cypher() SQL and its bind values. Pure (no DB) so the SQL
# generation can be unit-tested offline; cypher() wraps this with execution.
sub _cypher_sql_bind {
  my ($self, $graph, $query, $columns, $params) = @_;

  # Apache AGE requires the graph name to be a string literal in the
  # cypher() call -- it cannot be passed as a bind parameter. Validate the
  # name as a plain identifier so we can safely inline it.
  $graph =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
    or $self->throw_exception("Invalid AGE graph name '$graph'");

  my $col_spec = join ', ', map { "$_ agtype" } @$columns;

  my @bind;
  if ($params && %$params) {
    push @bind, $JSON->encode($params);
  }
  my $param_slot = @bind ? ', ?' : '';
  my $sql = "SELECT * FROM cypher('$graph', \$\$\n$query\n\$\$${param_slot}) AS ($col_spec)";

  return ($sql, \@bind);
}

# Decode a single agtype text value into native Perl data.
#
# AGE returns agtype values as text. The shapes we handle:
#   - JSON-like maps/lists  -> decode_json into hashref/arrayref
#   - Quoted string scalar  -> strip the surrounding quotes
#   - Integer / float       -> return as Perl number
#   - true / false / null   -> JSON booleans / undef
#   - Cast annotations      -> strip a trailing ::vertex / ::edge / ::path
#                               before further decoding (older AGE only).
# Anything we don't recognise is returned as-is so callers can still
# post-process it themselves.
sub decode_agtype {
  my ($self, $value) = @_;

  # Strip a trailing agtype cast annotation. Older AGE versions (1.3 and
  # earlier) append "::vertex" / "::edge" / "::path" to the rendered text;
  # newer versions do not. Be defensive about both.
  my $raw = $value;
  $raw =~ s/::(?:vertex|edge|path)\s*\z//;

  return $raw unless defined $raw && length $raw;

  my $first = substr($raw, 0, 1);

  # Map or list: hand off to JSON.
  if ($first eq '{' || $first eq '[') {
    my $decoded = eval { $JSON->decode($raw) };
    return $decoded unless $@;
    return $raw;
  }

  # Quoted string scalar: "foo" -> foo. Decode any JSON-escaped chars.
  if ($first eq '"') {
    my $decoded = eval { $JSON->decode($raw) };
    return $decoded unless $@;
    # Fallback: naive strip of outer quotes.
    my $inner = substr($raw, 1, length($raw) - 2);
    return $inner;
  }

  # Unquoted scalar. true/false/null/number.
  if ($raw eq 'true')  { return $JSON->true;  }
  if ($raw eq 'false') { return $JSON->false; }
  if ($raw eq 'null')  { return undef;        }

  # Looks numeric?
  if ($raw =~ /\A-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?\z/) {
    return $raw + 0; # +0 keeps int as int, float as float
  }

  # Anything else: leave alone.
  return $raw;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Age::Storage - PostgreSQL storage with Apache AGE graph support

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  # Loaded automatically via DBIO::PostgreSQL::Age component.
  # Use connect_call_load_age to initialize AGE on each connection:

  MyApp::Schema->connect(
    $dsn, $user, $pass,
    { on_connect_call => 'load_age' },
  );

  my $storage = $schema->storage;

  $storage->create_graph('social');

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person {name: $name})-[:KNOWS]->(b) RETURN b.name $$,
    ['friend'],
    { name => 'Alice' },
  );

  $storage->drop_graph('social', 1);  # cascade

=head1 DESCRIPTION

A storage B<layer> that adds Apache AGE graph database support -- connection
initialization, graph lifecycle management, and Cypher query execution -- to a
PostgreSQL storage. It is B<not> a storage subclass: it is a plain method
package composed over the resolved driver storage at connection time (see
L<DBIO::Storage::Composed>). L<DBIO::PostgreSQL::Age> registers it via
L<DBIO::Schema/register_storage_layer>, so on C<< $schema->connect >> the live
storage isa B<both> this layer and L<DBIO::PostgreSQL::Storage>, and the methods
below are callable on that composed storage. Because it is a layer, it stacks
cleanly with other extension layers (its methods are disjoint from, e.g.,
L<DBIO::PostgreSQL::PostGIS::Storage>).

=head2 Layer rules

Per the storage-layer composition model (DBIO core, karr #70): this package does
B<not> C<use base> a driver storage, defines no constructor, and calls only the
documented public storage surface -- C<dbh_do> and C<throw_exception> for the
graph methods, plus the connect-action seam C<_do_query> for
C<connect_call_load_age> -- each resolved through the composed MRO to the driver
base at runtime. C<_do_query> is deliberate: it is the same seam
C<connect_call_do_sql> uses, and it is what routes the C<LOAD 'age'> replay onto
each freshly-spawned async pool connection (core karr #68); a bare
C<< $self->dbh->do >> would run against the sync dbh instead and defeat the
replay. The pure helpers C<_cypher_sql_bind> and C<decode_agtype> are DB-free
class-level helpers, shared by composition with the async layer
(L<DBIO::PostgreSQL::Age::Storage::Async>) so sync and async build identical SQL
and decode identically.

All result columns from C<cypher()> are declared as C<agtype> — Apache AGE's
JSON-superset type that represents vertices, edges, paths, and scalar values.
Values are returned as strings and can be decoded with a JSON parser.

=head1 METHODS

=head2 connect_call_load_age

  { on_connect_call => 'load_age' }

Connection callback that loads the Apache AGE shared library into the session
and sets C<search_path> to include C<ag_catalog>. Must be called before any
graph operations.

=head2 create_graph

  $storage->create_graph('social');

Creates a new Apache AGE graph with the given name.

=head2 drop_graph

  $storage->drop_graph('social');
  $storage->drop_graph('social', 1);  # cascade

Drops the named graph. Pass a true second argument to cascade the drop to all
vertices and edges within the graph.

=head2 cypher_async

=head2 create_graph_async

=head2 drop_graph_async

The async counterparts of L</cypher>, L</create_graph> and L</drop_graph>,
reachable on the live (composed) storage. Each dispatches through core's
L<DBIO::Storage/_run_async|three-way async contract>: on an async connection
(C<< { async => 'future_io' } >>, C<'ev'>, ...) they route to the embedded async
backend (the composed L<DBIO::PostgreSQL::Age::Storage::Async> layer, which does
the real non-blocking work); under C<< { async => 'immediate' } >> they run the
sync method in-process and return an immediately-resolved L<Future> with no event
loop; on a plain sync connection they croak. This mirrors the core CRUD
C<*_async> methods (L<DBIO::Storage/select_async> and friends) -- graph queries
have a sync equivalent, so they degrade the same way rather than being
backend-only.

=head2 decode_agtype

  my $name = $storage->decode_agtype('"alice"');         # "alice"
  my $age  = $storage->decode_agtype('30');              # 30
  my $v    = $storage->decode_agtype(
    '{"id": 1, "label": "Person", "properties": {"name": "alice"}}::vertex'
  );                                                       # { id => 1, label => "Person", properties => { name => "alice" } }

  my $rows = $storage->cypher(
    'social',
    $$ RETURN n $$,
    ['n'],
  );
  my $vertex = $storage->decode_agtype($rows->[0]{n});   # manual decode

Decodes a single C<agtype> text value (as returned by C<cypher()>) into native
Perl data. Recognised shapes:

=over 4

=item * String scalar (quoted, e.g. C<"alice">) — string with quotes stripped

=item * Integer / float scalar (e.g. C<42>, C<3.14>) — Perl number

=item * Boolean (C<true>, C<false>) — C<JSON::MaybeXS> true/false objects

=item * Null (C<null>) — C<undef>

=item * Map / list (e.g. C<{"name": "alice"}>, C<[1, 2, 3]>) — hashref / arrayref

=item * Vertex / edge — same as the underlying map; a trailing C<::vertex> /
C<::edge> cast annotation (only emitted by older AGE versions) is stripped
before decoding. C<id>, C<label>, C<start_id>, C<end_id>, C<properties> are
preserved as JSON keys.

=item * Path — arrayref of decoded vertices and edges (structure preserved,
not unwrapped)

=item * Anything else — returned as-is so the caller can post-process it

=back

=head2 cypher

  my $rows = $storage->cypher(
    'social',
    $$ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name $$,
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $rows = $storage->cypher(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
    ['node'],
    { name => 'Alice' },
  );

  # Auto-decode each cell into native Perl data:
  my $rows = $storage->cypher(
    'social',
    $$ MATCH (n:Person {name: $name}) RETURN n $$,
    ['node'],
    { name => 'Alice' },
    { auto_decode => 1 },
  );
  # $rows->[0]{node} is now a hashref, not a string.

Executes a Cypher query against the named graph. C<$columns> is an arrayref
of result column names; all are declared as C<agtype>. Returns an arrayref
of hashrefs with one key per column.

An optional C<$params> hashref is JSON-encoded and passed as AGE's third
argument to C<cypher()> for parameterized queries.

Pass an optional fifth argument, a hashref of options, to control result
handling:

=over 4

=item * C<auto_decode =E<gt> 1> — apply L</decode_agtype> to every cell of
every row before returning. Without this option, every cell is a raw agtype
string and decoding is the caller's responsibility.

=back

=seealso

=over 4

=item * L<DBIO::PostgreSQL::Age> - Schema component that activates this storage

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
