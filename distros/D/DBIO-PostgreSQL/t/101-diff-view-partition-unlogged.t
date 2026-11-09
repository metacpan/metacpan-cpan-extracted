use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Function;
use DBIO::PostgreSQL::Diff::Table;

# karr k120 (4, 5, 6) -- the diff acts on what the model knows about a table.
#
# WHY it exists: the model holds which columns a view reads, which table a
# partition belongs to, which tables a table inherits from, and whether a
# table is unlogged. The diff read none of it, and wrote statements the
# server refuses, or none:
#
#   ALTER TABLE public.t ALTER COLUMN a TYPE bigint;   -- a view reads t.a:
#       cannot alter type of a column used by a view or rule
#   ALTER TABLE public.m ADD COLUMN x integer;         -- m is partitioned
#   ALTER TABLE public.m_2026 ADD COLUMN x integer;    -- its partition:
#       cannot add column to a partition
#   CREATE TABLE public.u (id integer);                -- u is UNLOGGED in the target
#   DROP FUNCTION public.p();                          -- p is a procedure
#
# What is held here, without a database (t/101-...-live.t holds each against
# a server, with "after apply the diff is empty" and "after a refusal nothing
# has changed"):
#
#  4. a column that changes its type while a view reads it: the views the
#     target has are dropped and created again around it (karr k120, decision
#     2026-10-12); a materialized view that reads it is refused (decision
#     2026-10-16), and so is a view only the database has, naming table,
#     column, both types, the view and the DROPs that are the way out -- and
#     only that column: one no view reads, and a change that is no
#     type change, go through;
#  5. a column a partition or an inheriting table has from its parent is
#     changed at the parent and nowhere else; what is the child's own -- its
#     default, its NOT NULL, a column of its own -- is changed at the child,
#     after the parent. A table that changes parents, and an inheriting table
#     to create, are refused;
#  6. an unlogged table is created UNLOGGED and a change is SET LOGGED / SET
#     UNLOGGED, where the server has that statement;
#  and a procedure is dropped with DROP PROCEDURE.

sub relation {
  my ($kind, $name, %more) = @_;
  return ("public.$name" => { schema_name => 'public', table_name => $name, kind => $kind, %more });
}
sub table { relation(r => @_) }
sub col {
  my ($name, $type, %more) = @_;
  return { column_name => $name, data_type => $type, not_null => 0, identity => '', generated => '', %more };
}
sub view {
  my ($name, $kind, $definition, %reads) = @_;
  return relation($kind => $name, view_definition => $definition,
    depends_on => [ sort keys %reads ], depends_on_columns => {%reads});
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}
sub statements { [ map { split /\n/, $_->as_sql } @{ diff_of(@_)->operations } ] }

sub refused_ok {
  my ($label, $source, $target, @like) = @_;
  my $ops = eval { diff_of($source, $target)->operations };
  my $error = $@;
  subtest $label => sub {
    is $ops, undef, 'no operation is built';
    like $error, qr/\Arefusing to diff: /, 'the diff is refused';
    like $error, $_, "the refusal matches $_" for @like;
    like $error, qr/No statement was generated\./, 'and says that nothing was generated';
  };
  return $error;
}

# --- 4. a column a view reads -----------------------------------------------

{
  my %views = (
    view(v_a    => v => ' SELECT id, a FROM public.t WHERE (d > 0);', 'public.t'   => [qw( a d id )]),
    view(v_on_v => v => ' SELECT a FROM public.v_a;',                  'public.v_a' => ['a']),
    view(mv_b   => m => ' SELECT b FROM public.t;',                    'public.t'   => ['b']),
  );
  my $cols = sub {
    my (%change) = @_;
    return { 'public.t' => [
      map { col($_->[0], $_->[1], %{ $change{ $_->[0] } // {} }) }
        [ id => 'integer' ], [ a => 'integer' ], [ b => 'integer' ], [ c => 'text' ], [ d => 'integer' ],
    ] };
  };
  my $model = sub { my ($views, %change) = @_; { tables => { table('t'), %$views }, columns => $cols->(%change) } };
  my $db = $model->(\%views);

  # Views the target has are dropped and created again around the change
  # (karr k120, maintainer's decision 2026-10-12): this was a refusal.
  is_deeply statements($db, $model->(\%views, a => { data_type => 'bigint' })), [
    'DROP VIEW public.v_on_v;',
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE (d > 0);',
    'CREATE VIEW public.v_on_v AS SELECT a FROM public.v_a;',
  ], 'the type of a column a view reads: the views go, the column changes, they come back';

  is_deeply statements($db, $model->(\%views, d => { data_type => 'bigint' })), [
    'DROP VIEW public.v_on_v;',
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN d TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE (d > 0);',
    'CREATE VIEW public.v_on_v AS SELECT a FROM public.v_a;',
  ], 'the type of a column a view reads in its WHERE only';

  # A materialized view is not built anew for it (decision 2026-10-16): that
  # takes its data and its indexes. Refused, naming it.
  refused_ok 'the type of a column a materialized view reads',
    $db, $model->(\%views, b => { data_type => 'bigint' }),
    qr/\Arefusing to diff: column public\.t\.b changes its type from integer to bigint and is read by materialized view public\.mv_b$/m,
    qr/^  DROP MATERIALIZED VIEW public\.mv_b;$/m;

  # The definition changes as well: one drop, one create, the target's text.
  my %changed = (%views, view(v_a => v => ' SELECT id, a FROM public.t WHERE (d > 1);', 'public.t' => [qw( a d id )]));
  is_deeply statements($db, $model->(\%changed, a => { data_type => 'bigint' })), [
    'DROP VIEW public.v_on_v;',
    'DROP VIEW public.v_a;',
    'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;',
    'CREATE VIEW public.v_a AS SELECT id, a FROM public.t WHERE (d > 1);',
    'CREATE VIEW public.v_on_v AS SELECT a FROM public.v_a;',
  ], 'the type of a column a view reads whose definition changes as well';

  # A view only the database has is not the declaration's to create again:
  # refused, by name (t/127 holds the rest of this).
  my %gone = %views; delete @gone{qw( public.v_a public.v_on_v )};
  my $error = refused_ok 'the type of a column a view reads that the target no longer has',
    $db, $model->(\%gone, a => { data_type => 'bigint' }),
    qr/\Arefusing to diff: column public\.t\.a changes its type from integer to bigint while view public\.v_a, view public\.v_on_v, which only the database has, depends on it$/m,
    qr/cannot alter type of a column used by a view or rule/,
    qr/^  DROP VIEW public\.v_on_v;\n  DROP VIEW public\.v_a;$/m,
    qr/diff again/;
  unlike $error, qr/mv_b/, '... naming the views that stand on this column, not every view on the table';

  # What the server takes, the diff writes.
  is_deeply statements($db, $model->(\%views, c => { data_type => 'character varying(10)' })),
    [ 'ALTER TABLE public.t ALTER COLUMN c TYPE character varying(10);' ],
    'the type of a column no view reads is altered';
  is_deeply statements($db, $model->(\%views, a => { not_null => 1, default_value => '1' })),
    [ 'ALTER TABLE public.t ALTER COLUMN a SET NOT NULL;', 'ALTER TABLE public.t ALTER COLUMN a SET DEFAULT 1;' ],
    'NOT NULL and the default of a column a view reads are altered';

  my $bare = $model->({});
  is_deeply statements($bare, $model->({ view(v_a => v => ' SELECT a FROM public.t;', 'public.t' => ['a']) },
      a => { data_type => 'bigint' })),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;', 'CREATE VIEW public.v_a AS SELECT a FROM public.t;' ],
    'a view the database does not have yet is no obstacle: it is created behind the columns';

  # The whole row: PostgreSQL records the relation and no column, and alters.
  my %row = (view(v_row => v => ' SELECT t.*::public.t AS t FROM public.t;', 'public.t' => []));
  is_deeply statements($model->(\%row), $model->(\%row, a => { data_type => 'bigint' })),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
    'a view that reads the table as a whole row is no obstacle';

  # A model built by hand that says what a view stands on, not which columns
  # it reads, says nothing here.
  my %unknown = (relation(v => 'v_a', view_definition => ' SELECT a FROM public.t;', depends_on => ['public.t']));
  is_deeply statements($model->(\%unknown), $model->(\%unknown, a => { data_type => 'bigint' })),
    [ 'ALTER TABLE public.t ALTER COLUMN a TYPE bigint;' ],
    'a view the model has no columns for is no ground for a refusal';
}

# --- 5. partitions ----------------------------------------------------------

{
  my %tables = (
    relation(p => 'm'),
    table(m_1    => partition_of => 'public.m'),
    table(a_part => partition_of => 'public.m'),    # sorts ahead of the table it belongs to
    relation(p => 'm_2', partition_of => 'public.m'),
    table(m_2_1  => partition_of => 'public.m_2'),
  );
  my @base = ([ id => 'integer', not_null => 1 ], [ v => 'text' ]);

  # A model with those tables: every table has @base and @all; %own gives a
  # table columns of its own definition instead.
  my $model = sub {
    my ($all, %own) = @_;
    return { tables => {%tables}, columns => { map {
      my $key = $_;
      ( $key => [ map { col(@$_) } @{ $own{$key} // [ @base, @$all ] } ] )
    } keys %tables } };
  };
  my $db = $model->([]);

  is_deeply statements($db, $model->([ [ x => 'integer', not_null => 1, default_value => '5' ] ])),
    [ 'ALTER TABLE public.m ADD COLUMN x integer NOT NULL DEFAULT 5;' ],
    'a column added to a partitioned table is added there, and to none of its partitions';

  is_deeply statements($model->([ [ x => 'integer' ] ]), $db),
    [ 'ALTER TABLE public.m DROP COLUMN x;' ],
    'a column dropped from a partitioned table is dropped there';

  is_deeply statements($model->([ [ x => 'integer' ] ]), $model->([ [ x => 'bigint' ] ])),
    [ 'ALTER TABLE public.m ALTER COLUMN x TYPE bigint;' ],
    'the type of a column of a partitioned table is altered there';

  is_deeply statements($model->([ [ x => 'integer' ] ]), $model->([ [ x => 'integer', not_null => 1, default_value => '9' ] ])),
    [ 'ALTER TABLE public.m ALTER COLUMN x SET NOT NULL;', 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9;' ],
    'NOT NULL and a default set on a partitioned table are set there';

  is_deeply statements($model->([ [ x => 'bigint', not_null => 1 ] ]), $model->([ [ x => 'bigint', not_null => 1, identity => 'a' ] ])),
    [ 'ALTER TABLE public.m ALTER COLUMN x ADD GENERATED ALWAYS AS IDENTITY;' ],
    'an identity the partitions have with the partitioned table is added there';

  # What is a partition's own.
  my $x = [ x => 'integer' ];
  my $own_default = sub { my ($default) = @_; ('public.m_1' => [ @base, [ x => 'integer', default_value => $default ] ]) };

  is_deeply statements($model->([$x]), $model->([$x], $own_default->('7'))),
    [ 'ALTER TABLE public.m_1 ALTER COLUMN x SET DEFAULT 7;' ],
    'a default of a partition alone is set on the partition';

  is_deeply statements($db, $model->([$x], $own_default->('7'))),
    [ 'ALTER TABLE public.m ADD COLUMN x integer;', 'ALTER TABLE public.m_1 ALTER COLUMN x SET DEFAULT 7;' ],
    'a new column with a default of the partition alone: added above, the default set below, in that order';

  # SET DEFAULT on the partitioned table overwrites the default of every
  # partition, so the partition's own is set again behind it.
  is_deeply statements($model->([$x], $own_default->('7')),
      $model->([ [ x => 'integer', default_value => '9' ] ], $own_default->('7'))),
    [ 'ALTER TABLE public.m ALTER COLUMN x SET DEFAULT 9;', 'ALTER TABLE public.m_1 ALTER COLUMN x SET DEFAULT 7;' ],
    'a default changed above, with a partition that keeps its own: set above, and put back below';

  is_deeply statements($model->([$x]), $model->([$x], 'public.m_1' => [ @base, [ x => 'integer', not_null => 1 ] ])),
    [ 'ALTER TABLE public.m_1 ALTER COLUMN x SET NOT NULL;' ],
    'NOT NULL of a partition alone is set on the partition';

  # DROP NOT NULL above leaves a NOT NULL a partition has of its own, and the
  # model does not say whose it is: the partition is asked as well, behind.
  is_deeply statements($model->([ [ x => 'integer', not_null => 1 ] ],
      'public.a_part' => [ @base, [ x => 'integer', not_null => 1 ] ], 'public.m_2' => [ @base, [ x => 'integer', not_null => 1 ] ],
      'public.m_2_1' => [ @base, [ x => 'integer', not_null => 1 ] ]),
    $model->([$x], 'public.a_part' => [ @base, $x ], 'public.m_2' => [ @base, $x ], 'public.m_2_1' => [ @base, $x ])),
    [ map { "ALTER TABLE public.$_ ALTER COLUMN x DROP NOT NULL;" } qw( m a_part m_1 m_2 m_2_1 ) ],
    'NOT NULL dropped from a partitioned table is dropped there first, then from each partition';

  # What no database has: a partition that differs from its table.
  refused_ok 'a column for a partition alone',
    $db, $model->([], 'public.m_1' => [ @base, [ own => 'integer' ] ]),
    qr/\Arefusing to diff: column public\.m_1\.own is to be added to public\.m_1, a partition of public\.m, and not to public\.m$/m,
    qr/cannot add column to a partition/;
  refused_ok 'a column dropped from a partition alone',
    $model->([$x]), $model->([$x], 'public.m_1' => [@base]),
    qr/\Arefusing to diff: column public\.m_1\.x is to be dropped from public\.m_1 and not from public\.m, which it has the column from$/m;
  refused_ok 'the type of a column of a partition alone',
    $model->([$x]), $model->([$x], 'public.m_1' => [ @base, [ x => 'bigint' ] ]),
    qr/\Arefusing to diff: column public\.m_1\.x is to change its type in public\.m_1 and not in public\.m, which it has the column from$/m;

  # A view on a partition holds the column of the partitioned table too.
  {
    my %read = (view(v_part => v => ' SELECT x FROM public.m_1;', 'public.m_1' => ['x']));
    my ($from, $to) = ($model->([$x]), $model->([ [ x => 'bigint' ] ]));
    $_->{tables} = { %{ $_->{tables} }, %read } for $from, $to;
    is_deeply statements($from, $to), [
      'DROP VIEW public.v_part;',
      'ALTER TABLE public.m ALTER COLUMN x TYPE bigint;',
      'CREATE VIEW public.v_part AS SELECT x FROM public.m_1;',
    ], 'the type of a column of a partitioned table that a view reads in a partition: the view is rebuilt';
  }

  # A table that changes what it belongs to.
  {
    my $detached = $model->([]);
    $detached->{tables}{'public.m_1'} = { table(m_1 => partition_of => undef) }->{'public.m_1'};
    refused_ok 'a partition that is none in the target',
      $db, $detached,
      qr/\Arefusing to diff: table public\.m_1 is a partition of public\.m in the database and a table of its own in the target$/m,
      qr/DETACH PARTITION/;
    refused_ok 'a table that is a partition in the target',
      $detached, $db,
      qr/\Arefusing to diff: table public\.m_1 is a table of its own in the database and a partition of public\.m in the target$/m;
  }
}

# --- 5. inheritance ---------------------------------------------------------

{
  my %tables = (table('p_inh'), table('p2'), table(c_inh => inherits => ['public.p_inh']),
    table(c2 => inherits => [ 'public.p_inh', 'public.p2' ]));
  my $a   = [ a => 'integer', is_local => 1 ];
  my $b   = [ b => 'text', is_local => 1 ];
  my $inh = sub { my ($col) = @_; [ @$col, is_local => 0 ] };
  my $own = [ c => 'integer', is_local => 1 ];

  my $model = sub {
    my (%cols) = @_;
    my %default = (
      'public.p_inh' => [ $a, $b ], 'public.p2' => [ $b ],
      'public.c_inh' => [ $inh->($a), $inh->($b), $own ],
      'public.c2'    => [ $inh->($a), $inh->($b), $own ],
    );
    return { tables => {%tables}, columns => { map {
      my $key = $_; ( $key => [ map { col(@$_) } @{ $cols{$key} // $default{$key} } ] )
    } keys %tables } };
  };
  my $db = $model->();
  my $n1 = [ n1 => 'integer' ];

  is_deeply statements($db, $model->(
      'public.p_inh' => [ $a, $b, $n1 ],
      'public.c_inh' => [ $inh->($a), $inh->($b), $own, $inh->($n1), [ own1 => 'integer', is_local => 1 ] ],
      'public.c2'    => [ $inh->($a), $inh->($b), $own, $inh->($n1) ])),
    [ 'ALTER TABLE public.p_inh ADD COLUMN n1 integer;', 'ALTER TABLE public.c_inh ADD COLUMN own1 integer;' ],
    'a column added to a table is added there and not to the tables that inherit it; a column of their own is added to them';

  is_deeply statements($db, $model->(
      'public.p_inh' => [ [ a => 'bigint', is_local => 1 ], $b ],
      'public.c_inh' => [ $inh->([ a => 'bigint' ]), $inh->($b), $own ],
      'public.c2'    => [ $inh->([ a => 'bigint' ]), $inh->($b), $own ])),
    [ 'ALTER TABLE public.p_inh ALTER COLUMN a TYPE bigint;' ],
    'the type of an inherited column is altered at the table it comes from';

  # An identity is not inherited: the child's column stays as it is.
  is_deeply statements($db, $model->('public.p_inh' => [ [ a => 'integer', is_local => 1, not_null => 1, identity => 'a' ], $b ],
      'public.c_inh' => [ $inh->([ a => 'integer', not_null => 1 ]), $inh->($b), $own ],
      'public.c2'    => [ $inh->([ a => 'integer', not_null => 1 ]), $inh->($b), $own ])),
    [ 'ALTER TABLE public.p_inh ALTER COLUMN a SET NOT NULL;', 'ALTER TABLE public.p_inh ALTER COLUMN a ADD GENERATED ALWAYS AS IDENTITY;' ],
    'an identity added to a table is added there, and nothing is asked of the tables that inherit the column';

  # DROP COLUMN goes down to a column that is only inherited. One the child
  # also defines itself stays behind, as its own, and has a drop of its own.
  is_deeply statements($db, $model->('public.p_inh' => [$a], 'public.p2' => [],
      'public.c_inh' => [ $inh->($a), $own ], 'public.c2' => [ $inh->($a), $own ])),
    [ 'ALTER TABLE public.p_inh DROP COLUMN b;', 'ALTER TABLE public.p2 DROP COLUMN b;' ],
    'a column dropped from every table it is inherited from goes with them';

  is_deeply statements($db, $model->('public.p2' => [])),
    [ 'ALTER TABLE public.p2 DROP COLUMN b;' ],
    'a column dropped from one of two tables it is inherited from stays: no statement for the child';

  {
    my $merged = $model->('public.c_inh' => [ $inh->($a), [ b => 'text', is_local => 1 ], $own ]);
    is_deeply statements($merged, $model->('public.p_inh' => [$a], 'public.p2' => [],
        'public.c_inh' => [ $inh->($a), $own ], 'public.c2' => [ $inh->($a), $own ])),
      [ 'ALTER TABLE public.p_inh DROP COLUMN b;', 'ALTER TABLE public.p2 DROP COLUMN b;', 'ALTER TABLE public.c_inh DROP COLUMN b;' ],
      'a column the child defines itself as well is dropped from the child too, behind';
  }

  # A table that inherits is not the diff's to create, and not to move.
  {
    my $without = $model->();
    delete $without->{tables}{'public.c_inh'};
    delete $without->{columns}{'public.c_inh'};
    my $error = refused_ok 'a table to create that inherits',
      $without, $db,
      qr/\Arefusing to diff: table public\.c_inh inherits from public\.p_inh in the target and is not in the database, and the diff cannot create it$/m,
      qr/CREATE TABLE public\.c_inh \(a integer, b text, c integer\)/;
    like $error, qr/INHERITS/, '... and says what the statement has to declare';

    my $loose = $model->();
    $loose->{tables}{'public.c_inh'} = { table('c_inh', inherits => []) }->{'public.c_inh'};
    refused_ok 'a table that no longer inherits',
      $db, $loose,
      qr/\Arefusing to diff: table public\.c_inh is a table that inherits from public\.p_inh in the database and a table of its own in the target$/m,
      qr/NO INHERIT/;
  }
}

# --- 6. UNLOGGED ------------------------------------------------------------

{
  my $model = sub {
    my ($persistence, %more) = @_;
    return {
      tables  => { table(u => (defined $persistence ? (persistence => $persistence) : ()), %more) },
      columns => { 'public.u' => [ col(id => 'integer') ] },
    };
  };
  my $none = { tables => {}, columns => {} };

  is_deeply statements($none, $model->('u')), [ 'CREATE UNLOGGED TABLE public.u (id integer);' ],
    'an unlogged table is created UNLOGGED';
  is_deeply statements($none, $model->('p')), [ 'CREATE TABLE public.u (id integer);' ],
    'a permanent table is created as before';

  my $diff = diff_of($model->('p'), $model->('u'));
  is_deeply [ map { $_->as_sql } @{ $diff->operations } ], [ 'ALTER TABLE public.u SET UNLOGGED;' ],
    'a table that is unlogged in the target is SET UNLOGGED';
  like $diff->summary, qr/~table: public\.u \(unlogged\)/, '... and the summary says so';
  is_deeply statements($model->('u'), $model->('p')), [ 'ALTER TABLE public.u SET LOGGED;' ],
    'a table that is logged in the target is SET LOGGED';
  is_deeply statements($model->('u'), $model->('u')), [], 'the same persistence is no change';
  is_deeply statements($model->('u'), $model->(undef)), [],
    'a target that does not say how the table is kept asks for nothing';

  refused_ok 'a partitioned table that is kept differently',
    $model->('u', kind => 'p'), $model->('p', kind => 'p'),
    qr/\Arefusing to diff: partitioned table public\.u is unlogged in the database and logged in the target$/m,
    qr/SET LOGGED/;
  refused_ok 'a temporary table to create',
    $none, $model->('t'),
    qr/\Arefusing to diff: table public\.u is temporary in the target$/m;

  throws_ok {
    DBIO::PostgreSQL::Diff::Table->new(action => 'set_persistence', schema_name => 'public', table_name => 'u',
      table_info => { persistence => 't' })->as_sql
  } qr/DBIO::PostgreSQL::Diff::Table: no statement for action 'set_persistence' on table public\.u/,
    'a hand-built change to a persistence the diff does not write dies in as_sql';
}

# --- procedures -------------------------------------------------------------

{
  my %routine = (schema_name => 'public', identity_args => 'n integer', definition => 'x');
  my @ops = DBIO::PostgreSQL::Diff::Function->diff({
    'public.p_proc(n integer)' => { %routine, function_name => 'p_proc', kind => 'p' },
    'public.f_fn(n integer)'   => { %routine, function_name => 'f_fn',   kind => 'f' },
    'public.f_old(n integer)'  => { %routine, function_name => 'f_old' },
  }, {});
  is_deeply [ map { $_->as_sql } @ops ],
    [ 'DROP FUNCTION public.f_fn(n integer);', 'DROP FUNCTION public.f_old(n integer);',
      'DROP PROCEDURE public.p_proc(n integer);' ],
    'a procedure is dropped with DROP PROCEDURE, a function -- and a routine the model does not name the kind of -- with DROP FUNCTION';
}

done_testing;
