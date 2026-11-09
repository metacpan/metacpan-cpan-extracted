use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Type;

# karr k121 (U8), offline half of t/139-diff-type-change-live.t: a change to
# a type both sides have that is no new enum value is refused, by name.

my $class = 'DBIO::PostgreSQL::Diff::Type';

sub enum {
  return { schema_name => 'public', type_name => 't', type_kind => 'enum', values => [@_] };
}

sub comp {
  return {
    schema_name => 'public', type_name => 't', type_kind => 'composite',
    attributes => [ map { { name => $_->[0], type => $_->[1], ordinal => 1 } } @_ ],
  };
}

sub range {
  return { schema_name => 'public', type_name => 't', type_kind => 'range', subtype => $_[0] };
}

sub refused {
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
sub add_sql {
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
# drop. (t/173-diff-empty-type-live.t is the live half, with the rows.)
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

done_testing;
