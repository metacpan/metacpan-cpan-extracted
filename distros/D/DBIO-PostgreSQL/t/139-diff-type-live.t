use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# Folded from several live files by subject (karr k158): every old file is a
# subtest named after it, with its own private database(s) as before, and
# its helpers in a package block of its own, since named subs and the
# lexicals they close over are file-global otherwise.

# LIVE test for karr k121 (U8): a change to an existing type.
#
# The diff wrote ALTER TYPE ... ADD VALUE for an enum that gained values and
# nothing for any other change to a type both sides have: a composite type
# with other attributes, a range with another subtype, an enum that lost or
# reordered values, a type that is another kind in the target. No operation
# and no message -- an upgrade that reported success and left the type as it
# was. Measured before the fix: every case of part 1 gave an empty list of
# operations.
#
# With database A as what there is and B as what is wanted:
#
#  1. each of those is refused, naming the type and what differs, and no
#     statement is written for anything;
#  2. what ran before is unchanged: a value appended to an enum is one
#     ALTER TYPE ... ADD VALUE and the server takes it, and the same type on
#     both sides is no operation.
{
  package Fold139::TypeChange;
  use Test::More;
  use Test::Exception;

  my ($dbh_a, $dbh_b);

  sub catalog {
    my ($dbh) = @_;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
    return $model;
  }

  sub start_over {
    my ($sql_a, $sql_b) = @_;
    for my $dbh ($dbh_a, $dbh_b) {
      $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
    }
    $dbh_a->do($_) for @$sql_a;
    $dbh_b->do($_) for @$sql_b;
  }

  sub ops {
    return DBIO::PostgreSQL::Diff->new(
      source => catalog($dbh_a), target => catalog($dbh_b))->operations;
  }

  subtest 'diff-type-change' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    $h;
  } qw( t139a t139b );

  # --- 1. refused --------------------------------------------------------------

  start_over(
    [ q{CREATE TYPE public.t AS (a integer, b text)} ],
    [ q{CREATE TYPE public.t AS (a integer, b text, c boolean)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: composite type public\.t has other attributes in the target than in the database/m,
    'a composite type with another attribute is refused, by name';
  like $@, qr/ALTER TYPE/, '... and the message says what to do';
  like $@, qr/No statement was generated\./, '... and that no statement was written';

  start_over(
    [ q{CREATE TYPE public.t AS (a integer, b text)} ],
    [ q{CREATE TYPE public.t AS (a integer, b varchar(5))} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: composite type public\.t has other attributes/m,
    'a composite type with an attribute of another type is refused';

  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = bigint)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: range type public\.r has another subtype in the target than in the database/m,
    'a range type with another subtype is refused';

  start_over(
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
    [ q{CREATE TYPE public.e AS ENUM ('a', 'c')} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: enum type public\.e has lost the value\(s\) 'b' in the target/m,
    'an enum that lost a value is refused';

  start_over(
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
    [ q{CREATE TYPE public.e AS ENUM ('a', 'c', 'b')} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: enum type public\.e has its values in another order in the target/m,
    'an enum with its values in another order is refused';

  start_over(
    [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
    [ q{CREATE TYPE public.t AS (a integer)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: type public\.t is a composite type in the target and an enum type in the database/m,
    'a type that is another kind in the target is refused';

  # --- 2. what ran before ------------------------------------------------------

  start_over(
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b')} ],
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'c')} ],
  );
  my @sql = map { $_->as_sql } @{ ops() };
  is_deeply \@sql, [ q{ALTER TYPE public.e ADD VALUE 'c';} ], 'an enum that gained a value: one ADD VALUE';
  ok eval { $dbh_a->do($_) for @sql; 1 }, '... the server takes it' or diag $@;
  is scalar @{ ops() }, 0, '... and afterwards the diff is empty';

  # A value between two the database has goes where the target has it. It was
  # appended, the type had another order than the target, and the next diff
  # refused it as a reordering.
  start_over(
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b', 'f')} ],
    [ q{CREATE TYPE public.e AS ENUM ('x', 'a', 'c', 'd', 'b', 'e', 'f', 'g')} ],
  );
  @sql = map { $_->as_sql } @{ ops() };
  ok eval { $dbh_a->do($_) for map { split /\n/ } @sql; 1 }, 'values between and around old ones: the server takes them' or diag $@;
  is_deeply [ @{ $dbh_a->selectcol_arrayref(
      q{SELECT enumlabel FROM pg_enum WHERE enumtypid = 'public.e'::regtype ORDER BY enumsortorder}) } ],
    [qw(x a c d b e f g)], '... and pg_enum has them in the target order';
  is scalar @{ ops() }, 0, '... and afterwards the diff is empty';

  start_over(
    [ q{CREATE TYPE public.t AS (a integer, b text)}, q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
    [ q{CREATE TYPE public.t AS (a integer, b text)}, q{CREATE TYPE public.r AS RANGE (SUBTYPE = integer)} ],
  );
  is scalar @{ ops() }, 0, 'the same types on both sides are no operation';
  };
}

# LIVE test for karr k121 (U8), the changes to an existing type that the diff-type-change subtest
# does not hold. Measured before the fix, with database A as what there is
# and B as what is wanted:
#
#  1. a range type with another subtype_diff function, collation or operator
#     class, and a composite type whose attribute has another collation: the
#     diff gave NO operation and no message (the model carried none of them),
#     an upgrade that reported success and left the type as it was. Part 1
#     claims each is now refused, naming the type and what differs.
#  2. a type the diff creates is created with them, so the model of the
#     database that ran the statements equals the target's, and the next
#     diff is empty. (Without it part 1 would refuse that next diff for good.)
#  3. what already worked and is held here (green before the fix, the measured
#     table is in the card): an enum value renamed, a composite attribute
#     renamed or of another size, a type of another kind with a column on it
#     are refused; a type moved to another schema or renamed with a column on
#     it is a CREATE, an ALTER COLUMN ... TYPE ... USING and a DROP, the
#     server takes them and the next diff is empty.
{
  package Fold139::TypeExtras;
  use Test::More;
  use Test::Exception;

  my ($dbh_a, $dbh_b);

  sub catalog {
    my ($dbh) = @_;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
    return $model;
  }

  sub start_over {
    my ($sql_a, $sql_b) = @_;
    for my $dbh ($dbh_a, $dbh_b) {
      $dbh->do($_) for 'DROP SCHEMA IF EXISTS s CASCADE', 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
    }
    $dbh_a->do($_) for @$sql_a;
    $dbh_b->do($_) for @$sql_b;
  }

  sub ops {
    return DBIO::PostgreSQL::Diff->new(
      source => catalog($dbh_a), target => catalog($dbh_b))->operations;
  }

  subtest 'diff-type-extras' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    $h;
  } qw( t172a t172b );

  # --- 1. refused, where nothing was ------------------------------------------

  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = float8)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = float8, SUBTYPE_DIFF = float8mi)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: range type public\.r has another subtype_diff in the target than in the database/m,
    'a range type with another subtype_diff function is refused, by name';
  like $@, qr/float8mi/, '... the function is named';
  like $@, qr/No statement was generated\./, '... and that no statement was written';

  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text, COLLATION = "C")} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: range type public\.r has another collation in the target than in the database/m,
    'a range type with another collation is refused';

  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text, SUBTYPE_OPCLASS = text_pattern_ops)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: range type public\.r has another subtype_opclass in the target than in the database/m,
    'a range type with another operator class is refused';

  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text, SUBTYPE_OPCLASS = text_pattern_ops)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text)} ],
  );
  throws_ok { ops() } qr/another subtype_opclass/, '... also when only the database has it';

  start_over(
    [ q{CREATE TYPE public.c AS (a text)} ],
    [ q{CREATE TYPE public.c AS (a text COLLATE "C")} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: composite type public\.c has other attributes in the target than in the database/m,
    'a composite type whose attribute has another collation is refused';
  like $@, qr{\+ a text COLLATE pg_catalog\."C"}, q{... the attribute is named with it};

  # The same on both sides: the default collation and operator class are not
  # "set" (a model that named them would make every range refused).
  start_over(
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text)}, q{CREATE TYPE public.q AS RANGE (SUBTYPE = int4)},
      q{CREATE TYPE public.c AS (a text, b integer)} ],
    [ q{CREATE TYPE public.r AS RANGE (SUBTYPE = text)}, q{CREATE TYPE public.q AS RANGE (SUBTYPE = int4)},
      q{CREATE TYPE public.c AS (a text, b integer)} ],
  );
  is scalar @{ ops() }, 0, 'types with nothing set are no operation';
  my $m = catalog($dbh_a)->{types};
  ok !defined $m->{'public.r'}{$_}, "a default range has no $_ in the model" for qw( collation subtype_opclass canonical subtype_diff );
  ok !defined $m->{'public.c'}{attributes}[0]{collation}, 'an attribute of the default collation has none in the model';

  # --- 2. created with them ----------------------------------------------------

  my @extras = (
    q{CREATE TYPE public.r AS RANGE (SUBTYPE = float8, SUBTYPE_DIFF = float8mi)},
    q{CREATE TYPE public.s AS RANGE (SUBTYPE = text, COLLATION = "C", SUBTYPE_OPCLASS = text_pattern_ops)},
    q{CREATE TYPE public.c AS (a text COLLATE "C", b integer)},
  );
  start_over([], \@extras);
  my @sql = map { $_->as_sql } @{ ops() };
  is scalar @sql, 3, 'three types to create';
  ok eval { $dbh_a->do($_) for @sql; 1 }, '... the server takes them' or diag $@;
  is scalar @{ ops() }, 0, '... and afterwards the diff is empty' or diag join "\n", map { $_->as_sql } @{ ops() };
  $m = catalog($dbh_a)->{types};
  is $m->{'public.r'}{subtype_diff}, 'pg_catalog.float8mi', 'the model names the subtype_diff function with its schema';
  is $m->{'public.s'}{collation}, 'pg_catalog."C"', '... the collation';
  is $m->{'public.s'}{subtype_opclass}, 'pg_catalog.text_pattern_ops', '... the operator class';
  is $m->{'public.c'}{attributes}[0]{collation}, 'pg_catalog."C"', '... the collation of an attribute';

  # --- 3. what was right before ------------------------------------------------

  start_over(
    [ q{CREATE TYPE public.e AS ENUM ('a', 'b')} ],
    [ q{CREATE TYPE public.e AS ENUM ('a', 'x')} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: enum type public\.e has lost the value\(s\) 'b' in the target/m,
    'an enum value renamed is refused (a lost value and a new one)';

  start_over(
    [ q{CREATE TYPE public.c AS (a integer, b text)} ],
    [ q{CREATE TYPE public.c AS (a integer, z text)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: composite type public\.c has other attributes/m,
    'a composite attribute renamed is refused';

  start_over(
    [ q{CREATE TYPE public.c AS (a varchar(5))} ],
    [ q{CREATE TYPE public.c AS (a varchar(9))} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: composite type public\.c has other attributes/m,
    'a composite attribute of another size is refused';

  start_over(
    [ q{CREATE TYPE public.k AS ENUM ('a')}, q{CREATE TABLE public.t (v public.k)} ],
    [ q{CREATE TYPE public.k AS (x integer)}, q{CREATE TABLE public.t (v public.k)} ],
  );
  throws_ok { ops() } qr/\Arefusing to diff: type public\.k is a composite type in the target and an enum type in the database/m,
    'a type of another kind with a column on it is refused';

  for my $case (
    [ 'moved to another schema',
      [ q{CREATE TYPE public.e AS ENUM ('a', 'b')}, q{CREATE TABLE public.t (v public.e)} ],
      [ q{CREATE SCHEMA s}, q{CREATE TYPE s.e AS ENUM ('a', 'b')}, q{CREATE TABLE public.t (v s.e)} ],
      qr/USING v::text::s\.e/ ],
    [ 'renamed',
      [ q{CREATE TYPE public.e AS ENUM ('a', 'b')}, q{CREATE TABLE public.t (v public.e)} ],
      [ q{CREATE TYPE public.e2 AS ENUM ('a', 'b')}, q{CREATE TABLE public.t (v public.e2)} ],
      qr/USING v::text::public\.e2/ ],
    [ 'a composite moved to another schema',
      [ q{CREATE TYPE public.c AS (a integer)}, q{CREATE TABLE public.t (v public.c)} ],
      [ q{CREATE SCHEMA s}, q{CREATE TYPE s.c AS (a integer)}, q{CREATE TABLE public.t (v s.c)} ],
      qr/USING v::text::s\.c/ ],
  ) {
    my ($label, $from, $to, $using) = @$case;
    start_over($from, $to);
    my @sql = map { $_->as_sql } @{ ops() };
    like join("\n", @sql), $using, "an enum/composite $label with a column on it: the column goes over with USING";
    like $sql[-1], qr/\ADROP TYPE public\.\w+;\z/, '... the old type is dropped last';
    ok eval { $dbh_a->begin_work; $dbh_a->do($_) for @sql; $dbh_a->commit; 1 }, '... the server takes the statements' or do { diag $@; $dbh_a->rollback };
    is scalar @{ ops() }, 0, '... and afterwards the diff is empty';
  }
  };
}

# LIVE test for karr k121: an enum without values or a composite type without
# attributes was never in the model (the join on pg_enum / pg_attribute gave
# no row). A target that declares such a type empty, where the database has
# it with values or attributes, was read as "the target does not declare the
# type": DROP TYPE ... CASCADE, and every column of the type went with it.
#
# The claim: such a diff is refused by name, and the type and the rows are
# as they were. A type the target does not declare at all stays a plain drop.
{
  package Fold139::EmptyType;
  use Test::More;
  use Test::Exception;

  my ($dbh_a, $dbh_b);

  sub catalog {
    my ($dbh) = @_;
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
    delete $_->{oid} for values %{ $model->{tables} }, values %{ $model->{schemas} };
    return $model;
  }

  sub start_over {
    my ($sql_a, $sql_b) = @_;
    for my $dbh ($dbh_a, $dbh_b) {
      $dbh->do($_) for 'DROP SCHEMA public CASCADE', 'CREATE SCHEMA public';
    }
    $dbh_a->do($_) for @$sql_a;
    $dbh_b->do($_) for @$sql_b;
  }

  sub ops {
    return DBIO::PostgreSQL::Diff->new(
      source => catalog($dbh_a), target => catalog($dbh_b))->operations;
  }

  subtest 'diff-empty-type' => sub {
  ($dbh_a, $dbh_b) = map {
    my $h = LiveServer->control_dbh(
      login => [ PrivatePgDatabase->create($_) ], attrs => { PrintWarn => 0 });
    $h->do('SET client_min_messages = warning');
    $h;
  } qw( t173a t173b );

  my @cases = (
    [ enum => q{CREATE TYPE public.t AS ENUM ('a', 'b')}, q{CREATE TYPE public.t AS ENUM ()},
      q{INSERT INTO public.u VALUES (1, 'a'), (2, 'b')}, 'values' ],
    [ composite => q{CREATE TYPE public.t AS (x integer, y text)}, q{CREATE TYPE public.t AS ()},
      q{INSERT INTO public.u VALUES (1, ROW(1, 'a')), (2, ROW(2, 'b'))}, 'attributes' ],
  );

  for my $case (@cases) {
    my ($kind, $full, $empty, $insert, $what) = @$case;
    start_over(
      [ $full, q{CREATE TABLE public.u (id integer PRIMARY KEY, c public.t)}, $insert ],
      [ $empty, q{CREATE TABLE public.u (id integer PRIMARY KEY)} ],
    );
    ok exists catalog($dbh_b)->{types}{'public.t'}, "$kind: the empty type is in the target model";
    my @ops = eval { @{ ops() } };
    my $err = $@;
    like $err, qr/\Arefusing to diff: $kind type public\.t is declared empty in the target but has $what in the database\n/,
      "$kind: declared empty in the target, with $what in the database, is refused";
    like $err, qr/No statement was generated\./, '... and no statement was written';
    is scalar @ops, 0, '... and no operation built';
    is $dbh_a->selectrow_array(q{SELECT count(*) FROM public.u}), 2, '... the rows are still there';
    is $dbh_a->selectrow_array(q{SELECT count(*) FROM pg_attribute WHERE attrelid = 'public.u'::regclass AND attname = 'c' AND NOT attisdropped}),
      1, '... and so is the column of the type';
  }

  # A type the target does not declare at all is a plain drop, as before.
  start_over(
    [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
    [],
  );
  my @sql = eval { map { $_->as_sql } @{ ops() } };
  is_deeply \@sql, [ q{DROP TYPE public.t;} ],
    'a type the target does not declare: DROP TYPE, not refused' or diag $@;

  # Empty on both sides: no operation. Empty in the database, values in the
  # target: the values are added.
  start_over(
    [ q{CREATE TYPE public.t AS ENUM ()} ],
    [ q{CREATE TYPE public.t AS ENUM ()} ],
  );
  is scalar @{ ops() }, 0, 'empty on both sides is no operation';

  start_over(
    [ q{CREATE TYPE public.t AS ENUM ()} ],
    [ q{CREATE TYPE public.t AS ENUM ('a', 'b')} ],
  );
  @sql = map { $_->as_sql } @{ ops() };
  ok eval { $dbh_a->do($_) for map { split /\n/ } @sql; 1 },
    'an empty enum in the database gets the target values: the server takes it' or diag $@;
  is scalar @{ ops() }, 0, '... and afterwards the diff is empty';
  };
}

done_testing;
