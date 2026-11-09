use strict;
use warnings;
use Test::More;

use DBIO::Deploy::Base;
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Column;

# karr k152 -- the guard of the deploy (core k399) asks the column operation
# whether a change of type may alter a stored value.
#
# WHY it exists: apply runs a diff that drops something or changes a type in a
# way that can round, cut or re-read values only when it is released with
# allow_destructive. The operations answer through `lossy`; a type change the
# operation does not know to keep every value is lossy -- the guard errs
# towards asking. integer to bigint, a longer varchar, a numeric that keeps
# every digit are what a deploy runs without the release.
#
# Without a server. t/196-deploy-guard-live.t has apply against one.

my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

sub col {
  my ($type, %more) = @_;
  return { column_name => 'v', data_type => $type, not_null => 0, %more };
}

# The operations of a column that goes from one declaration to the other.
sub ops {
  my ($from, $to) = @_;
  return DBIO::PostgreSQL::Diff::Column->diff(
    { 'public.t' => [ $from ] }, { 'public.t' => [ $to ] }, $tables, $tables);
}

sub lossy {
  my ($from, $to) = @_;
  my @ops = ops($from, $to);
  die "expected one operation, got " . @ops unless @ops == 1;
  return $ops[0]->lossy ? 1 : 0;
}

# --- 1. the table: every pair says what it keeps -------------------------------

my @cases = (
  # [ from, to, lossy, why ]
  [ 'smallint', 'integer', 0, 'smallint to integer' ],
  [ 'smallint', 'bigint',  0, 'smallint to bigint' ],
  [ 'integer',  'bigint',  0, 'integer to bigint' ],
  [ 'bigint',   'integer', 1, 'bigint to integer cuts' ],
  [ 'integer',  'smallint', 1, 'integer to smallint cuts' ],
  [ 'character varying(10)', 'character varying(20)', 0, 'varchar(10) to varchar(20)' ],
  [ 'character varying(10)', 'character varying(10)', undef, 'the same type is no change' ],
  [ 'character varying(20)', 'character varying(10)', 1, 'varchar(20) to varchar(10) cuts' ],
  [ 'character varying(10)', 'character varying', 0, 'varchar(10) to varchar without limit' ],
  [ 'character varying', 'character varying(10)', 1, 'varchar without limit to varchar(10) cuts' ],
  [ 'character varying(10)', 'text', 0, 'varchar(n) to text' ],
  [ 'text', 'character varying(10)', 1, 'text to varchar(n) cuts' ],
  [ 'text', 'character varying', 0, 'text to varchar without limit (the same strings)' ],
  [ 'numeric(10,2)', 'numeric(12,2)', 0, 'numeric(10,2) to numeric(12,2) grows' ],
  [ 'numeric(10,2)', 'numeric(12,4)', 0, 'numeric(10,2) to numeric(12,4): more scale, as many digits before the point' ],
  [ 'numeric(10,2)', 'numeric(10,4)', 1, 'numeric(10,2) to numeric(10,4): fewer digits before the point' ],
  [ 'numeric(10,2)', 'numeric(10,1)', 1, 'numeric(10,2) to numeric(10,1) rounds' ],
  [ 'numeric(10,2)', 'numeric(8,2)', 1, 'numeric(10,2) to numeric(8,2) can overflow' ],
  [ 'numeric(10,2)', 'numeric', 0, 'numeric(10,2) to numeric without limit' ],
  [ 'numeric', 'numeric(10,2)', 1, 'numeric without limit to numeric(10,2)' ],
  [ 'numeric(10,0)', 'numeric(11,0)', 0, 'numeric(10) to numeric(11)' ],
  [ 'timestamp(3) with time zone', 'timestamp(6) with time zone', 0, 'timestamptz(3) to (6)' ],
  [ 'timestamp(6) with time zone', 'timestamp(3) with time zone', 1, 'timestamptz(6) to (3) rounds' ],
  [ 'timestamp without time zone', 'timestamp with time zone', 1, 'timestamp to timestamptz reads the session time zone' ],
  [ 'real', 'double precision', 1, 'real to double precision is not in the list' ],
  [ 'integer', 'text', 1, 'integer to text' ],
  [ 'text', 'integer', 1, 'text to integer' ],
  [ 'character(5)', 'character(10)', 1, 'char(n) pads: left out' ],
  [ 'integer', 'numeric(12,0)', 1, 'integer to numeric is not in the list' ],
);

for my $case (@cases) {
  my ($from, $to, $want, $why) = @$case;
  if (!defined $want) {
    is scalar(() = ops(col($from), col($to))), 0, "$why: no operation";
    next;
  }
  is lossy(col($from), col($to)), $want, ($want ? 'lossy' : 'lossless') . ": $why";
}

# the size given as a key of its own, as a model built by hand has it
is lossy(col('varchar', size => 10), col('varchar', size => 20)), 0, 'a size key: varchar 10 to 20 is lossless';
is lossy(col('varchar', size => 20), col('varchar', size => 10)), 1, '... and 20 to 10 is lossy';
is lossy(col('numeric', size => [10, 2]), col('numeric', size => [12, 2])), 0, '... numeric [10,2] to [12,2] is lossless';

# --- 2. what else a column operation says --------------------------------------

{
  my @ops = ops(col('integer'), col('integer', not_null => 1));
  is scalar(@ops), 1, 'NOT NULL set: one operation';
  ok !$ops[0]->lossy, '... not lossy (the server refuses it over NULLs, which _check_before_apply names)';

  @ops = ops(col('text'), col('text', default_value => q{'x'::text}));
  ok !$ops[0]->lossy, 'a default set is not lossy';

  my ($drop) = DBIO::PostgreSQL::Diff::Column->new(action => 'drop', column_name => 'v', table_key => 'public.t');
  ok !$drop->lossy, 'a column drop answers through its action (a drop), not through lossy';
  my ($add) = DBIO::PostgreSQL::Diff::Column->new(action => 'add', column_name => 'v', table_key => 'public.t',
    new_info => col('text'));
  ok !$add->lossy, 'an added column is not lossy';
}

# enum and composite changes are lossy, with or without USING
{
  my $enum = sub { col($_[0], type_category => 'e', type_schema => 'public', enum_type => $_[0]) };
  is lossy($enum->('e_old'), $enum->('e_new')), 1, 'enum to enum is lossy';
  is lossy(col('text'), $enum->('e_new')), 1, 'text to enum is lossy';
  is lossy($enum->('e_old'), col('text')), 1, 'enum to text is lossy';
}

# a USING makes any change lossy, and is decided once
{
  my $calls = 0;
  DBIO::PostgreSQL::Diff::Column->register_using_hook(k152 => sub {
    $calls++;
    return 'v::bigint' if $_[0]{new_type} eq 'bigint';
    return undef;
  });
  my @ops = ops(col('integer'), col('bigint'));
  is $ops[0]->lossy, 1, 'integer to bigint with a USING of a hook is lossy';
  like $ops[0]->as_sql, qr/TYPE bigint USING v::bigint;/, '... the statement carries the same USING';
  my $once = $calls;
  $ops[0]->lossy; $ops[0]->as_sql; $ops[0]->as_sql;
  is $calls, $once, '... the hook was asked once, when the operation was built';
  DBIO::PostgreSQL::Diff::Column->unregister_using_hook('k152');
  is lossy(col('integer'), col('bigint')), 0, 'without the hook integer to bigint is lossless again';
}

# --- 3. the guard reads it -----------------------------------------------------

{
  my $model = sub {
    my ($type) = @_;
    return {
      tables  => { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } },
      columns => { 'public.t' => [ col($type) ] },
    };
  };
  my $widen = DBIO::PostgreSQL::Diff->new(source => $model->('integer'), target => $model->('bigint'));
  is scalar(() = $widen->destructive_operations), 0, 'integer to bigint: the guard has nothing to ask for';
  my $narrow = DBIO::PostgreSQL::Diff->new(source => $model->('bigint'), target => $model->('integer'));
  my @risky = $narrow->destructive_operations;
  is scalar(@risky), 1, 'bigint to integer: the guard asks';
  like $risky[0]->summary, qr/column: public\.t\.v \(integer\)/, '... and names the column';
}

# --- 4. the deploy is the base's -----------------------------------------------

for my $method (qw( apply upgrade )) {
  is(DBIO::PostgreSQL::Deploy->can($method), DBIO::Deploy::Base->can($method),
    "Deploy inherits $method from DBIO::Deploy::Base: the same code, not a copy");
}
ok(DBIO::PostgreSQL::Deploy->can('_check_before_apply') != DBIO::Deploy::Base->can('_check_before_apply'),
  'the driver takes part through _check_before_apply');

done_testing;
