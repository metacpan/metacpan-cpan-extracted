package DBIO::PostgreSQL::Age::Storage;
# ABSTRACT: PostgreSQL storage with Apache AGE graph support

use strict;
use warnings;

our $VERSION = '0.900004';

use JSON::MaybeXS ();

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# Same decoder for a value that already is a character string (UTF8 flag on,
# what DBD::Pg hands over with client_encoding UTF8).
my $JSON_CHARS = JSON::MaybeXS->new(utf8 => 0, canonical => 1);


sub connect_call_load_age {
  my $self = shift;
  $self->_do_query(q{LOAD 'age'});
  # ag_catalog anywhere in the path (also quoted) leaves the path as it is --
  # the driver's order is respected, nothing is doubled. Else: with a tenant
  # namespace (connect key `schema`, kept as connection_schema) ag_catalog goes
  # BEHIND the namespace entry (the first path element), so unqualified DDL
  # lands in the namespace; without one it goes in front. An empty path gets
  # just ag_catalog.
  my $ns = defined $self->connection_schema ? 1 : 0;
  my $with_ns = q{regexp_replace(current_setting('search_path'), }
    . q{'^\s*("([^"]|"")*"|[^,]*)', '\1, ag_catalog')};
  $self->_do_query(
    q{SELECT set_config('search_path', CASE }
  . q{WHEN current_setting('search_path') ~ '(^|,)\s*(ag_catalog|"ag_catalog")\s*(,|$)' }
  . q{THEN current_setting('search_path') }
  . q{WHEN btrim(current_setting('search_path')) = '' THEN 'ag_catalog' }
  . ($ns
      ? qq{ELSE $with_ns END, false)}
      : q{ELSE 'ag_catalog, ' || current_setting('search_path') END, false)})
  );
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

  # The result columns go into the AS (...) list verbatim, so they get the same
  # plain-identifier check as the graph name.
  for my $col (@$columns) {
    defined $col && $col =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/
      or $self->throw_exception(
        'Invalid AGE column name ' . (defined $col ? "'$col'" : '(undef)')
      );
  }
  my $col_spec = join ', ', map { "$_ agtype" } @$columns;

  # The Cypher text is inlined as a dollar-quoted string, and a "$tag$" inside
  # it would end the quoting early. Pick a tag that does not occur in the text
  # (counting up on a collision) so any Cypher text is enclosed verbatim.
  my $tag = 'dbio_age';
  my $n = 0;
  $tag = 'dbio_age' . ++$n while index($query, "\$$tag\$") >= 0;
  my $dq = "\$$tag\$";

  my @bind;
  if ($params && %$params) {
    # A character string: DBD::Pg encodes it for the wire itself (bytes would be encoded twice).
    push @bind, $JSON_CHARS->encode($params);
  }
  my $param_slot = @bind ? ', ?' : '';
  my $sql = "SELECT * FROM cypher('$graph', $dq\n$query\n$dq${param_slot}) AS ($col_spec)";

  return ($sql, \@bind);
}

# Text of a "<number>::numeric" value without the cast: the bare number when a
# Perl number holds it exactly, else a quoted JSON string with the exact digits.
sub _numeric_literal {
  my ($num) = @_;
  return $num if $num =~ /\A-?\d+\z/ && ($num + 0) eq $num;   # fits an IV
  (my $digits = $num) =~ s/[eE].*//;
  $digits =~ s/\D//g;
  $digits =~ s/^0+//;
  $digits =~ s/0+\z//;
  return length($digits) > 15 ? qq{"$num"} : $num;
}

# Decode a single agtype text value into native Perl data.
#
# AGE returns agtype values as text. The shapes we handle:
#   - JSON-like maps/lists  -> decode_json into hashref/arrayref
#   - Quoted string scalar  -> strip the surrounding quotes
#   - Integer / float       -> return as Perl number
#   - true / false / null   -> JSON booleans / undef
#   - Cast annotations      -> strip every ::vertex / ::edge / ::path (AGE
#                               annotates each element, also inside paths and
#                               lists), but never inside a string literal.
# Anything we don't recognise is returned as-is so callers can still
# post-process it themselves.
sub decode_agtype {
  my ($self, $value) = @_;

  return undef unless defined $value;   # SQL NULL cell

  # AGE (verified against 1.8.0) appends "::vertex" / "::edge" / "::path" to
  # every such element of the rendered text, e.g.
  # "[{...}::vertex, {...}::edge, {...}::vertex]::path". Strip them all, but
  # skip string literals: a property value may legitimately contain
  # "::vertex". The first alternative consumes (and keeps) a whole literal.
  #
  # "<number>::numeric" is stripped the same way. A numeric a double cannot
  # hold exactly (more than 15 significant digits, unless it is an integer
  # that fits an IV) is rewritten to a JSON string literal, so the exact digits
  # survive both as a scalar and inside a list/map, whatever JSON backend.
  my $raw = $value;
  $raw =~ s{("(?:[^"\\]|\\.)*")|((?<![\d.])-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)::numeric\b|::(?:vertex|edge|path)\b}{
    defined $1 ? $1
    : defined $2 ? _numeric_literal($2)
    : ''
  }ge;
  $raw =~ s/\s+\z//;

  return $raw unless defined $raw && length $raw;

  my $first = substr($raw, 0, 1);

  # A character string (UTF8 flag) is decoded as characters, bytes as bytes.
  my $json = utf8::is_utf8($raw) ? $JSON_CHARS : $JSON;

  # Map or list: hand off to JSON.
  if ($first eq '{' || $first eq '[') {
    my $decoded = eval { $json->decode($raw) };
    return $decoded unless $@;
    # Neither the value nor the parser's message (it quotes the value) is named.
    my ($suffix) = $value =~ /(::(?:vertex|edge|path))\s*\z/;
    $self->throw_exception(
      'decode_agtype: cannot decode agtype ' . ($first eq '{' ? 'map' : 'list')
      . (defined $suffix ? " ($suffix)" : '')
    );
  }

  # Quoted string scalar: "foo" -> foo. Decode any JSON-escaped chars.
  if ($first eq '"') {
    my $decoded = eval { $json->decode($raw) };
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

version 0.900004

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
    q{ MATCH (a:Person {name: $name})-[:KNOWS]->(b) RETURN b.name },
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
cleanly with other extension layers; its methods are disjoint from theirs. It
defines no C<dbio_deploy_class>: the deploy class is the driver's, and the
model rules of AGE are in L<DBIO::PostgreSQL::Age::Extension>, which names this
layer through C<storage_layer>.

=head2 Layer rules

Per the storage-layer composition model (DBIO core): this package does
B<not> C<use base> a driver storage, defines no constructor, and calls only the
documented public storage surface -- C<dbh_do> and C<throw_exception> for the
graph methods, plus the connect-action seam C<_do_query> for
C<connect_call_load_age> -- each resolved through the composed MRO to the driver
base at runtime. C<_do_query> is deliberate: it is the same seam
C<connect_call_do_sql> uses, and it is what routes the C<LOAD 'age'> replay onto
each freshly-spawned async pool connection; a bare
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
and adds C<ag_catalog> to the connection's current C<search_path> (added, not
replaced). Where it goes depends on the connection:

=over 4

=item *

With a tenant namespace (connect key C<schema>), C<ag_catalog> is inserted
B<behind> the namespace entry, the first element of the path, so that
unqualified DDL still lands in the namespace (PostgreSQL creates in the first
existing schema of the path); cypher and C<create_graph> keep working because
C<ag_catalog> stays on the path.

=item *

Without a namespace, C<ag_catalog> goes in front of the path, as before.

=back

When C<ag_catalog> is already an element of the path, at any position and
quoted or not (the driver puts it behind the namespace for a declared
C<pg_extensions('age')>), the path stays unchanged: the driver's order is
respected and nothing is doubled. Must be called before any graph operations.

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
L<three-way async contract|DBIO::Storage/_run_async>: on an async connection
(C<< { async => 'future_io' } >>, C<'ev'>, ...) they route to the embedded async
backend (the composed L<DBIO::PostgreSQL::Age::Storage::Async> layer, which does
the real non-blocking work); under C<< { async => 'immediate' } >> they run the
sync method in-process and return an immediately-resolved L<Future> with no event
loop; on a plain sync connection they croak. This mirrors the core CRUD
C<*_async> methods (L<DBIO::Storage/select_async> and friends) -- graph queries
have a sync equivalent, so they degrade the same way rather than being
backend-only.

B<Not transaction-pinned.> On an async connection all three route to the
embedded backend's B<pooled> query seam, so calling one inside a
L<DBIO::Storage::Async/txn_do_async> body runs it on a sibling connection
B<outside> that transaction, and inside a L<DBIO::Storage::Async/pipeline> batch
it is not batched onto the bracketed connection -- in both cases silently.
Transactional graph work belongs on the sync surface --
C<< $schema->txn_do(sub { $schema->storage->cypher(...) }) >> runs on the
transaction's own C<dbh>. Full reasoning:
L<DBIO::PostgreSQL::Age::Storage::Async/"The graph methods are pool-only, not transaction-pinned">.

=head2 decode_agtype

  my $name = $storage->decode_agtype('"alice"');         # "alice"
  my $age  = $storage->decode_agtype('30');              # 30
  my $v    = $storage->decode_agtype(
    '{"id": 1, "label": "Person", "properties": {"name": "alice"}}::vertex'
  );                                                       # { id => 1, label => "Person", properties => { name => "alice" } }

  my $rows = $storage->cypher(
    'social',
    q{ RETURN n },
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

=item * Vertex / edge — same as the underlying map; the C<::vertex> /
C<::edge> cast annotation AGE appends to every element (checked against AGE
1.8.0, also inside paths, lists and maps) is stripped before decoding, but
never inside a string literal, so a property value may contain C<::vertex>.
C<id>, C<label>, C<start_id>, C<end_id>, C<properties> are
preserved as JSON keys.

=item * Path — arrayref of decoded vertices and edges (structure preserved,
not unwrapped); the C<::path> annotation is stripped as well

=item * SQL C<NULL> (C<undef>) — C<undef>, without a warning

=item * Numeric cast (C<1.5::numeric>) — the cast is stripped (outside string
literals, also inside lists and maps) and the value becomes a Perl number. A
value a double cannot hold exactly (more than 15 significant digits, e.g.
C<0.1234567890123456789::numeric>) is returned as the exact string instead,
scalar and inside a container alike; an integer that fits an IV stays an exact
number

=item * A value with the UTF8 flag (what DBD::Pg returns for a UTF-8 client
encoding) is decoded as characters, a byte string as UTF-8 bytes; either way
non-ASCII text arrives as the same characters

=item * A map or list that is not valid agtype JSON throws a L<DBIO::Exception>
naming the kind (map or list) and the C<::vertex> / C<::edge> / C<::path>
annotation the value carried, never the value itself

=item * Digit runs are matched once from their first digit, so the time taken
grows linearly with the length of the value

=item * Anything else — returned as-is so the caller can post-process it

=back

=head2 cypher

  my $rows = $storage->cypher(
    'social',
    q{ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name },
    [qw( person friend )],
  );

  # With Cypher parameters:
  my $rows = $storage->cypher(
    'social',
    q{ MATCH (n:Person {name: $name}) RETURN n },
    ['node'],
    { name => 'Alice' },
  );

  # Auto-decode each cell into native Perl data:
  my $rows = $storage->cypher(
    'social',
    q{ MATCH (n:Person {name: $name}) RETURN n },
    ['node'],
    { name => 'Alice' },
    { auto_decode => 1 },
  );
  # $rows->[0]{node} is now a hashref, not a string.

Executes a Cypher query against the named graph. C<$columns> is an arrayref
of result column names; all are declared as C<agtype>. Returns an arrayref
of hashrefs with one key per column. Like the graph name, every column name
must be a plain identifier (C<[A-Za-z_][A-Za-z0-9_]*>); anything else throws
C<Invalid AGE column name>, because the names are placed into the SQL as-is.

The Cypher text is embedded into the SQL as a dollar-quoted string. The quote
tag (C<$dbio_age$>, counted up to C<$dbio_age1$>, ... if the text itself
contains it) is chosen so that it does not occur in the Cypher text, so a
C<$$> in a string literal is harmless. Values must still go through C<$params>
(see below) and never be interpolated into the Cypher text: the text is
executed as written.

An optional C<$params> hashref is JSON-encoded and passed as AGE's third
argument to C<cypher()> for parameterized queries.

Pass an optional fifth argument, a hashref of options, to control result
handling:

=over 4

=item * C<auto_decode =E<gt> 1> — apply L</decode_agtype> to every cell of
every row before returning. Without this option, every cell is a raw agtype
string and decoding is the caller's responsibility.

=back

=head1 SEE ALSO

=pod

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
