use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Type;

# karr k121 (U8), offline half of t/172-diff-type-extras-live.t: what the
# catalog says of a type beyond its kind, its values, its attributes and its
# range subtype.
#
# WHAT it claims:
#
#  1. a range type that differs from the database in its collation, operator
#     class, canonical function or subtype_diff function, and a composite
#     type whose attribute differs in its collation, used to give NO
#     operation and no message -- an upgrade that reported success and left
#     the type as it was (t/140 refuses the other changes to a type; these
#     slipped through because the model did not carry them). Each is now
#     refused, naming the type and what differs;
#  2. a type that carries them on both sides is no operation, and so is a
#     model that does not carry the keys at all (a model built by hand);
#  3. a type the diff has to create is created WITH them: refusing the
#     difference afterwards for a type the diff itself made without them
#     would refuse every second diff for good.
#
# t/140 held the older claim (a type that differs in more than new enum
# values is refused); it is unchanged and still holds.

my $class = 'DBIO::PostgreSQL::Diff::Type';

sub range {
  return { schema_name => 'public', type_name => 'r', type_kind => 'range', subtype => 'text', @_ };
}

sub comp {
  return {
    schema_name => 'public', type_name => 'c', type_kind => 'composite',
    attributes => [ map { { name => $_->[0], type => $_->[1], ordinal => 1,
                            (defined $_->[2] ? (collation => $_->[2]) : ()) } } @_ ],
  };
}

sub refused {
  my ($key, $from, $to) = @_;
  my @ops = eval { $class->diff({ $key => $from }, { $key => $to }) };
  return ($@, scalar @ops);
}

for my $case (
  [ collation       => '"C"',                    qr/collation/ ],
  [ subtype_opclass => 'pg_catalog.text_pattern_ops', qr/operator class/ ],
  [ subtype_diff    => 'public.textdiff',        qr/subtype_diff/ ],
  [ canonical       => 'public.canon',           qr/canonical/ ],
) {
  my ($field, $value, $word) = @$case;
  my ($err, $n) = refused('public.r', range(), range($field => $value));
  like $err, qr/\Arefusing to diff: range type public\.r has another \Q$field\E in the target than in the database\n/,
    "range: a $field the database lacks is refused, by name";
  like $err, qr/\Q$value\E/, '... the value is named';
  like $err, qr/drop this one and create it again/, '... and the way out';
  like $err, qr/No statement was generated\./, '... and no statement was written';
  is $n, 0, '... and no operation built';

  ($err) = refused('public.r', range($field => $value), range());
  like $err, qr/another \Q$field\E/, "range: a $field only the database has is refused too";

  my @ops = eval { $class->diff({ 'public.r' => range($field => $value) }, { 'public.r' => range($field => $value) }) };
  is scalar @ops, 0, "range: the same $field on both sides is no operation" or diag $@;
}

# A model without the keys is the same as one with them unset.
{
  my @ops = eval { $class->diff({ 'public.r' => range() }, { 'public.r' => range(collation => undef) }) };
  is scalar @ops, 0, 'range: a missing key and an undef one are the same' or diag $@;
}

# Composite attribute collation.
{
  my ($err, $n) = refused('public.c', comp([ a => 'text' ]), comp([ a => 'text', '"C"' ]));
  like $err, qr/\Arefusing to diff: composite type public\.c has other attributes in the target than in the database\n/,
    'composite: an attribute with another collation is refused, by name';
  like $err, qr/- a text\n/, '... the database attribute is named without it';
  like $err, qr/\+ a text COLLATE "C"\n/, '... the target attribute with it';
  is $n, 0, '... and no operation built';

  my @ops = eval { $class->diff({ 'public.c' => comp([ a => 'text', '"C"' ]) }, { 'public.c' => comp([ a => 'text', '"C"' ]) }) };
  is scalar @ops, 0, 'composite: the same collation on both sides is no operation' or diag $@;
}

# Creating a type writes them.
is(
  $class->new(action => 'create', type_key => 'public.r', type_info => range(
    subtype => 'float8', subtype_diff => 'pg_catalog.float8mi',
  ))->as_sql,
  'CREATE TYPE public.r AS RANGE (SUBTYPE = float8, SUBTYPE_DIFF = pg_catalog.float8mi);',
  'a range created with a subtype_diff function',
);
is(
  $class->new(action => 'create', type_key => 'public.r', type_info => range(
    collation => '"C"', subtype_opclass => 'pg_catalog.text_pattern_ops', canonical => 'public.canon',
  ))->as_sql,
  'CREATE TYPE public.r AS RANGE (SUBTYPE = text, SUBTYPE_OPCLASS = pg_catalog.text_pattern_ops, COLLATION = "C", CANONICAL = public.canon);',
  'a range created with a collation, an operator class and a canonical function',
);
is(
  $class->new(action => 'create', type_key => 'public.c', type_info => comp([ a => 'text', '"C"' ], [ b => 'integer' ]))->as_sql,
  qq{CREATE TYPE public.c AS (\n  a text COLLATE "C",\n  b integer\n);},
  'a composite type created with the collation of an attribute',
);
is(
  $class->new(action => 'create', type_key => 'public.r', type_info => range())->as_sql,
  'CREATE TYPE public.r AS RANGE (SUBTYPE = text);',
  'a plain range is written as before',
);

done_testing;
