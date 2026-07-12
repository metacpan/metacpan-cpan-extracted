use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;

use DBIO::Test;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;

# Offline unit tests for decode_agtype. The decoder is pure (no DB), so we
# can pin the full shape-coverage here without a live PostgreSQL+AGE.
#
# Coverage matrix:
#   - Scalar: quoted string, integer, float, true, false, null
#   - Compound: map, list
#   - Vertex/edge: with and without ::vertex / ::edge cast annotations
#   - Edge cases: empty map, nested map (vertex with properties), the
#     string "true" must NOT be confused with the boolean true

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# Age::Storage is a plain storage LAYER now (core karr #70) -- no constructor.
# Compose it over the PG driver storage for an instance carrying decode_agtype.
my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $composed = DBIO::Storage::Composed->compose(
  'DBIO::PostgreSQL::Storage', ['DBIO::PostgreSQL::Age::Storage'],
);
my $s = $composed->new($schema);

# --- scalars ---

{
  my $v = $s->decode_agtype('"alice"');
  is $v, 'alice', 'quoted string scalar has quotes stripped';
}

{
  my $v = $s->decode_agtype('42');
  is $v, 42, 'integer scalar comes back as Perl number';
}

{
  my $v = $s->decode_agtype('3.14');
  is $v, 3.14, 'float scalar comes back as Perl number';
}

{
  my $v = $s->decode_agtype('true');
  ok $v == $JSON->true, 'true becomes JSON::MaybeXS true';

  my $f = $s->decode_agtype('false');
  ok $f == $JSON->false, 'false becomes JSON::MaybeXS false';
}

{
  my $v = $s->decode_agtype('null');
  is $v, undef, 'null becomes undef';
}

# --- maps / lists ---

{
  my $v = $s->decode_agtype('{"name": "alice", "age": 30}');
  is_deeply $v, { name => 'alice', age => 30 },
    'plain map decodes to hashref';
}

{
  my $v = $s->decode_agtype('[1, 2, 3]');
  is_deeply $v, [1, 2, 3], 'plain list decodes to arrayref';
}

{
  my $v = $s->decode_agtype('{}');
  is_deeply $v, {}, 'empty map decodes to empty hashref';
}

# --- vertex / edge cast annotations ---

{
  my $raw = q[{"id": 844424930131969, "label": "Person", "properties": {"name": "alice"}}::vertex];
  my $v = $s->decode_agtype($raw);
  is_deeply $v,
    { id => 844424930131969, label => 'Person', properties => { name => 'alice' } },
    'vertex with ::vertex annotation: annotation stripped, id/label/properties preserved';
}

{
  my $raw = q[{"id": 844424930131970, "label": "KNOWS", "end_id": 844424930131972, "start_id": 844424930131971, "properties": {"since": 2020}}::edge];
  my $v = $s->decode_agtype($raw);
  is_deeply $v,
    {
      id => 844424930131970,
      label => 'KNOWS',
      end_id => 844424930131972,
      start_id => 844424930131971,
      properties => { since => 2020 },
    },
    'edge with ::edge annotation: start_id/end_id preserved, annotation stripped';
}

{
  # Newer AGE (1.4+) returns the same JSON object WITHOUT the cast annotation.
  # The decoder must produce the same shape in either case.
  my $raw_no_cast = q[{"id": 844424930131969, "label": "Person", "properties": {"name": "alice"}}];
  my $raw_with_cast = $raw_no_cast . '::vertex';
  my $a = $s->decode_agtype($raw_no_cast);
  my $b = $s->decode_agtype($raw_with_cast);
  is_deeply $a, $b,
    'vertex decoded identically with or without ::vertex annotation';
}

# --- nested / tricky cases ---

{
  # Vertex where properties contain a nested object.
  my $raw = q[{"id": 1, "label": "Person", "properties": {"name": "alice", "addr": {"city": "Berlin", "zip": "10115"}}}::vertex];
  my $v = $s->decode_agtype($raw);
  is $v->{properties}{addr}{city}, 'Berlin',
    'nested map (vertex.properties.addr.city) is decoded recursively';
  is $v->{properties}{addr}{zip}, '10115',
    'nested string inside properties is decoded (quotes stripped)';
}

{
  # The string "true" (with quotes) MUST decode to the literal string 'true',
  # not to JSON true. This is the classic gotcha.
  my $v = $s->decode_agtype('"true"');
  is $v, 'true', 'quoted "true" decodes to the string "true" (not boolean)';
}

{
  # Same for "false" and "null".
  my $f = $s->decode_agtype('"false"');
  is $f, 'false', 'quoted "false" decodes to the string "false"';

  my $n = $s->decode_agtype('"null"');
  is $n, 'null', 'quoted "null" decodes to the string "null"';
}

{
  # A path is an arrayref of vertices/edges (no unwrap).
  my $raw = q[[{"id": 1, "label": "Person", "properties": {"name": "alice"}}, {"id": 10, "label": "KNOWS", "end_id": 2, "start_id": 1, "properties": {"since": 2020}}, {"id": 2, "label": "Person", "properties": {"name": "bob"}}]];
  my $v = $s->decode_agtype($raw);
  is ref($v), 'ARRAY', 'path decodes to arrayref';
  is scalar @$v, 3, 'path keeps all three elements (vertex, edge, vertex)';
  is $v->[0]{label}, 'Person', 'first element is a vertex';
  is $v->[1]{label}, 'KNOWS',  'middle element is an edge';
  is $v->[2]{label}, 'Person', 'last element is a vertex';
}

{
  # Unknown / unrecognised input is returned as-is so the caller can handle it.
  my $v = $s->decode_agtype('not-json-at-all');
  is $v, 'not-json-at-all', 'unrecognised scalar returned as-is';
}

done_testing;