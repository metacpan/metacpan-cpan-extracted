use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::DB2::DDL;
use DBIO::DB2::Diff;
use DBIO::DB2::Diff::View;

# OFFLINE (karr k54, ADR 0011 addendum). Views in the order of what they read,
# as dbio-mysql does since its k110/k113: a view after the views it reads on
# create, before them on drop; a reader of a replaced view is replaced with it;
# a cycle is refused before any operation. Models are the shape
# DBIO::DB2::Introspect makes: SYSCAT.VIEWS.TEXT after the view's name, so an
# unquoted name in it is the upper-case one the catalog holds. The live
# counterpart is t/75.

sub view { my ($name, $def) = @_; return { table_name => $name, kind => 'view', view_definition => $def } }
sub tbl  { return { table_name => $_[0], kind => 'table' } }
sub model {
  my (%tables) = @_;
  return {
    tables  => { %tables },
    columns => { map { $_ => [ { column_name => 'id', catalog_type => 'INTEGER', catalog_size => 4, not_null => 1 } ] } keys %tables },
    indexes => {}, foreign_keys => {}, unique_constraints => {},
  };
}
sub sql_of { my ($m1, $m2) = @_; return [ map { $_->as_sql } @{ DBIO::DB2::Diff->new(source => $m1, target => $m2)->operations } ] }
sub reads { return [ DBIO::DB2::DDL::view_reads($_[0]) ] }

# --- view_reads ---------------------------------------------------------------
is_deeply reads('AS SELECT "id" FROM "t"'), ['t'], 'a quoted name is read as written';
is_deeply reads('AS SELECT id FROM t'), ['T'], 'an unquoted name is the upper-case one the catalog holds';
is_deeply reads('AS SELECT * FROM "s"."a" JOIN b ON 1=1 LEFT OUTER JOIN "c" ON 1=1'),
  [qw(a B c)], 'a schema qualifier is dropped; JOIN names are read, in order';
is_deeply reads('AS SELECT * FROM "a", "b" x, (SELECT 1 FROM "c") AS y'),
  [qw(a b c)], 'comma list, alias, derived table';
is_deeply reads(q{AS SELECT 'from "x"' AS a /* from "y" */ FROM "z" -- from "w"}),
  ['z'], 'strings and comments read nothing';
is_deeply reads('AS SELECT TRIM(BOTH FROM "v") FROM "t" WHERE a IS DISTINCT FROM b'),
  ['t'], 'FROM inside TRIM and IS DISTINCT FROM open no table list';
is_deeply reads('AS SELECT * FROM TABLE(f(1)) AS x, "t"'), ['t'], 'a call is no table';
is_deeply reads('AS SELECT "from" FROM "t"'), ['t'], 'a quoted identifier named from is no keyword';
is_deeply reads(undef), [], 'no definition reads nothing';

# --- order_views --------------------------------------------------------------
is_deeply [ DBIO::DB2::DDL::order_views({
    a => 'AS SELECT * FROM "b"', b => 'AS SELECT * FROM "c"', c => 'AS SELECT 1 FROM "t"', d => undef,
  }) ], [qw(c b a d)], 'a view after the views it reads, otherwise by name';
is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM B', b => 'AS SELECT 1 FROM "t"' }) ],
  [qw(b a)], 'an unquoted read matches the one view of that name without regard to case';
is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "a"' }) ], ['a'], 'a read of itself is no dependency';
throws_ok { DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "b"', b => 'AS SELECT * FROM "a"', c => 'AS SELECT 1 FROM "t"' }) }
  qr/"a".*"b".*cycle|cycle.*"a".*"b"/s, 'a cycle throws, naming the views';
throws_ok { DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "b"', b => 'AS SELECT * FROM "a"', c => 'AS SELECT 1 FROM "t"' }) }
  'DBIO::Exception', '... a DBIO::Exception';

# --- the diff: create in order, drop in reverse ------------------------------------
{
  my $t = tbl('t');
  my $sql = sql_of(model(t => $t), model(t => $t,
    a => view('a', 'AS SELECT * FROM "b"'),
    b => view('b', 'AS SELECT * FROM "c"'),
    c => view('c', 'AS SELECT * FROM "t"')));
  is_deeply [ grep { /VIEW/ } @$sql ], [
    'CREATE VIEW "c" AS SELECT * FROM "t";',
    'CREATE VIEW "b" AS SELECT * FROM "c";',
    'CREATE VIEW "a" AS SELECT * FROM "b";',
  ], 'creates: a view after the views it reads (not name order)' or diag join "\n", @$sql;

  $sql = sql_of(model(t => $t,
    a => view('a', 'AS SELECT * FROM "b"'),
    b => view('b', 'AS SELECT * FROM "c"'),
    c => view('c', 'AS SELECT * FROM "t"')), model(t => $t));
  is_deeply [ grep { /VIEW/ } @$sql ], [ 'DROP VIEW "a";', 'DROP VIEW "b";', 'DROP VIEW "c";' ],
    'drops: a view before the views it reads' or diag join "\n", @$sql;
}

# --- a reader of a replaced view is replaced with it (transitively) --------------
{
  my $t = tbl('t');
  my $src = model(t => $t,
    base  => view('base',  'AS SELECT "id" FROM "t"'),
    mid   => view('mid',   'AS SELECT "id" FROM "base"'),
    top   => view('top',   'AS SELECT "id" FROM "mid"'),
    other => view('other', 'AS SELECT "id" FROM "t"'));
  my $tgt = model(t => $t,
    base  => view('base',  'AS SELECT "id", 1 AS "x" FROM "t"'),
    mid   => view('mid',   'AS SELECT "id" FROM "base"'),
    top   => view('top',   'AS SELECT "id" FROM "mid"'),
    other => view('other', 'AS SELECT "id" FROM "t"'));
  my @ops = DBIO::DB2::Diff::View->diff($src->{tables}, $tgt->{tables});
  is_deeply [ map { $_->action . ' ' . $_->view_name } @ops ],
    [ 'drop top', 'drop mid', 'drop base', 'create base', 'create mid', 'create top' ],
    'readers of a replaced view, direct and through another view: dropped before, created after';
  is_deeply [ map { $_->replaced ? 1 : 0 } grep { $_->action eq 'drop' } @ops ], [1, 1, 1],
    '... every drop is marked replaced';
  my $d = DBIO::DB2::Diff->new(source => $src, target => $tgt);
  ok $d->has_changes, 'the diff has changes';
  is scalar(grep { /other/ } map { $_->as_sql } @{ $d->operations }), 0, 'a view that reads only what stays is not touched';
  my $sql = sql_of($src, $tgt);
  is $sql->[0], 'DROP VIEW "top";', 'the drops stand at the head';
  is $sql->[-1], 'CREATE VIEW "top" AS SELECT "id" FROM "mid";', '... the creates at the end';
}

# --- a reader of an unchanged view is left alone ------------------------------
{
  my $t = tbl('t');
  my @ops = DBIO::DB2::Diff::View->diff(
    { t => $t, base => view('base', 'AS SELECT 1 FROM "t"'), r => view('r', 'AS SELECT * FROM "base"') },
    { t => $t, base => view('base', 'AS SELECT 1 FROM "t"'), r => view('r', 'AS SELECT * FROM "base"') });
  is scalar(@ops), 0, 'nothing changed, nothing to do';
}

# --- cycles are refused before any operation ----------------------------------------
{
  my $t = tbl('t');
  my $d = DBIO::DB2::Diff->new(source => model(t => $t), target => model(t => $t,
    a => view('a', 'AS SELECT * FROM "b"'), b => view('b', 'AS SELECT * FROM "a"')));
  throws_ok { $d->operations } qr/"a".*"b".*cycle|cycle.*"a".*"b"/s, 'a cycle in the target: the diff throws, naming the views';
  throws_ok {
    DBIO::DB2::Diff::View->diff(model(t => $t)->{tables}, model(t => $t,
      a => view('a', 'AS SELECT * FROM "b"'), b => view('b', 'AS SELECT * FROM "a"'))->{tables});
  } 'DBIO::Exception', '... from Diff::View, before an operation is returned';
}

# --- install_ddl ------------------------------------------------------------------
{
  package T74::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  package T74::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  for my $v (['A', 'a', 'SELECT id FROM "b"'], ['B', 'b', 'SELECT id FROM "c"'], ['C', 'c', 'SELECT id FROM "t"']) {
    no strict 'refs';
    my ($cls, $n, $def) = @$v;
    @{"T74::Result::V$cls\::ISA"} = ('DBIO::Core');
    "T74::Result::V$cls"->table_class('DBIO::ResultSource::View');
    "T74::Result::V$cls"->table($n);
    "T74::Result::V$cls"->result_source_instance->view_definition($def);
    "T74::Result::V$cls"->add_columns(id => { data_type => 'integer' });
  }
  T74::Schema->register_class($_ => "T74::Result::$_") for qw(T VA VB VC);
}
{
  my $ddl = DBIO::DB2::DDL->install_ddl('T74::Schema'->connect('dbi:DB2:'));
  my @v = $ddl =~ /^CREATE VIEW "(\w+)"/mg;
  is_deeply \@v, [qw(c b a)], 'install_ddl creates the views in the order of what they read' or diag $ddl;
}

# --- common table expressions (karr k55) -----------------------------------------------
# A name a WITH clause defines is no view, even if a view of that name exists; the
# reads inside the bodies still count.
is_deeply reads('AS WITH a AS (SELECT 1 AS x FROM "t") SELECT x FROM a'), ['t'],
  'a CTE read is no dependency; the read inside its body is';
is_deeply reads('AS WITH a AS (SELECT 1 FROM "t"), b (x, y) AS (SELECT 1, 2 FROM a) SELECT * FROM a, b JOIN "c" ON 1=1'),
  [qw(t c)], 'several CTEs, one with a column list, one reading the other; the main select reads a, b and "c"';
is_deeply reads('AS WITH A AS (SELECT 1 FROM "t") SELECT * FROM a'), ['t'],
  'an unquoted CTE name and an unquoted read are the same name';
is_deeply reads('AS WITH "a" AS (SELECT 1 FROM "t") SELECT * FROM A'), ['t', 'A'],
  '... a quoted lower-case CTE is not the upper-case read';
is_deeply reads('AS WITH n (i) AS (SELECT 1 FROM sysibm.sysdummy1 UNION ALL SELECT i + 1 FROM n WHERE i < 5) SELECT i FROM n'),
  ['SYSDUMMY1'], 'a recursive CTE reads itself as the CTE, not as a view';
is_deeply reads('AS WITH a AS (SELECT 1 FROM b), b AS (SELECT 1 FROM "t") SELECT * FROM a, b'), ['B', 't'],
  'a body reads a name defined after it as a table or view (B), after its own definition as the CTE';
is_deeply reads('AS SELECT * FROM (WITH q AS (SELECT 1 FROM "t") SELECT * FROM q) AS d, q'), [qw(t Q)],
  'a CTE is visible in its own select only: the q outside the parentheses is a table';
is_deeply reads('AS SELECT * FROM "a" WITH UR'), ['a'], 'WITH UR is no CTE';
is_deeply reads('AS SELECT * FROM "a" WITH CASCADED CHECK OPTION'), ['a'], 'WITH CHECK OPTION is no CTE';
is_deeply reads('AS WITH a AS (SELECT 1 FROM "t") SELECT * FROM s.a'), ['t', 'A'],
  'a qualified read is never a CTE';
throws_ok { reads('AS WITH a (x) SELECT 1 FROM "t"') } 'DBIO::Exception', 'a WITH that is no readable CTE throws';
throws_ok { reads('AS WITH a (x) AS "t" SELECT 1') } qr/"A".*not a readable common table expression/,
  '... naming the CTE';
throws_ok { reads('AS WITH a AS (SELECT 1 FROM "t"), SELECT 1') } 'DBIO::Exception',
  '... also after a comma that brings no next CTE';

is_deeply [ DBIO::DB2::DDL::order_views({
    a => 'AS WITH b AS (SELECT 1 FROM "t") SELECT * FROM b', b => 'AS SELECT 1 FROM "t"',
  }) ], [qw(a b)], 'a view a with a CTE b beside a view b: no dependency, name order (it was b, a)';
is_deeply [ DBIO::DB2::DDL::order_views({
    a => 'AS WITH x AS (SELECT 1 FROM "b") SELECT * FROM x', b => 'AS SELECT 1 FROM "t"', c => 'AS SELECT 1 FROM "t"',
  }) ], [qw(b a c)], '... the read inside the CTE body still orders (b before a)';

# --- a schema qualifier (karr k55) ----------------------------------------------------
{
  my %defs = (
    a => 'AS SELECT * FROM other.b', b => 'AS SELECT 1 FROM "t"',
  );
  is_deeply [ DBIO::DB2::DDL::view_reads('AS SELECT * FROM s.b JOIN APP.c ON 1=1', 'APP') ], ['C'],
    'view_reads with a schema: the read of another schema is dropped, the own one stays';
  is_deeply [ DBIO::DB2::DDL::view_reads('AS SELECT * FROM s.b JOIN c ON 1=1') ], [qw(B C)],
    '... without one the qualifier is dropped and every name is a candidate';

  is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM OTHER.B', B => 'AS SELECT 1 FROM "t"' }, 'APP') ],
    [qw(B a)], 'another schema: not a dependency of the set, name order (B sorts before a)';
  is_deeply [ DBIO::DB2::DDL::order_views({ b => 'AS SELECT * FROM OTHER.a', a => 'AS SELECT 1 FROM "t"' }, 'APP') ],
    [qw(a b)], '... even where it would have reordered';
  is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM APP.b', b => 'AS SELECT 1 FROM "t"' }, 'APP') ],
    [qw(b a)], 'the own schema: a dependency';
  is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "APP"."b"', b => 'AS SELECT 1 FROM "t"' }, 'APP') ],
    [qw(b a)], '... also quoted';
  is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "app"."b"', b => 'AS SELECT 1 FROM "t"' }, 'APP') ],
    [qw(a b)], '... a quoted lower-case app is another schema than APP';
  is_deeply [ DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM x.nosuch', b => 'AS SELECT 1 FROM "t"' }) ],
    [qw(a b)], 'without a schema: a qualified read of no view of the set is no dependency and no problem';

  throws_ok { DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM s."b"', b => 'AS SELECT 1 FROM "t"' }) }
    qr/view "a" reads "S"\."b".*"b" is a view of the same set.*schema/s,
    'without a schema: a qualified read of a view of the set is refused, naming view and read';
  throws_ok { DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM s."b"', b => 'AS SELECT 1 FROM "t"' }) }
    'DBIO::Exception', '... a DBIO::Exception';
  lives_ok { DBIO::DB2::DDL::order_views({ a => 'AS SELECT * FROM "a"."a"' }) }
    '... but the view reading itself through a qualifier is no ambiguity';
}

# --- install_ddl: the schema is an optional second argument (karr k55) -------------------
{
  package T74Q::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  for my $v (['X', 'x', 'SELECT id FROM "APP"."y"'], ['Y', 'y', 'SELECT 1 AS id FROM sysibm.sysdummy1']) {
    no strict 'refs';
    my ($cls, $n, $def) = @$v;
    @{"T74Q::Result::V$cls\::ISA"} = ('DBIO::Core');
    "T74Q::Result::V$cls"->table_class('DBIO::ResultSource::View');
    "T74Q::Result::V$cls"->table($n);
    "T74Q::Result::V$cls"->result_source_instance->view_definition($def);
    "T74Q::Result::V$cls"->add_columns(id => { data_type => 'integer' });
    T74Q::Schema->register_class("V$cls" => "T74Q::Result::V$cls");
  }
}
{
  my $schema = 'T74Q::Schema'->connect('dbi:DB2:');
  throws_ok { DBIO::DB2::DDL->install_ddl($schema) } qr/view "x" reads "APP"\."y"/,
    'install_ddl without the schema refuses a qualified read of a view of the set';
  my @v = DBIO::DB2::DDL->install_ddl($schema, 'APP') =~ /^CREATE VIEW "(\w+)"/mg;
  is_deeply \@v, [qw(y x)], '... and orders it when it is given the schema the views are created in';
  @v = DBIO::DB2::DDL->install_ddl($schema, 'OTHER') =~ /^CREATE VIEW "(\w+)"/mg;
  is_deeply \@v, [qw(x y)], '... a qualifier that is another schema is no dependency (name order)';
}

# --- the diff takes the schema from the live model ---------------------------------------
{
  my $t = tbl('t'); $t->{schema} = 'APP';
  sub in_app { my ($n, $def) = @_; my $v = view($n, $def); $v->{schema} = 'APP'; return $v }
  my $src = model(t => $t);
  my $tgt = model(t => $t,
    a => in_app('a', 'AS SELECT * FROM APP.b'), b => in_app('b', 'AS SELECT * FROM other.c'),
    c => in_app('c', 'AS SELECT 1 FROM "t"'));
  is_deeply [ grep { /VIEW/ } @{ sql_of($src, $tgt) } ], [
    'CREATE VIEW "b" AS SELECT * FROM other.c;',
    'CREATE VIEW "a" AS SELECT * FROM APP.b;',
    'CREATE VIEW "c" AS SELECT 1 FROM "t";',
  ], 'the live schema (APP) is the own one: APP.b orders a after b, other.c orders nothing (name order b, a, c)'
    or diag join "\n", @{ sql_of($src, $tgt) };

  # without a table in the live model the schema is unknown: undecidable is refused
  throws_ok { sql_of(model(), model(a => in_app('a', 'AS SELECT * FROM APP.b'), b => in_app('b', 'AS SELECT 1 FROM "t"'))) }
    qr/view "a" reads "APP"\."B"/, 'a live model with no entry names no schema: the qualified read is refused';

  # the fold of a reader of a replaced view follows the same rule
  my $s2 = model(t => $t, base => in_app('base', 'AS SELECT 1 FROM "t"'),
    r => in_app('r', 'AS SELECT * FROM APP.base'), o => in_app('o', 'AS SELECT * FROM other.base'));
  my $t2 = model(t => $t, base => in_app('base', 'AS SELECT 2 FROM "t"'),
    r => in_app('r', 'AS SELECT * FROM APP.base'), o => in_app('o', 'AS SELECT * FROM other.base'));
  is_deeply [ map { $_->action . ' ' . $_->view_name } DBIO::DB2::Diff::View->diff($s2->{tables}, $t2->{tables}, 'APP') ],
    [ 'drop r', 'drop base', 'create base', 'create r' ],
    'a reader through the own schema is replaced with the view, one through another schema is left alone';
}

# --- install_ddl finds the target schema itself (karr k55) -------------------------------
# A storage that says it is connected, over a recording handle answering CURRENT SCHEMA
# (CHAR(128): space-padded).
{
  package T74::Dbh;
  sub new { my ($c, $a) = @_; return bless { answer => $a, sql => [] }, $c }
  sub selectrow_array { my $s = shift; push @{ $s->{sql} }, $_[0]; return $s->{answer} }
  package T74::Storage;
  sub new { my ($c, $d) = @_; return bless { dbh => $d }, $c }
  sub connected { 1 }
  sub dbh { $_[0]{dbh} }
}
{
  sub views_of { my ($schema) = @_; return [ DBIO::DB2::DDL->install_ddl($schema) =~ /^CREATE VIEW "(\w+)"/mg ] }

  my $schema = 'T74Q::Schema'->connect('dbi:DB2:');
  my $dbh = T74::Dbh->new('APP' . (' ' x 125));
  $schema->storage(T74::Storage->new($dbh));
  is_deeply views_of($schema), [qw(y x)],
    'no explicit schema, the connection is in APP: the qualifier APP is the target schema, x waits for y';
  is_deeply $dbh->{sql}, ['VALUES CURRENT SCHEMA'], '... asked once, with the register Deploy reads';

  $schema->storage(T74::Storage->new(T74::Dbh->new('OTHER')));
  is_deeply views_of($schema), [qw(x y)],
    'the connection is in another schema: the qualifier APP is a foreign one, no dependency (name order)';

  for my $unknown ([ 'no answer from the handle', T74::Dbh->new(undef) ]) {
    $schema->storage(T74::Storage->new($unknown->[1]));
    throws_ok { DBIO::DB2::DDL->install_ddl($schema) } qr/view "x" reads "APP"\."y"/,
      "$unknown->[0]: the schema is unknown, the qualified read is refused";
  }

  $schema->storage(bless { }, 'T74::Dead');
  { package T74::Dead; sub dbh { die "no connection\n" } }
  throws_ok { DBIO::DB2::DDL->install_ddl($schema) } qr/view "x" reads "APP"\."y"/,
    'a storage that cannot connect: the schema is unknown, refused';

  throws_ok { DBIO::DB2::DDL->install_ddl('T74Q::Schema') } qr/view "x" reads "APP"\."y"/,
    'a class has no connection: refused';

  $schema->storage(T74::Storage->new(T74::Dbh->new('OTHER')));
  is_deeply [ DBIO::DB2::DDL->install_ddl($schema, 'APP') =~ /^CREATE VIEW "(\w+)"/mg ], [qw(y x)],
    'an explicit schema wins over the connection';
  is_deeply $schema->storage->dbh->{sql}, [], '... and the connection is not asked';
}

done_testing;
