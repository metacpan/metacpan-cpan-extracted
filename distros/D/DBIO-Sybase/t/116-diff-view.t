use strict;
use warnings;
use Test::More;

# WHY (karr k98): the ASE diff used to read a view like a table -- CREATE TABLE
# for a new one, DROP TABLE for a removed one (Msg 3705), ALTER TABLE ADD for a
# column of a changed one (Msg 4909). A view is created, dropped, or dropped
# and created again when its definition changed; changed and removed views go
# before the table changes, new and changed ones come after them, and views on
# views are ordered by what they depend on. No server: the models are fed in
# the shape DBIO::Sybase::Introspect produces.

use_ok 'DBIO::Sybase::Diff';
use_ok 'DBIO::Sybase::Diff::View';
use_ok 'DBIO::Sybase::Diff::Table';
use_ok 'DBIO::Sybase::Diff::Column';
use_ok 'DBIO::Sybase::Introspect::Views';

sub exception(&) { local $@; return eval { $_[0]->(); 1 } ? undef : $@ }

sub tbl  { +{ table_name => $_[0], kind => 'table' } }
sub vtbl { +{ table_name => $_[0], kind => 'view' } }
sub col  { +{ column_name => $_[0], data_type => $_[1] // 'int', not_null => ($_[0] eq 'id' ? 1 : 0) } }
sub view {
  my ($name, $def, @dep) = @_;
  +{ view_name => $name, definition => $def, depends_on => [ @dep ] };
}

# --- the view diff itself -----------------------------------------------
{
  my @ops = DBIO::Sybase::Diff::View->diff({}, { v => view('v', 'SELECT id FROM base') });
  is scalar(@ops), 1, 'a new view is one op';
  is $ops[0]->action, 'create', 'a create';
  is $ops[0]->as_sql, 'CREATE VIEW v AS SELECT id FROM base;',
    'CREATE VIEW, ended in ; (its own batch)';
  is $ops[0]->summary, 'CREATE VIEW v', 'summary';
}
{
  my @ops = DBIO::Sybase::Diff::View->diff({ v => view('v', 'SELECT id FROM base') }, {});
  is scalar(@ops), 1, 'a removed view is one op';
  is $ops[0]->action, 'drop', 'a drop';
  is $ops[0]->as_sql, 'DROP VIEW v;', 'DROP VIEW (not DROP TABLE)';
  is $ops[0]->summary, 'DROP VIEW v', 'summary';
}
{
  my @ops = DBIO::Sybase::Diff::View->diff(
    { v => view('v', 'SELECT id FROM base') },
    { v => view('v', 'SELECT id, name FROM base') });
  is_deeply [ map { $_->action } @ops ], [ 'drop', 'create' ],
    'a changed definition is a drop and a create';
  is_deeply [ map { $_->as_sql } @ops ],
    [ 'DROP VIEW v;', 'CREATE VIEW v AS SELECT id, name FROM base;' ],
    'the statements';
}
{
  my @ops = DBIO::Sybase::Diff::View->diff(
    { v => view('v', "SELECT id,\n    name\n  FROM base  ") },
    { v => view('v', 'SELECT id, name FROM base') });
  is scalar(@ops), 0, 'white space is not a change';
}
{
  my @ops = DBIO::Sybase::Diff::View->diff(
    { v => view('v', 'SELECT id, name FROM base') },
    { v => view('v', 'SELECT id, name FROM base WHERE id = 1') });
  is scalar(@ops), 2, 'a changed WHERE is a change';
}
{
  my @ops = DBIO::Sybase::Diff::View->diff({}, { dummy => view('dummy', 'SELECT 1 AS x') });
  is $ops[0]->as_sql, 'CREATE VIEW [dummy] AS SELECT 1 AS x;',
    'a keyword name is quoted by DBIO::Sybase::Quote';
  @ops = DBIO::Sybase::Diff::View->diff({ dummy => view('dummy', 'SELECT 1 AS x') }, {});
  is $ops[0]->as_sql, 'DROP VIEW [dummy];', 'and in the drop';
}

# --- views on views -----------------------------------------------------
{
  my %t = (
    top  => view('top',  'SELECT id FROM mid', 'mid'),
    mid  => view('mid',  'SELECT id FROM low', 'low'),
    low  => view('low',  'SELECT id FROM base'),
    zzz  => view('zzz',  'SELECT 1 AS x'),
  );
  my @ops = DBIO::Sybase::Diff::View->diff({}, \%t);
  my @names = map { $_->view->{view_name} } @ops;
  my %pos = map { $names[$_] => $_ } 0 .. $#names;
  ok $pos{low} < $pos{mid} && $pos{mid} < $pos{top},
    'created: what a view reads from comes first';
  is_deeply \@names, [ qw(low mid top zzz) ], 'and the rest in name order';

  @ops = DBIO::Sybase::Diff::View->diff(\%t, {});
  @names = map { $_->view->{view_name} } @ops;
  is_deeply \@names, [ qw(top mid low zzz) ],
    'dropped: the view that reads from another goes first';

  # only the changed one: an unchanged dependent is left alone (the server
  # answers if that does not work)
  my %s = %t;
  my %t2 = (%t, low => view('low', 'SELECT id, name FROM base'));
  @ops = DBIO::Sybase::Diff::View->diff(\%s, \%t2);
  is_deeply [ map { $_->action . ' ' . $_->view->{view_name} } @ops ],
    [ 'drop low', 'create low' ],
    'an unchanged dependent view is not touched';
}
{
  my $e = exception {
    DBIO::Sybase::Diff::View->diff({}, {
      a => view('a', 'SELECT 1 AS x FROM b', 'b'),
      b => view('b', 'SELECT 1 AS x FROM a', 'a'),
    });
  };
  isa_ok $e, 'DBIO::Exception', 'a cycle';
  like "$e", qr/cycl/i, 'says cycle';
  like "$e", qr/\ba\b.*\bb\b/s, 'names the views';
  $e = exception {
    DBIO::Sybase::Diff::View->diff({
      a => view('a', 'SELECT 1 AS x FROM b', 'b'),
      b => view('b', 'SELECT 1 AS x FROM a', 'a'),
    }, {});
  };
  isa_ok $e, 'DBIO::Exception', 'a cycle among dropped views';
}

# --- tables skip views --------------------------------------------------
{
  my @ops = DBIO::Sybase::Diff::Table->diff(
    { base => tbl('base'), gone => vtbl('gone') },
    { base => tbl('base'), fresh => vtbl('fresh'), newt => tbl('newt') },
    { newt => [ col('id') ] });
  is_deeply [ map { $_->summary } @ops ], [ 'CREATE TABLE newt' ],
    'Diff::Table neither creates nor drops a view';
}
{
  my @ops = DBIO::Sybase::Diff::Column->diff(
    { v => [ col('id') ] },
    { v => [ col('id'), col('extra') ] },
    { v => vtbl('v') }, { v => vtbl('v') });
  is scalar(@ops), 0, 'Diff::Column does not ALTER TABLE a view';
}

# --- the orchestrator ---------------------------------------------------
{
  my $source = {
    tables  => { base => tbl('base'), v => vtbl('v'), gone => vtbl('gone'), old => tbl('old') },
    columns => { base => [ col('id') ], v => [ col('id') ], gone => [ col('id') ], old => [ col('id') ] },
    indexes => {}, foreign_keys => {},
    views   => {
      v    => view('v', 'SELECT id FROM base'),
      gone => view('gone', 'SELECT id FROM old'),
    },
  };
  my $target = {
    tables  => { base => tbl('base'), v => vtbl('v'), fresh => vtbl('fresh') },
    columns => { base => [ col('id'), col('name') ], v => [ col('id'), col('name') ],
                 fresh => [ col('id') ] },
    indexes => {}, foreign_keys => {},
    views   => {
      v     => view('v', 'SELECT id, name FROM base'),
      fresh => view('fresh', 'SELECT id FROM base'),
    },
  };
  my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
  my @sql = grep { length } map { $_->as_sql } @{ $diff->operations };
  my %at;
  for my $i (0 .. $#sql) { $at{ $sql[$i] } //= $i }

  ok exists $at{'DROP VIEW v;'}, 'the changed view is dropped';
  ok exists $at{'DROP VIEW gone;'}, 'the removed view is dropped';
  ok exists $at{'DROP TABLE old;'}, 'the removed table is dropped';
  ok exists $at{'CREATE VIEW v AS SELECT id, name FROM base;'}, 'the changed view is created';
  ok exists $at{'CREATE VIEW fresh AS SELECT id FROM base;'}, 'the new view is created';
  my ($add) = grep { /^ALTER TABLE base ADD/ } @sql;
  ok defined $add, 'the column is added to the table';

  ok $at{'DROP VIEW gone;'} < $at{'DROP TABLE old;'},
    'a removed view goes before the table it reads';
  ok $at{'DROP VIEW v;'} < $at{$add},
    'a changed view goes before the column change under it';
  ok $at{$add} < $at{'CREATE VIEW v AS SELECT id, name FROM base;'},
    'a changed view is created after the column it reads';
  ok $at{$add} < $at{'CREATE VIEW fresh AS SELECT id FROM base;'},
    'a new view is created after the table changes';
  unlike join("\n", @sql), qr/TABLE (?:v|gone|fresh)\b/,
    'no statement treats a view as a table';
  ok !grep({ $_ !~ /;\z/ } @sql), 'every statement ends in ;';
}
{
  my $diff = DBIO::Sybase::Diff->new(
    source => { tables => { base => tbl('base') }, columns => { base => [ col('id') ] } },
    target => { tables => { base => tbl('base') }, columns => { base => [ col('id') ] } });
  ok !$diff->has_changes, 'models without views still diff';
}

# --- introspection ------------------------------------------------------
{
  package Test::ViewsDBH;
  our @asked;
  sub new { bless {}, shift }
  sub selectall_arrayref {
    my ($self, $sql, $attr, @bind) = @_;
    push @asked, $sql;
    if ($sql =~ /syscomments/i) {
      # shuffled on purpose: the order is the colid2/colid of the rows
      return [
        { view_name => 'v2', colid2 => 0, colid => 2, text => ' = 1' },
        { view_name => 'v1', colid2 => 0, colid => 1, text => 'create view v1 as select id from ba' },
        { view_name => 'v2', colid2 => 0, colid => 1, text => "create view dbo.v2 (x)\nas select id from v1 where id" },
        { view_name => 'v1', colid2 => 0, colid => 2, text => "se;\n" },
        { view_name => 'other', colid2 => 0, colid => 1, text => 'create view other as select 1 as x' },
      ];
    }
    if ($sql =~ /sysdepends/i) {
      return [
        { view_name => 'v2', depends_on => 'v1' },
        { view_name => 'v2', depends_on => 'v1' },
        { view_name => 'v2', depends_on => 'not_in_the_list' },
      ];
    }
    die "unexpected query: $sql";
  }
}
{
  my $tables = { map { $_ => { table_name => $_, kind => 'view' } } qw(v1 v2 other) };
  my $views = DBIO::Sybase::Introspect::Views->fetch(Test::ViewsDBH->new, 'dbo', $tables);
  is_deeply [ sort keys %$views ], [ qw(other v1 v2) ], 'every view';
  is $views->{v1}{definition}, 'select id from base', 'rows joined in colid order, head and ; stripped';
  is $views->{v2}{definition}, 'select id from v1 where id = 1', 'a head with a column list is stripped';
  is $views->{v1}{view_name}, 'v1', 'view_name';
  is_deeply $views->{v2}{depends_on}, [ 'v1' ], 'depends on views of the list only, once';
  is_deeply $views->{v1}{depends_on}, [], 'no dependencies';
  my $e = join "\n", @Test::ViewsDBH::asked;
  like $e, qr/sysdepends/i, 'dependencies come from sysdepends';
}

done_testing;
