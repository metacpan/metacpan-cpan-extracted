use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;
use Time::HiRes ();
use Test::Fatal;

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
  # The decoder must produce the same shape with or without the annotation
  # (AGE 1.8.0 still appends it; see the real-server strings below).
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

# --- inputs captured verbatim from a real AGE 1.8.0 server (karr k13) ---
# AGE annotates EVERY element, also inside paths, lists and maps.

my $REAL_V1 = q[{"id": 844424930131969, "label": "P", "properties": {"name": "a ::vertex \"q\""}}::vertex];
my $REAL_E  = q[{"id": 1125899906842625, "label": "K", "end_id": 844424930131970, "start_id": 844424930131969, "properties": {"since": 2020}}::edge];
my $REAL_V2 = q[{"id": 844424930131970, "label": "P", "properties": {"name": "b"}}::vertex];

my $V1 = { id => 844424930131969, label => 'P', properties => { name => 'a ::vertex "q"' } };
my $E  = { id => 1125899906842625, label => 'K', end_id => 844424930131970,
           start_id => 844424930131969, properties => { since => 2020 } };
my $V2 = { id => 844424930131970, label => 'P', properties => { name => 'b' } };

{
  my $v = $s->decode_agtype("[$REAL_V1, $REAL_E, $REAL_V2]::path");
  is_deeply $v, [$V1, $E, $V2],
    'real path (inner ::vertex/::edge plus trailing ::path) decodes to arrayref';
}

{
  my $v = $s->decode_agtype("[$REAL_V1, $REAL_V2]");
  is_deeply $v, [$V1, $V2], 'real collect(n) vertex list decodes to arrayref';
}

{
  my $v = $s->decode_agtype(qq[{"n": $REAL_V2}]);
  is_deeply $v, { n => $V2 }, 'vertex nested in a map decodes';
}

{
  # The property value contains the text '::vertex' inside a string literal:
  # it must survive untouched (REAL_V1 carries 'a ::vertex "q"').
  my $v = $s->decode_agtype($REAL_V1);
  is $v->{properties}{name}, 'a ::vertex "q"',
    'a "::vertex" inside a string literal is not stripped';

  my $w = $s->decode_agtype(q["x::vertex"]);
  is $w, 'x::vertex', 'quoted scalar containing ::vertex is kept as is';

  my $t = $s->decode_agtype(q[{"id": 1, "label": "P", "properties": {"n": "ends with ::edge"}}::vertex]);
  is $t->{properties}{n}, 'ends with ::edge',
    'string literal ending in ::edge is not stripped';
}

# --- undef (SQL NULL cell) must not warn (karr k15) ---

{
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  my $v = $s->decode_agtype(undef);
  is $v, undef, 'undef decodes to undef';
  is_deeply \@w, [], 'undef input raises no warning';
}

# --- numeric cast: stripped, value becomes a number (karr k17) ---
# AGE renders 1.5::numeric / [1.5::numeric, 2] with the annotation. The cast is
# stripped outside string literals, like ::vertex/::edge/::path. A value a
# double cannot hold exactly stays the exact string, scalar and container alike.
{
  my $n = $s->decode_agtype('1.5::numeric');
  is $n, 1.5, '::numeric scalar is stripped and returned as a number';
  ok !ref $n, 'plain scalar, not a reference';

  is $s->decode_agtype('42::numeric'), 42, 'integer ::numeric scalar';
  is $s->decode_agtype('-3.25::numeric'), -3.25, 'negative ::numeric scalar';

  is_deeply $s->decode_agtype('[1.5::numeric, 2]'), [1.5, 2],
    '::numeric inside a list is stripped, container decodes';
  is_deeply $s->decode_agtype('{"a": 2.5::numeric, "b": "x"}'),
    { a => 2.5, b => 'x' }, '::numeric inside a map is stripped';

  is $s->decode_agtype('"1.5::numeric"'), '1.5::numeric',
    '::numeric inside a string literal is kept';
  is_deeply $s->decode_agtype('{"n": "x 1.5::numeric y"}'),
    { n => 'x 1.5::numeric y' }, '::numeric inside a map string value is kept';

  # Large decimals: exact string, no NV rounding.
  is $s->decode_agtype('0.1234567890123456789::numeric'),
    '0.1234567890123456789', 'long fraction scalar keeps its exact string';
  is $s->decode_agtype('12345678901234567890.123456789::numeric'),
    '12345678901234567890.123456789', 'large decimal scalar keeps its exact string';
  is_deeply $s->decode_agtype('[0.1234567890123456789::numeric, 1.5::numeric]'),
    ['0.1234567890123456789', 1.5], 'large decimal in a list stays exact string';
  is_deeply $s->decode_agtype('{"v": 12345678901234567890.123456789::numeric}'),
    { v => '12345678901234567890.123456789' },
    'large decimal in a map stays exact string';

  # IV boundary: an integer that fits an IV stays a number, exactly.
  my $iv = $s->decode_agtype('9007199254740993::numeric');
  is $iv, '9007199254740993', 'integer beyond 2**53 but within IV is exact';
  is $iv + 0, 9007199254740993, 'and is a real integer, not a rounded double';
  is_deeply $s->decode_agtype('[9007199254740993::numeric]'), [9007199254740993],
    'IV-range integer in a list is exact';
}

# Linear time: a long digit run without ::numeric (karr k26).
{
  my $digits = '1' x 16000;
  my $t0 = [Time::HiRes::gettimeofday()];
  my $r = $s->decode_agtype($digits);
  my $took = Time::HiRes::tv_interval($t0);
  ok $took < 0.1, "16000 digits without ::numeric decode in ${took}s";
  ok defined $r, 'and still decode to something';
}

# Character and byte strings give the same text (karr k26).
{
  my $cell = qq{{"name": "caf\x{e9}"}::vertex};
  my $chars = $cell; utf8::upgrade($chars);
  my $bytes = $cell; utf8::encode($bytes);
  ok utf8::is_utf8($chars), 'character cell carries the UTF8 flag';
  is_deeply $s->decode_agtype($chars), { name => "caf\x{e9}" }, 'character string';
  is_deeply $s->decode_agtype($bytes), { name => "caf\x{e9}" }, 'byte string';
  is_deeply $s->decode_agtype(qq{{"n": "\x{263a}"}}), { n => "\x{263a}" }, 'wide character';
  is $s->decode_agtype(qq{"caf\x{e9}"}), "caf\x{e9}", 'quoted scalar, characters';
}

# A map that cannot be decoded throws, without naming the value (karr k26).
{
  my $e = exception { $s->decode_agtype('{"secret": oops}::vertex') };
  ok $e, 'broken map throws';
  like "$e", qr/decode_agtype.*map.*::vertex/, 'message names kind and suffix';
  unlike "$e", qr/secret|oops/, 'message does not carry the value';
  $e = exception { $s->decode_agtype('[1, secret') };
  like "$e", qr/list/, 'broken list throws';
  unlike "$e", qr/secret/, 'no value in the list message';
}

done_testing;
