use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Introspect::Indexes;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121 (U2, points 1, 16, 17): what the index entries of
# the model say about the index, read from the catalog and not out of the
# text of pg_get_indexdef.
#
#  point 1:  an index that stands behind a PRIMARY KEY, UNIQUE or EXCLUDE
#            constraint says so (constraint_name, constraint_type p/u/x), and
#            says which foreign keys of other tables point at it
#            (referenced_by). Without that the diff cannot tell DROP INDEX,
#            which the server refuses for such an index, from the statement
#            that works.
#  point 16: `columns` holds the key positions and only them, one entry each,
#            undef for an expression, in ONE form whether the handle expands
#            arrays (pg_expand_array, DBD::Pg's default) or not; the INCLUDE
#            columns are in `include_columns` and nowhere else.
#  point 17: the sort of each key column (indoption) and its operator class
#            (indclass), the class with its schema where the session's
#            search_path does not find it.

my ($pdsn, $puser, $ppass) = PrivatePgDatabase->create('t111');
my $dbh = LiveServer->dbh_or_die(login => [ $pdsn, $puser, $ppass ], attrs => { PrintWarn => 0 });
$dbh->do('SET client_min_messages = warning');

$dbh->do($_) for (
  q{CREATE SCHEMA "Ex Schema"},
  q{CREATE OPERATOR CLASS "Ex Schema".my_int_ops FOR TYPE int4 USING btree AS
      OPERATOR 1 <, OPERATOR 2 <=, OPERATOR 3 =, OPERATOR 4 >=, OPERATOR 5 >,
      FUNCTION 1 btint4cmp(int4, int4)},
  q{CREATE TABLE t (
      id bigint PRIMARY KEY,
      a  bigint, b bigint, c text, d integer,
      "x,y" bigint,
      CONSTRAINT t_a_key  UNIQUE (a),
      CONSTRAINT t_b_excl EXCLUDE USING btree (b WITH =)
    )},
  q{CREATE TABLE u (id bigint PRIMARY KEY, t_a bigint CONSTRAINT u_t_a_fkey REFERENCES t (a))},
  q{CREATE UNIQUE INDEX t_c_uidx   ON t (c)},
  q{CREATE INDEX t_plain           ON t (a)},
  q{CREATE INDEX t_inc             ON t (a) INCLUDE (b, c)},
  q{CREATE INDEX t_inc_comma       ON t (a) INCLUDE ("x,y")},
  q{CREATE INDEX t_expr            ON t (lower(c))},
  q{CREATE INDEX t_mixed           ON t (a, lower(c), b)},
  q{CREATE INDEX t_sort            ON t (a DESC, b NULLS FIRST, c DESC NULLS LAST, id)},
  q{CREATE INDEX t_class           ON t (c text_pattern_ops DESC)},
  q{CREATE INDEX t_quoted_class    ON t (d "Ex Schema".my_int_ops DESC)},
  q{ALTER TABLE t ADD COLUMN tv tsvector},
  q{CREATE INDEX t_params          ON t USING gist (tv tsvector_ops (siglen = 32))},
  q{CREATE INDEX t_gin             ON t USING gin (tv)},
);

sub model {
  my ($expand) = @_;
  local $dbh->{pg_expand_array} = $expand;
  return DBIO::PostgreSQL::Introspect::Indexes->fetch($dbh, ['public']);
}

my $m = model(1)->{'public.t'};
ok($m, 'the model has the indexes of public.t') or BAIL_OUT('no model');

# --- point 16 -------------------------------------------------------------
is_deeply(model(0), model(1),
  'point 16: the whole model is the same whether the handle expands arrays or not');

is_deeply($m->{t_inc}{columns}, ['a'], 'point 16: INCLUDE columns are not key columns');
is_deeply($m->{t_inc}{include_columns}, [ 'b', 'c' ], '... they are the include columns');
is_deeply($m->{t_inc_comma}{include_columns}, ['x,y'],
  '... an include column with a comma in its name is one column');
is_deeply($m->{t_expr}{columns}, [undef], 'point 16: an index on an expression alone has [undef]');
is_deeply($m->{t_mixed}{columns}, [ 'a', undef, 'b' ],
  '... a column, an expression and a column: one entry per position');
is_deeply($m->{t_plain}{include_columns}, [], '... no include columns is []');

# --- point 1 --------------------------------------------------------------
sub constraint_of {
  my ($i) = @_;
  return [ $m->{$i}{constraint_type}, $m->{$i}{constraint_name} ];
}
is_deeply(constraint_of('t_pkey'),  [ 'p', 't_pkey' ],  'point 1: the primary key index says primary');
is_deeply(constraint_of('t_a_key'), [ 'u', 't_a_key' ], '... the index behind UNIQUE says unique');
is_deeply(constraint_of('t_b_excl'), [ 'x', 't_b_excl' ], '... the index behind EXCLUDE says exclusion');
is_deeply(constraint_of('t_c_uidx'), [ undef, undef ],
  '... a unique index without a constraint says nothing');
is($m->{t_c_uidx}{is_unique}, 1, '... and is unique');
is_deeply(constraint_of('t_plain'), [ undef, undef ], '... a plain index says nothing');

is_deeply($m->{t_a_key}{referenced_by},
  [ { schema_name => 'public', table_name => 'u', constraint_name => 'u_t_a_fkey' } ],
  '... the unique constraint a foreign key of u points at says so');
is_deeply($m->{t_pkey}{referenced_by}, [], '... one nothing points at has []');
is_deeply($m->{t_plain}{referenced_by}, [], '... so does an index without a constraint');
is_deeply(model(1)->{'public.u'}{u_pkey}{referenced_by}, [],
  '... and the index of u, which holds the foreign key, is not referenced by it');

# --- point 17 -------------------------------------------------------------
is_deeply($m->{t_sort}{sort_options},
  { a => 'DESC', b => 'NULLS FIRST', c => 'DESC NULLS LAST' },
  'point 17: the sort of a key column that is not the default is in the model');
is_deeply($m->{t_plain}{sort_options}, {}, '... an ascending column has none');
is_deeply($m->{t_class}{sort_options}, { c => 'DESC' }, '... beside an operator class');
is_deeply($m->{t_class}{opclasses}, { c => 'text_pattern_ops' },
  '... which is kept');
is_deeply($m->{t_quoted_class}{opclasses}, { d => '"Ex Schema".my_int_ops' },
  'point 17: an operator class in a quoted schema is kept, with its schema');
is_deeply($m->{t_quoted_class}{sort_options}, { d => 'DESC' }, '... and so is the sort');
is_deeply($m->{t_plain}{opclasses}, {}, '... an index on the default class has no opclasses');

# What the catalog gives is what pg_get_indexdef prints, class parameters
# included, for every index of the table (the quoted schema's is the one the
# printed text was never read right for).
is_deeply($m->{t_params}{opclasses}, { tv => "tsvector_ops(siglen='32')" },
  'point 17: the parameters of an operator class stay with its name');
use DBIO::PostgreSQL::Introspect::Parse;
for my $name (sort grep { $_ ne 't_quoted_class' } keys %$m) {
  is_deeply($m->{$name}{opclasses},
    DBIO::PostgreSQL::Introspect::Parse->column_opclasses($m->{$name}{definition}),
    "... $name: the catalog and the printed definition agree");
}

# The class is named with its schema only where the session's path does not
# find it.
$dbh->do('SET search_path TO "Ex Schema", public');
my $found = DBIO::PostgreSQL::Introspect::Indexes->fetch($dbh, ['public'])->{'public.t'};
is_deeply($found->{t_quoted_class}{opclasses}, { d => 'my_int_ops' },
  '... and bare where the search_path finds it');
$dbh->do('RESET search_path');

$dbh->disconnect;
done_testing;
