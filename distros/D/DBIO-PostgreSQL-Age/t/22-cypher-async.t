use strict;
use warnings;
use Test::More;

# Offline coverage for cypher_async on the Age async LAYER. No event loop, no
# real database: a fake transport captures the SQL+bind cypher_async submits and
# hands back canned raw rows through a real Future, so we can assert:
#
#   * cypher_async builds the SAME SQL + bind as the sync _cypher_sql_bind -- the
#     composition-reuse guard that fails the moment the builder drifts;
#   * the '?'-seam contract (core karr #70 / ADR 0032): the layer hands the
#     transport RAW '?' SQL and does NOT shape it -- turning '?' into the wire
#     dialect ($N) is the transport's concern, applied inside its _query_async.
#     The '$$...$$' cypher body and any '$name' Cypher reference survive
#     untouched (they are not SQL placeholders);
#   * it resolves the sync {Slice => {}} row shape (hashref keyed by column);
#   * auto_decode applies the SAME decode_agtype, inside the Future chain;
#   * create_graph_async / drop_graph_async mirror the sync graph SQL.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all => 'future_io prerequisites (DBD::Pg/Future/Future::IO) not available';
}

use DBIO::PostgreSQL::Age::Storage::Async;
use DBIO::PostgreSQL::Age::Storage ();

# --- Fake capturing transport ------------------------------------------------
# The Age async layer is a plain package now; a real backend composes it OVER a
# transport. This fake stands in for that transport: it carries the layer's
# methods (via ISA) and captures the raw-query seam. Crucially it does NOT
# transform the SQL -- so whatever it captures is exactly what the layer handed
# it, letting us prove the layer emits raw '?' and leaves shaping to the wire.
{
  package FakeAgeAsync;
  use base 'DBIO::PostgreSQL::Age::Storage::Async';
  use Future;

  sub future_class { 'Future' }
  sub new { bless { cap => [], rows => [] }, ref($_[0]) || $_[0] }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{cap} }, { sql => $sql, bind => $bind };
    return Future->done(@{ $self->{rows} });
  }
}

# --- cypher_async: builder reuse (no drift) + row shape ----------------------
{
  my $a = FakeAgeAsync->new;
  $a->{rows} = [ [ '"alice"' ], [ '"bob"' ] ];

  my @args = ('social', 'MATCH (n {name: $name}) RETURN n.name', ['name'], { name => 'Alice' });

  my $f = $a->cypher_async(@args);
  isa_ok $f, 'Future', 'cypher_async returns a Future';

  my $rows = $f->get;
  is_deeply $rows, [ { name => '"alice"' }, { name => '"bob"' } ],
    'resolves an arrayref of hashrefs keyed by column (sync {Slice=>{}} shape), raw by default';

  # The captured SQL+bind must be EXACTLY the shared sync builder's output --
  # RAW, un-transformed. Same sub => identical strings by construction; a
  # copied/forked builder would drift and fail here.
  my ($sync_sql, $sync_bind)
    = DBIO::PostgreSQL::Age::Storage::_cypher_sql_bind($a, @args);
  is $a->{cap}[0]{sql}, $sync_sql,
    'cypher_async hands the transport the RAW sync _cypher_sql_bind SQL (no shaping in the layer)';
  is_deeply $a->{cap}[0]{bind}, $sync_bind,
    'cypher_async bind == sync _cypher_sql_bind bind (JSON-encoded params)';
  like $a->{cap}[0]{sql}, qr/\$\$, \?\) AS \(name agtype\)/,
    'param slot is a raw "?" placeholder ($N shaping is the transport concern); column declared agtype';

  # '?'-seam body-survival: the Cypher body ($$...$$) and the $name reference are
  # NOT SQL placeholders and must reach the transport intact.
  like $a->{cap}[0]{sql}, qr/\$\$\nMATCH \(n \{name: \$name\}\) RETURN n\.name\n\$\$/,
    q{the '$$...$$' cypher body and the '$name' reference survive untouched into the transport};
}

# --- cypher_async: no-params path -------------------------------------------
{
  my $a = FakeAgeAsync->new;
  $a->{rows} = [ [ '"x"', '"y"' ] ];

  my @args = ('g', 'RETURN a, b', [qw(person friend)]);
  my $rows = $a->cypher_async(@args)->get;
  is_deeply $rows, [ { person => '"x"', friend => '"y"' } ],
    'multi-column no-param query zips columns in declared order';

  my ($sync_sql, $sync_bind)
    = DBIO::PostgreSQL::Age::Storage::_cypher_sql_bind($a, @args);
  is $a->{cap}[0]{sql}, $sync_sql, 'no-param SQL matches the raw sync builder';
  is_deeply $a->{cap}[0]{bind}, [], 'no-param query carries no bind';
  unlike $a->{cap}[0]{sql}, qr/\?/,  'no "?" placeholder emitted without params';
  unlike $a->{cap}[0]{sql}, qr/\$\d/, 'no $N appears -- the layer never shapes placeholders';
}

# --- cypher_async: auto_decode parity ---------------------------------------
{
  my $a = FakeAgeAsync->new;
  my @raw = ( [ '"alice"', '30' ], [ '{"id":1,"label":"Person"}::vertex', 'null' ] );
  $a->{rows} = [ map { [ @$_ ] } @raw ];

  my $rows = $a->cypher_async(
    'g', 'MATCH (n) RETURN n.name, n.age', [qw(name age)], undef, { auto_decode => 1 },
  )->get;

  # Expected = the SAME pure decode_agtype applied cell-by-cell.
  my @expected = map {
    { name => DBIO::PostgreSQL::Age::Storage::decode_agtype($a, $_->[0]),
      age  => DBIO::PostgreSQL::Age::Storage::decode_agtype($a, $_->[1]) }
  } @raw;

  is_deeply $rows, \@expected,
    'auto_decode applies decode_agtype to every cell, inside the Future chain';
  is $rows->[0]{name}, 'alice', '... quoted string decoded';
  is $rows->[0]{age}, 30, '... integer decoded to a number';
  is ref($rows->[1]{name}), 'HASH', '... vertex decoded to a hashref';
  is $rows->[1]{age}, undef, '... null decoded to undef';
}

# --- create_graph_async / drop_graph_async: mirror the sync graph SQL --------
{
  my $a = FakeAgeAsync->new;

  $a->create_graph_async('social')->get;
  is $a->{cap}[0]{sql}, 'SELECT * FROM ag_catalog.create_graph(?)',
    'create_graph_async runs ag_catalog.create_graph with a raw "?" (transport shapes it)';
  is_deeply $a->{cap}[0]{bind}, ['social'], 'create_graph_async binds the graph name';

  $a->{cap} = [];
  $a->drop_graph_async('social')->get;
  is $a->{cap}[0]{sql}, 'SELECT * FROM ag_catalog.drop_graph(?, ?)',
    'drop_graph_async runs ag_catalog.drop_graph with raw "?" placeholders';
  is_deeply $a->{cap}[0]{bind}, ['social', 0], 'drop_graph_async defaults cascade to 0';

  $a->{cap} = [];
  $a->drop_graph_async('social', 1)->get;
  is_deeply $a->{cap}[0]{bind}, ['social', 1], 'drop_graph_async passes a true cascade as 1';
}

done_testing;
