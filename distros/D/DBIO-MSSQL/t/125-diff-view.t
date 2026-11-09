use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Diff::View;
use DBIO::MSSQL::DDL;

# karr k82: the diff creates, replaces and drops views. A view is an entry of
# the model's tables with kind => 'view' and its stored text in definition
# (sys.sql_modules). Live counterpart: t/126-diff-view-live.t.

sub model {
  my (%spec) = @_;    # name => definition ('TABLE' makes a table)
  my (%tables, %columns);
  for my $n (keys %spec) {
    my $is_table = ($spec{$n} // '') eq 'TABLE';
    $tables{$n} = { table_name => $n, kind => $is_table ? 'table' : 'view',
      $is_table ? () : (definition => $spec{$n}) };
    $columns{$n} = [ { column_name => 'id', data_type => 'int', not_null => 1,
      ($is_table ? (is_pk => 1) : ()) } ];
  }
  return { tables => \%tables, columns => \%columns, indexes => {}, foreign_keys => {} };
}
sub stmts {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return map { $_->as_sql } @{ $d->operations };
}

# body and normalize
{
  my $B = 'DBIO::MSSQL::Diff::View';
  is $B->body('CREATE VIEW [dbo].[v] AS SELECT 1 AS a'), 'SELECT 1 AS a', 'body: bracketed name';
  is $B->body("create view v\n  as\n  select 1;\n"), 'select 1', 'body: lower case, newlines, trailing ;';
  is $B->body('CREATE VIEW v (a, [as]) WITH SCHEMABINDING AS SELECT 1, 2'), 'SELECT 1, 2',
    'body: column list with a column called as, options';
  is $B->body('CREATE OR ALTER VIEW [my schema].[v w] AS SELECT 1'), 'SELECT 1', 'body: quoted schema and name';
  is $B->body("-- note\nCREATE VIEW v AS SELECT 1"), 'SELECT 1', 'body: comment before the header';
  is $B->body('SELECT 2'), 'SELECT 2', 'body: not a header, taken as it is';
  is $B->normalize("CREATE VIEW v AS SELECT  a,\n\tb  FROM t"), 'SELECT a, b FROM t', 'normalize folds white space';
  isnt $B->normalize('CREATE VIEW v AS SELECT A'), $B->normalize('CREATE VIEW v AS SELECT a'), 'case is not folded';
}

my $base = 'TABLE';

# added
{
  my @s = stmts(model(t => $base),
                model(t => $base, v => 'CREATE VIEW v AS SELECT id FROM t'));
  is_deeply \@s, ["CREATE OR ALTER VIEW v AS\nSELECT id FROM t;"], 'added: CREATE OR ALTER VIEW';
}

# dropped
{
  my @s = stmts(model(t => $base, v => 'CREATE VIEW [dbo].[v] AS SELECT id FROM t'), model(t => $base));
  is_deeply \@s, ['DROP VIEW v;'], 'dropped: DROP VIEW';
}

# changed, and same after normalization
{
  my $src = model(t => $base, v => 'CREATE VIEW [dbo].[v] AS SELECT id FROM t');
  my @s = stmts($src, model(t => $base, v => 'CREATE VIEW v AS SELECT id, id AS i2 FROM t'));
  is_deeply \@s, ["CREATE OR ALTER VIEW v AS\nSELECT id, id AS i2 FROM t;"], 'changed: CREATE OR ALTER VIEW';
  my $d = DBIO::MSSQL::Diff->new(source => $src,
    target => model(t => $base, v => "CREATE VIEW v AS\n  SELECT   id\nFROM t"));
  ok !$d->has_changes, 'same body, other white space and header: no change';
  like(DBIO::MSSQL::Diff->new(source => $src, target => model(t => $base))->summary,
    qr/^- view: v/m, 'summary names the drop');
}

# schema-qualified
{
  my @s = stmts(model(), model('my s.v' => 'CREATE VIEW v AS SELECT 1 AS id'));
  is $s[0], 'CREATE SCHEMA [my s];', 'a view in a new schema: CREATE SCHEMA first';
  is $s[1], "CREATE OR ALTER VIEW [my s].v AS\nSELECT 1 AS id;", 'schema part quoted on its own';
  @s = stmts(model('other.v' => 'CREATE VIEW other.v AS SELECT 1'), model());
  is_deeply \@s, ['DROP VIEW other.v;'], 'dropped view of another schema';
}

# order: drops before DROP TABLE, creates after CREATE TABLE and the keys
{
  my @s = stmts(model(old => $base, ov => 'CREATE VIEW ov AS SELECT id FROM old'),
                model(new => $base, nv => 'CREATE VIEW nv AS SELECT id FROM new'));
  my %at = map { ($s[$_] =~ /^(DROP VIEW|DROP TABLE|CREATE TABLE|CREATE OR ALTER VIEW)/)[0] => $_ } 0 .. $#s;
  ok $at{'DROP VIEW'} < $at{'DROP TABLE'}, 'DROP VIEW before DROP TABLE';
  ok $at{'CREATE TABLE'} < $at{'CREATE OR ALTER VIEW'}, 'CREATE VIEW after CREATE TABLE';
}

# views that read views: the order is the one of the dependencies, not of the
# names (z_base is the one that is read, a_top reads it)
{
  my $m = sub {
    my ($with_deps, @drop) = @_;
    my $mm = model(t => $base,
      z_base => 'CREATE VIEW z_base AS SELECT id FROM t',
      a_top  => 'CREATE VIEW a_top AS SELECT id FROM z_base');
    $mm->{tables}{a_top}{depends_on} = ['z_base'] if $with_deps;
    return $mm;
  };
  my @s = stmts(model(t => $base), $m->(1));
  is_deeply [ map { /VIEW (\w+)/ } @s ], [qw(z_base a_top)], 'create: the view that is read first';
  @s = stmts($m->(1), model(t => $base));
  is_deeply [ map { /VIEW (\w+)/ } @s ], [qw(a_top z_base)], 'drop: the view that reads first';
  my $old = $m->(1);
  my $new = $m->(1);
  $new->{tables}{z_base}{definition} = 'CREATE VIEW z_base AS SELECT id, id AS j FROM t';
  $new->{tables}{a_top}{definition}  = 'CREATE VIEW a_top AS SELECT id, j FROM z_base';
  @s = stmts($old, $new);
  is_deeply [ map { /VIEW (\w+)/ } @s ], [qw(z_base a_top)], 'change: the view that is read first';

  my $cycle = $m->(1);
  $cycle->{tables}{z_base}{depends_on} = ['a_top'];
  my $ok = eval { stmts(model(t => $base), $cycle); 1 };
  ok !$ok && "$@" =~ /cycle.*refus/s, 'a cycle is refused';
  my $unknown = model(t => $base, a_top => 'CREATE VIEW a_top AS SELECT 1 AS id');
  $unknown->{tables}{a_top}{depends_on} = ['gone'];
  $ok = eval { stmts(model(t => $base), $unknown); 1 };
  ok !$ok && "$@" =~ /'gone'.*refus/s, 'a view read that the model does not know is refused';
}

# install_ddl writes the views in the order of what they name
{
  my @o = DBIO::MSSQL::DDL::_order_view_statements(
    [ a_top => 'SELECT id FROM [z_base]' ], [ z_base => 'SELECT 1 AS id' ], [ m => 'SELECT 2' ]);
  is_deeply [ map { /VIEW (\w+)/ } @o ], [qw(z_base a_top m)], 'DDL: the view that is named first';
}

# a declared view without a definition cannot be written
{
  my $ok = eval { stmts(model(), model(v => undef)); 1 };
  ok !$ok && "$@" =~ /view 'v' is declared without a definition/, 'no definition: refused';
}

done_testing;
