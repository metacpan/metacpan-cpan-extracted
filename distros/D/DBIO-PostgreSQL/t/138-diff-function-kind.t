use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Diff::Function;

# karr k121 (U7, points 3 and 4), offline half of t/137-diff-function-kind-live.t:
# the kind of a routine.
#
# A function and a procedure can not be changed into each other by CREATE OR
# REPLACE (the server: "cannot change routine kind"), so the diff drops the
# old one and creates the new one. An aggregate or a window function has no
# definition in the model, so the diff refuses one it would have to create
# or change.

my $class = 'DBIO::PostgreSQL::Diff::Function';

my $func = {
  schema_name => 'public', function_name => 'f', identity_args => 'integer',
  kind => 'f', definition => 'CREATE OR REPLACE FUNCTION public.f(integer) RETURNS integer ...',
};
my $proc = {
  schema_name => 'public', function_name => 'f', identity_args => 'IN integer',
  kind => 'p', definition => 'CREATE OR REPLACE PROCEDURE public.f(IN integer) ...',
};

# Under one key: a function without arguments that is now a procedure.
my @ops = $class->diff(
  { 'public.g()' => { %$func, function_name => 'g', identity_args => '' } },
  { 'public.g()' => { %$proc, function_name => 'g', identity_args => '' } },
);
is_deeply [ map { $_->action } @ops ], [qw( drop create )], 'same key: a drop, then a create';
ok $ops[0]->replaced, '... the drop is the first half of a rebuild';
ok !$ops[1]->replaced, '... the create is not';
like $ops[0]->as_sql, qr/\ADROP FUNCTION public\.g\(\);\z/, 'the function is dropped as a function';
like $ops[1]->as_sql, qr/\ACREATE OR REPLACE PROCEDURE public\.f/, 'the procedure is created';

# Under two keys: the procedure's identity arguments carry the mode.
@ops = $class->diff(
  { 'public.f(integer)'    => $func },
  { 'public.f(IN integer)' => $proc },
);
is_deeply [ map { $_->action } @ops ], [qw( drop create )], 'two keys: a drop, then a create, no more';
is $ops[0]->function_key, 'public.f(integer)',    '... the drop is of the function';
is $ops[1]->function_key, 'public.f(IN integer)', '... the create of the procedure';

@ops = $class->diff(
  { 'public.f(IN integer)' => $proc },
  { 'public.f(integer)'    => $func },
);
is_deeply [ map { $_->action } @ops ], [qw( drop create )], 'procedure to function: a drop, then a create';
like $ops[0]->as_sql, qr/\ADROP PROCEDURE public\.f\(IN integer\);\z/, '... a procedure is dropped as one';

# Two routines of one name and other argument types are two routines.
@ops = $class->diff(
  { 'public.f(integer)' => $func },
  { 'public.f(IN text)' => { %$proc, identity_args => 'IN text' } },
);
is_deeply [ map { $_->action } @ops ], [qw( create drop )], 'other argument types: not a rebuild';
ok !$ops[1]->replaced, '... the drop is a removal';

# Aggregates and window functions.
my $agg = { schema_name => 'public', function_name => 'mysum', identity_args => 'integer',
  kind => 'a', fingerprint => 'n|0|int4pl|...|0' };
my $win = { schema_name => 'public', function_name => 'w', identity_args => '',
  kind => 'w', fingerprint => 'internal|window_rank||i|s|f|bigint' };

my $refused = sub {
  my @r = eval { $class->diff(@_) };
  return ($@, scalar @r);
};

my ($err, $n) = $refused->({}, { 'public.mysum(integer)' => $agg });
like $err, qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the target and not in the database\n/,
  'an aggregate to create is refused, by name';
like $err, qr/No statement was generated\./, '... and says no statement was written';
is $n, 0, '... and builds no operation';

($err) = $refused->({}, { 'public.w()' => $win });
like $err, qr/\Arefusing to diff: window function public\.w\(\) is in the target and not in the database\n/,
  'a window function to create is refused';

($err) = $refused->(
  { 'public.mysum(integer)' => { %$agg, fingerprint => 'other' } },
  { 'public.mysum(integer)' => $agg },
);
like $err, qr/\Arefusing to diff: aggregate public\.mysum\(integer\) is in the database and in the target with another definition\n/,
  'an aggregate with another definition is refused';

($err) = $refused->(
  { 'public.f(integer)' => $func },
  { 'public.f(integer)' => { %$agg, function_name => 'f' } },
);
like $err, qr/\Arefusing to diff: aggregate public\.f\(integer\) is in the target, and the database has function public\.f\(integer\) of the same signature/,
  'a function that is an aggregate in the target is refused';

@ops = $class->diff({ 'public.mysum(integer)' => $agg }, { 'public.mysum(integer)' => { %$agg } });
is scalar @ops, 0, 'the same aggregate on both sides is no operation';

# One only the database has is dropped like any function (karr k121): an
# aggregate by DROP AGGREGATE, a window function by DROP FUNCTION.
@ops = $class->diff({ 'public.mysum(integer)' => $agg, 'public.w()' => $win }, {});
is scalar @ops, 2, 'an aggregate and a window function only the database has are dropped';
is_deeply [ map { $_->action } @ops ], [qw(drop drop)], '... both as drops';
is $ops[0]->as_sql, 'DROP AGGREGATE public.mysum(integer);', 'an aggregate is dropped by DROP AGGREGATE';
is $ops[1]->as_sql, 'DROP FUNCTION public.w();', 'a window function is dropped by DROP FUNCTION';

my $star = { schema_name => 'public', function_name => 'cnt', identity_args => '',
  kind => 'a', fingerprint => 'n|0|int8inc|...' };
@ops = $class->diff({ 'public.cnt()' => $star }, {});
is $ops[0]->as_sql, 'DROP AGGREGATE public.cnt(*);', 'an aggregate without arguments is dropped as name(*)';

# A procedure and a function of the same input argument types can not stand
# side by side, and CREATE OR REPLACE can not change one into the other. Where
# the keys pair (the mode IN left out), the diff drops and creates. Where they
# do not -- an INOUT argument, a name that changed, an OUT argument one side
# has -- the create would meet the old routine: the server answers "function
# ... already exists with same argument types". That is refused ahead
# (karr k121).
my $in_proc = { %$proc, function_name => 'f', identity_args => 'INOUT x integer',
  input_types => 'integer' };
my $in_func = { %$func, function_name => 'f', identity_args => 'x integer',
  input_types => 'integer' };

($err, $n) = $refused->(
  { 'public.f(INOUT x integer)' => $in_proc },
  { 'public.f(x integer)'       => $in_func },
);
like $err, qr/\Arefusing to diff: procedure public\.f\(INOUT x integer\) is in the database and function public\.f\(x integer\) is in the target, under the same argument types\n/,
  'a procedure with an INOUT argument that becomes a function is refused, by name';
like $err, qr/DROP PROCEDURE public\.f\(INOUT x integer\)/, '... the message names the manual way out';
like $err, qr/No statement was generated\./, '... and says no statement was written';
is $n, 0, '... and builds no operation';

($err) = $refused->(
  { 'public.f(x integer)'       => $in_func },
  { 'public.f(INOUT x integer)' => $in_proc },
);
like $err, qr/\Arefusing to diff: function public\.f\(x integer\) is in the database and procedure public\.f\(INOUT x integer\) is in the target, under the same argument types\n/,
  'a function that becomes a procedure with an INOUT argument is refused';
like $err, qr/DROP FUNCTION public\.f\(x integer\)/, '... with DROP FUNCTION as the way out';

($err) = $refused->(
  { 'public.f(IN y integer)' => { %$proc, identity_args => 'IN y integer', input_types => 'integer' } },
  { 'public.f(z integer)'    => { %$in_func, identity_args => 'z integer' } },
);
like $err, qr/\Arefusing to diff: procedure public\.f\(IN y integer\) is in the database and function public\.f\(z integer\)/,
  'another argument name unpairs the keys, and is refused the same way';

# Paired keys and other argument types stay as they were.
@ops = $class->diff(
  { 'public.f(OUT x integer, IN y integer)' => { %$proc, identity_args => 'OUT x integer, IN y integer', input_types => 'integer' } },
  { 'public.f(OUT x integer, y integer)'    => { %$func, identity_args => 'OUT x integer, y integer', input_types => 'integer' } },
);
is_deeply [ map { $_->action } @ops ], [qw( drop create )], 'keys that pair with the mode IN left out are rebuilt, not refused';

@ops = $class->diff(
  { 'public.f(INOUT x integer)' => $in_proc },
  { 'public.f(x text)'          => { %$in_func, identity_args => 'x text', input_types => 'text' } },
);
is_deeply [ map { $_->action } @ops ], [qw( create drop )], 'other input types: two routines, not refused';

# A model without input_types (built by hand) is not refused: nothing says
# the types are the same.
@ops = $class->diff(
  { 'public.f(INOUT x integer)' => { %$in_proc, input_types => undef } },
  { 'public.f(x integer)'       => { %$in_func, input_types => undef } },
);
is_deeply [ map { $_->action } @ops ], [qw( create drop )], 'no input_types in the model: no refusal';

done_testing;
