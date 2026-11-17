use strict;
use warnings;
use Test::More;
use DBIO::PostgreSQL::Diff::Type;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';

# karr k121 (U8), offline half of t/139-diff-type-live.t: a change to
# a type both sides have that is no new enum value is refused, by name.
subtest 'diff-type-change' => sub {
  my $class = 'DBIO::PostgreSQL::Diff::Type';

  my sub enum {
    return { schema_name => 'public', type_name => 't', type_kind => 'enum', values => [@_] };
  }

  my sub comp {
    return {
      schema_name => 'public', type_name => 't', type_kind => 'composite',
      attributes => [ map { { name => $_->[0], type => $_->[1], ordinal => 1 } } @_ ],
    };
  }

  my sub range {
    return { schema_name => 'public', type_name => 't', type_kind => 'range', subtype => $_[0] };
  }

  my sub refused {
    my ($from, $to) = @_;
    my @ops = eval { $class->diff({ 'public.t' => $from }, { 'public.t' => $to }) };
    return ($@, scalar @ops);
  }

  my ($err, $n) = refused(comp([a => 'integer']), comp([a => 'integer'], [b => 'text']));
  like $err, qr/\Arefusing to diff: composite type public\.t has other attributes in the target than in the database\n/,
    'composite: an added attribute is refused';
  like $err, qr/\+ b text/, '... and the added attribute is named';
  like $err, qr/ADD ATTRIBUTE/, '... and the way out is named';
  like $err, qr/No statement was generated\./, '... and no statement was written';
  is $n, 0, '... and no operation built';

  ($err) = refused(comp([a => 'integer'], [b => 'text']), comp([a => 'integer']));
  like $err, qr/- b text/, 'composite: a dropped attribute is named';

  ($err) = refused(comp([a => 'integer']), comp([a => 'bigint']));
  like $err, qr/- a integer/m, 'composite: a changed type is named, old';
  like $err, qr/\+ a bigint/m, '... and new';

  ($err) = refused(range('integer'), range('bigint'));
  like $err, qr/\Arefusing to diff: range type public\.t has another subtype in the target than in the database\n/,
    'range: another subtype is refused';
  like $err, qr/integer.*bigint/s, '... both subtypes are named';

  ($err) = refused(enum(qw(a b c)), enum(qw(a c)));
  like $err, qr/\Arefusing to diff: enum type public\.t has lost the value\(s\) 'b' in the target\n/,
    'enum: a lost value is refused';

  ($err) = refused(enum(qw(a b c)), enum(qw(a c b)));
  like $err, qr/\Arefusing to diff: enum type public\.t has its values in another order in the target\n/,
    'enum: another order is refused';

  ($err) = refused(enum(qw(a b)), enum(qw(a c b)));
  is $err, '', 'enum: a value added in the middle is not refused';

  # This line asserted that a value added between two the database has is "still
  # one ADD VALUE" (appended, no position), which left the type in another order
  # and made the next diff refuse it. The claim now: the value goes where the
  # target has it, and the statements run in an order in which each position
  # names a value that exists by then.
  my sub add_sql {
    my ($from, $to) = @_;
    return [ map { split /\n/, $_->as_sql }
      $class->diff({ 'public.t' => enum(@$from) }, { 'public.t' => enum(@$to) }) ];
  }
  is_deeply add_sql([qw(a b)], [qw(a c b)]), [ q{ALTER TYPE public.t ADD VALUE 'c' AFTER 'a';} ],
    'enum: a value in the middle is added AFTER its predecessor';
  is_deeply add_sql([qw(a b)], [qw(c a b)]), [ q{ALTER TYPE public.t ADD VALUE 'c' BEFORE 'a';} ],
    'enum: a new first value is added BEFORE the old first one';
  is_deeply add_sql([qw(a b)], [qw(a b c)]), [ q{ALTER TYPE public.t ADD VALUE 'c';} ],
    'enum: a value at the end has no position';
  is_deeply add_sql([qw(a b)], [qw(a c d b e)]), [
    q{ALTER TYPE public.t ADD VALUE 'c' AFTER 'a';},
    q{ALTER TYPE public.t ADD VALUE 'd' AFTER 'c';},
    q{ALTER TYPE public.t ADD VALUE 'e';},
  ], 'enum: several new values each follow the one before, which exists by then';
  is_deeply add_sql([qw(a b)], [qw(x y a b)]), [
    q{ALTER TYPE public.t ADD VALUE 'x' BEFORE 'a';},
    q{ALTER TYPE public.t ADD VALUE 'y' AFTER 'x';},
  ], 'enum: new values ahead of all old ones';

  ($err) = refused(enum(qw(a b)), comp([a => 'integer']));
  like $err, qr/\Arefusing to diff: type public\.t is a composite type in the target and an enum type in the database\n/,
    'a type of another kind is refused';

  # Unchanged behaviour.
  my @ops = $class->diff({ 'public.t' => enum(qw(a b)) }, { 'public.t' => enum(qw(a b c)) });
  is_deeply [ map { $_->action } @ops ], ['add_value'], 'a new value: add_value';
  is_deeply $ops[0]->added_values, ['c'], '... of c';
  @ops = $class->diff({ 'public.t' => comp([a => 'integer']) }, { 'public.t' => comp([a => 'integer']) });
  is scalar @ops, 0, 'the same composite type: no operation';
  @ops = $class->diff({ 'public.t' => range('integer') }, { 'public.t' => range('integer') });
  is scalar @ops, 0, 'the same range type: no operation';

  # Several at once are named together.
  {
    my $e = enum(qw(x y));
    my $r = range('integer');
    $err = eval {
      $class->diff(
        { 'public.a' => { %$e, type_name => 'a' }, 'public.b' => { %$r, type_name => 'b' } },
        { 'public.a' => { %{ enum(qw(x)) }, type_name => 'a' },
          'public.b' => { %{ range('bigint') }, type_name => 'b' } },
      );
      '';
    } // $@;
    $err = $@ if $@;
  }
  like $err, qr/type public\.a.*type public\.b/s, 'every refused type is named in one message';

  # An empty type the target declares (an entry with an empty list) where the
  # database has values or attributes is refused; a type the target lacks is a
  # drop. (t/139-diff-type-live.t is the live half, with the rows.)
  ($err) = refused(enum(qw(a b)), enum());
  like $err, qr/\Arefusing to diff: enum type public\.t is declared empty in the target but has values in the database\n/,
    'enum: declared empty in the target, with values in the database, is refused';
  like $err, qr/DROP TYPE of a type the columns.*No statement was generated\./s, '... the message says why and that no statement was written';

  ($err) = refused(comp([a => 'integer']), comp());
  like $err, qr/\Arefusing to diff: composite type public\.t is declared empty in the target but has attributes in the database\n/,
    'composite: declared empty in the target, with attributes in the database, is refused';

  ($err, $n) = refused(enum(), enum());
  is $err, '', 'enum: empty on both sides is not refused';
  is $n, 0, '... and no operation';

  my @drop = $class->diff({ 'public.t' => enum(qw(a b)) }, {});
  is_deeply [ map { $_->as_sql } @drop ], ['DROP TYPE public.t;'],
    'a type the target does not declare at all stays a plain drop';
};

# karr k121 (U8), offline half of t/139-diff-type-live.t: what the
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
subtest 'diff-type-extras' => sub {
  my $class = 'DBIO::PostgreSQL::Diff::Type';

  my sub range {
    return { schema_name => 'public', type_name => 'r', type_kind => 'range', subtype => 'text', @_ };
  }

  my sub comp {
    return {
      schema_name => 'public', type_name => 'c', type_kind => 'composite',
      attributes => [ map { { name => $_->[0], type => $_->[1], ordinal => 1,
                              (defined $_->[2] ? (collation => $_->[2]) : ()) } } @_ ],
    };
  }

  my sub refused {
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
};

done_testing;
