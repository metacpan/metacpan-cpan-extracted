use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::SQL::Util ();
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff;

# LIVE (karr k65). The definition of a view in the model, and what the diff
# writes for a view that is new, changed or gone, applied to a real Oracle.
# t/94-diff-view.t pins the text; here the server takes it, hands the
# definition back, and the second diff is empty. What Oracle rewrites when it
# stores a view is pinned as measured (Oracle 23ai Free): a comment before the
# SELECT and the column list are gone, SELECT * is expanded.

my @env = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
plan skip_all => 'Set DBIO_TEST_ORA_DSN, _USER and _PASS to run this test'
  unless $env[0] && $env[1];
plan skip_all => 'DBD::Oracle not installed' unless eval { require DBD::Oracle; 1 };

my $dbh = DBI->connect(@env, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

sub wipe {
  for my $v (qw(T95_A_ON_B T95_B T95_W T95_V)) {
    eval { $dbh->do("DROP VIEW $v"); 1 };
  }
  eval { $dbh->do('DROP TABLE T95_BASE CASCADE CONSTRAINTS PURGE'); 1 };
}

my @foreign = map { $_->[0] } @{ $dbh->selectall_arrayref(q{
  SELECT table_name FROM user_tables
  WHERE table_name NOT LIKE 'BIN$%' AND table_name NOT LIKE 'T95\_%' ESCAPE '\'
  UNION ALL
  SELECT view_name FROM user_views WHERE view_name NOT LIKE 'T95\_%' ESCAPE '\'
}) };
plan skip_all => "The schema must hold no tables or views but this test's own (T95_*); found: @foreign"
  if @foreign;

wipe();
END { wipe() if $dbh }

sub model { return DBIO::Oracle::Introspect->new(dbh => $dbh)->model }

# the way DBIO::Deploy::Base::_execute_ddl takes a diff's SQL: statement by statement
sub apply {
  my ($sql) = @_;
  return [ map {
    my $s = $_;
    my $went = eval { $dbh->do($s); 1 } ? 'ok' : ( $@ =~ /(ORA-\d+)/ )[0] // "no ORA number: $@";
    ( my $short = $s ) =~ s/\s+/ /g;
    "$short -- $went";
  } DBIO::SQL::Util::_split_statements($sql) ];
}

sub diff_of { return DBIO::Oracle::Diff->new(source => $_[0], target => $_[1]) }

$dbh->do('CREATE TABLE T95_BASE (ID NUMBER(10) PRIMARY KEY, NAME VARCHAR2(20), EXTRA VARCHAR2(20))');
my $A = model();

# ---- the model carries the definition, as Oracle stores it
$dbh->do('CREATE VIEW T95_V (X, Y, Z) AS /* a comment */ SELECT * FROM T95_BASE');
$dbh->do(q{CREATE VIEW T95_W AS
  select   ID ,   NAME
    from T95_BASE where NAME = 'a  b';});
my $B = model();

is_deeply $B->{views}{T95_V}, {
  view_name  => 'T95_V',
  definition => 'SELECT "ID","NAME","EXTRA" FROM T95_BASE',
  columns    => [ qw(X Y Z) ],
  depends_on => [],
}, 'the model holds the definition (the comment and the column list are gone from the text, SELECT * is expanded) and the names of the columns, in order';

is $B->{views}{T95_W}{definition}, "select   ID ,   NAME\n    from T95_BASE where NAME = 'a  b'",
  '... case and whitespace as written, the semicolon gone';

is_deeply [ sort keys %{ $B->{views} } ], [ qw(T95_V T95_W) ], '... one entry per view, none for the table';

# ---- a new view
$dbh->do('DROP VIEW T95_V');
$dbh->do('DROP VIEW T95_W');
{
  my $diff = diff_of($A, $B);
  is_deeply [ split /\n/, $diff->summary ], [ '+ view: T95_V', '+ view: T95_W' ],
    'new: the diff creates both views';
  is_deeply [ map { s/.* -- //sr } @{ apply($diff->as_sql) } ], [ 'ok', 'ok' ],
    '... and Oracle takes them';
  ok !diff_of($B, model())->has_changes, '... the model of the result compares equal: a second diff is empty';
  is_deeply $dbh->selectcol_arrayref(q{SELECT column_name FROM user_tab_columns WHERE table_name = 'T95_V' ORDER BY column_id}),
    [ qw(X Y Z) ], '... the view made by the diff has the names of the column list, not those of its query';
}

# ---- a changed view
my $C;
{
  $dbh->do('CREATE OR REPLACE VIEW T95_W AS SELECT ID, NAME, EXTRA FROM T95_BASE');
  $C = model();
  $dbh->do(q{CREATE OR REPLACE VIEW T95_W AS select   ID ,   NAME
    from T95_BASE where NAME = 'a  b'});
  my $diff = diff_of($B, $C);
  is_deeply [ split /\n/, $diff->summary ], [ '~ view: T95_W' ], 'changed: only the changed view is replaced';
  is_deeply [ map { s/.* -- //sr } @{ apply($diff->as_sql) } ], [ 'ok' ], '... and Oracle takes it';
  ok !diff_of($C, model())->has_changes, '... a second diff is empty';

  # the same text in other whitespace is no change
  $dbh->do(qq{CREATE OR REPLACE VIEW T95_W AS SELECT   ID,\n  NAME,   EXTRA   FROM   T95_BASE});
  ok !diff_of($C, model())->has_changes, 'whitespace between the tokens is not a change';
}

# ---- only the column list changed
{
  my $before = model();
  $dbh->do('CREATE OR REPLACE VIEW T95_V (X, Z, Y) AS SELECT ID, NAME, EXTRA FROM T95_BASE');
  my $after = model();
  my $diff = diff_of($before, $after);
  is_deeply [ split /\n/, $diff->summary ], [ '~ view: T95_V' ], 'the same query under other names: the view is changed';
  $dbh->do('CREATE OR REPLACE VIEW T95_V (X, Y, Z) AS SELECT ID, NAME, EXTRA FROM T95_BASE');
  is_deeply [ map { s/.* -- //sr } @{ apply(diff_of(model(), $after)->as_sql) } ], [ 'ok' ], '... and Oracle takes it';
  is_deeply model()->{views}{T95_V}{columns}, [ qw(X Z Y) ], '... the names are those of the new list';
  ok !diff_of($after, model())->has_changes, '... a second diff is empty';
  $dbh->do('CREATE OR REPLACE VIEW T95_V (X, Y, Z) AS SELECT ID, NAME, EXTRA FROM T95_BASE');
}

# ---- a view on a view: created after the one it rests on, dropped before it
{
  $dbh->do('CREATE VIEW T95_B AS SELECT ID FROM T95_BASE');
  $dbh->do('CREATE VIEW T95_A_ON_B AS SELECT ID FROM T95_B');
  my $both = model();
  is_deeply $both->{views}{T95_A_ON_B}{depends_on}, ['T95_B'], 'the model holds what a view rests on';
  is_deeply $both->{views}{T95_B}{depends_on}, [], '... and nothing for a view on a table only';
  wipe_views();
  my $without = model();
  my $diff = diff_of($without, $both);
  is_deeply [ $diff->summary =~ /view: (\w+)/g ], [ qw(T95_B T95_A_ON_B) ],
    'new: the view it rests on comes first, though its name sorts later';
  is_deeply [ map { s/.* -- //sr } @{ apply($diff->as_sql) } ], [ 'ok', 'ok' ],
    'a view on a view made in the same run is created after it';
  ok !diff_of($both, model())->has_changes, '... a second diff is empty';

  my $gone = diff_of(model(), $without);
  is_deeply [ $gone->summary =~ /view: (\w+)/g ], [ qw(T95_A_ON_B T95_B) ],
    'gone: the dependent view is dropped before the view it rests on';
  is_deeply [ map { s/.* -- //sr } @{ apply($gone->as_sql) } ], [ 'ok', 'ok' ], '... and Oracle takes both';
  wipe_views();
}

sub wipe_views {
  for my $v (qw(T95_A_ON_B T95_B)) { eval { $dbh->do("DROP VIEW $v"); 1 } }
}

# ---- gone: the views are dropped before the table they rest on
{
  wipe_views();
  my $diff = diff_of(model(), { tables => {}, columns => {} });
  my @first = map { (split /\n/, $_->as_sql)[0] } @{ $diff->operations };
  is_deeply \@first, [ 'DROP VIEW "T95_V";', 'DROP VIEW "T95_W";', 'DROP TABLE "T95_BASE" CASCADE CONSTRAINTS;' ],
    'gone: both views are dropped, then the table';
  is_deeply [ map { s/.* -- //sr } @{ apply($diff->as_sql) } ], [ ('ok') x 3 ], '... and Oracle takes all three';
  is_deeply [ sort keys %{ model()->{tables} } ], [], '... nothing is left';
}

done_testing;
