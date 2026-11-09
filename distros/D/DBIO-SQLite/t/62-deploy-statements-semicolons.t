use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::SQL::Util ();
use DBIO::Deploy::Base ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Diff ();
use DBIO::SQLite::Diff::Rebuild ();
use DBIO::SQLite::Introspect ();

eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';

# karr k75 -- DBIO::SQLite::Deploy::apply runs the statements of a diff, and a
# statement can hold a semicolon: a trigger between the statements of its body,
# a string, a comment. Core's _execute_ddl cuts the text it is given at the
# semicolons the splitter (DBIO::SQL::Util::_split_statements) reads as ends.
#
# karr k78 -- the splitter reads a bare "end" or "begin" as a column name and
# SQLite's backslash as a plain character, and the latter only because the
# storage declares its dialect (_ddl_sql_dialect, core karr k332). apply hands
# the whole diff to _execute_ddl in one text. This file holds that every one of
# these statements gets through apply whole, that the storage names 'sqlite',
# and what the splitter does with the dialect-dependent forms under that name.

sub memory_dbh {
  return DBI->connect('dbi:SQLite::memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

{
  package HandMade::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}

# Triggers as sqlite_master keeps them: the text as written, no semicolon.
my %TRIGGER = (
  item_case => <<'SQL',
CREATE TRIGGER item_case AFTER INSERT ON item BEGIN
  UPDATE item SET s = CASE WHEN NEW.id > 1 THEN 'big' ELSE 'small' END
   WHERE id = NEW.id;
  INSERT INTO log (msg) VALUES ('case');
END
SQL
  item_end => <<'SQL',
CREATE TRIGGER item_end AFTER INSERT ON item BEGIN
  UPDATE item SET end = 1 WHERE id = NEW.id;
  INSERT INTO log (msg) VALUES ('end');
END
SQL
  item_begin => <<'SQL',
CREATE TRIGGER item_begin AFTER DELETE ON item BEGIN
  UPDATE item SET begin = 2 WHERE begin = 1;
  INSERT INTO log (msg) VALUES ('begin');
END
SQL
  item_literal => <<'SQL',
CREATE TRIGGER item_literal AFTER UPDATE ON item WHEN NEW.s = 'END; BEGIN' BEGIN
  -- a comment; with end
  INSERT INTO log (msg) VALUES ('END; BEGIN'); /* and another; one */
END
SQL
);
chomp %TRIGGER;

my $TABLE = <<'SQL';
CREATE TABLE item (
  id INTEGER PRIMARY KEY,
  begin INTEGER,
  end INTEGER,
  s TEXT DEFAULT 'a;b', -- a default with a semicolon; and a comment with one
  t TEXT /* here; too */
)
SQL
chomp $TABLE;

my $dbh = memory_dbh();
$dbh->do($TABLE);
$dbh->do('CREATE TABLE log (msg TEXT)');
$dbh->do($_) for values %TRIGGER;

my $model = DBIO::SQLite::Introspect->new(dbh => $dbh)->model;

my $op = DBIO::SQLite::Diff::Rebuild->new(
  table_name   => 'item',
  table_sql    => $model->{tables}{item}{sql},
  copy_columns => [qw(id begin end s t)],
  triggers     => [ map { $TRIGGER{$_} } sort keys %TRIGGER ],
);
my $diff = DBIO::SQLite::Diff->new(
  source => $model, target => $model, operations => [$op],
);

# ---------------------------------------------------------------------------
# apply: every statement gets through whole
# ---------------------------------------------------------------------------

my $before = $dbh->selectall_arrayref(
  q{SELECT type, name, sql FROM sqlite_master ORDER BY type, name});

my $deploy = DBIO::SQLite::Deploy->new(
  schema => HandMade::Schema->connect(sub { $dbh }),
);

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  ok(eval { $deploy->apply($diff) }, 'a rebuild whose statements hold semicolons applies')
    or diag $@;
}

# The rebuild names its table quoted; everything else stays as written.
my $after = $dbh->selectall_arrayref(
  q{SELECT type, name, sql FROM sqlite_master ORDER BY type, name});
$_->[2] =~ s/\ACREATE TABLE "item"/CREATE TABLE item/ for @$after;
is_deeply($after, $before,
  'and leaves the database as it was: tables, defaults and triggers, text for text');

$dbh->do('INSERT INTO item (id, begin) VALUES (1, 1)');
is_deeply(
  [ sort @{ $dbh->selectcol_arrayref('SELECT msg FROM log') } ],
  [qw(case end)],
  'the CASE trigger and the one with a bare "end" column fire as stored',
);
is_deeply(
  $dbh->selectrow_arrayref('SELECT s, end FROM item WHERE id = 1'),
  [ 'small', 1 ],
  'with their effect',
);

$dbh->do('DELETE FROM log');
$dbh->do('DELETE FROM item WHERE id = 1');
is_deeply($dbh->selectcol_arrayref('SELECT msg FROM log'), ['begin'],
  'the trigger with a bare "begin" column fires');

$dbh->do('DELETE FROM log');
$dbh->do(q{INSERT INTO item (id, s) VALUES (5, 'x')});
$dbh->do('DELETE FROM log');
$dbh->do(q{UPDATE item SET s = 'END; BEGIN' WHERE id = 5});
is_deeply($dbh->selectcol_arrayref('SELECT msg FROM log'), ['END; BEGIN'],
  'the one with semicolons in a literal and in comments fires');

$dbh->do('INSERT INTO item (id) VALUES (9)');
$dbh->do('DELETE FROM log');
is(scalar $dbh->selectrow_array('SELECT s FROM item WHERE id = 9'), 'big',
  'the rebuilt table has its triggers on it');

# ---------------------------------------------------------------------------
# the splitter, as this driver's storage drives it
# ---------------------------------------------------------------------------

my @cases = (
  [ 'a trigger body with CASE ... END'          => $TRIGGER{item_case} ],
  [ 'a trigger with a literal and comments'     => $TRIGGER{item_literal} ],
  [ 'a string default with a semicolon'         => $TABLE ],
  [ 'a trigger body with a bare "end" column'   => $TRIGGER{item_end} ],
  [ 'a trigger body with a bare "begin" column' => $TRIGGER{item_begin} ],
);

for my $case (@cases) {
  my ($label, $sql) = @$case;
  my @got = DBIO::SQL::Util::_split_statements("$sql;\nCREATE TABLE after (id INTEGER);");
  is_deeply(\@got, [ $sql, 'CREATE TABLE after (id INTEGER)' ],
    "the core splitter keeps $label whole");
}

# Driver resolution is lazy: it runs on the first dbh access, so touch the
# handle before asking what the storage is.
my $storage = HandMade::Schema->connect(sub { memory_dbh() })->storage;
$storage->dbh;
isa_ok($storage, 'DBIO::SQLite::Storage', 'the connected storage');
is($storage->_ddl_sql_dialect, 'sqlite',
  'the storage declares the sqlite dialect for the DDL splitter');

# In SQLite a backslash inside a literal is a character, not an escape. The
# first literal below ends on it; read as an escape, it would swallow the
# quote and the cut after it, and the semicolon of the next literal would end
# a statement. Without a declared dialect the splitter takes both readings and
# cuts there. (No parentheses on purpose: inside them a semicolon is never a
# cut, and the case would not depend on the dialect.)
my $backslash = join ";\n",
  q{UPDATE t SET s = 'a\'},
  q{UPDATE t SET s = 'b;c'};
my @want = (q{UPDATE t SET s = 'a\'}, q{UPDATE t SET s = 'b;c'});

is_deeply([ DBIO::Deploy::Base::_split_ddl($storage, $backslash) ], \@want,
  'a literal ending on a backslash, then a literal with a semicolon: cut as SQLite reads it');

is_deeply([ DBIO::Deploy::Base::_split_ddl($storage, "$backslash;") ], \@want,
  'and with the trailing semicolon');

# End to end: the text goes through _execute_ddl, which asks the storage.
{
  my $dbh2 = memory_dbh();
  my $deploy2 = DBIO::SQLite::Deploy->new(
    schema => HandMade::Schema->connect(sub { $dbh2 }),
  );
  $dbh2->do(q{CREATE TABLE t (s TEXT)});
  $dbh2->do(q{INSERT INTO t (s) VALUES ('x')});
  ok(eval { $deploy2->_execute_ddl($dbh2, "$backslash;"); 1 },
    'such a text runs through _execute_ddl') or diag $@;
  is($dbh2->selectrow_array('SELECT s FROM t'), 'b;c',
    'and the second literal arrives whole');
}

done_testing;
