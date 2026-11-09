use strict;
use warnings;

use Test::More;
use DBIO::SQL::Util '_quote_ident', '_split_statements';

# _quote_ident tests
# Pattern: /^[a-z_][a-z0-9_]*$/i - simple identifiers returned as-is
subtest '_quote_ident simple (no quoting needed)' => sub {
  is(_quote_ident('foo'), 'foo', 'simple lowercase');
  is(_quote_ident('bar'), 'bar', 'simple with numbers');
  is(_quote_ident('foo_bar'), 'foo_bar', 'with underscore');
  is(_quote_ident('FOO'), 'FOO', 'uppercase');
  is(_quote_ident('_foo'), '_foo', 'starts with underscore');
  is(_quote_ident('FooBar'), 'FooBar', 'mixed case');
  is(_quote_ident('bar123'), 'bar123', 'alphanumeric');
};

# A trailing newline is no part of a simple identifier (karr k393)
subtest '_quote_ident quotes a name with a trailing newline' => sub {
  is(_quote_ident("a\n"), qq{"a\n"}, 'trailing newline is quoted');
  is(_quote_ident("ab_1\n"), qq{"ab_1\n"}, 'a name that is otherwise simple is quoted');
};

# Identifiers that need quoting
subtest '_quote_ident needs quoting' => sub {
  is(_quote_ident('foo bar'), '"foo bar"', 'space');
  is(_quote_ident('foo"bar'), '"foo""bar"', 'embedded double quote');
  is(_quote_ident('1foo'), '"1foo"', 'starts with digit');
  is(_quote_ident(''), '""', 'empty string');
};

subtest '_quote_ident embedded quotes' => sub {
  is(_quote_ident('foo""bar'), '"foo""""bar"', 'embedded escaped quotes');
  is(_quote_ident('a"b"c'), '"a""b""c"', 'multiple embedded quotes');
};

# _split_statements tests
subtest '_split_statements basic' => sub {
  is_deeply([_split_statements("SELECT 1; SELECT 2;")],
    ["SELECT 1", "SELECT 2"], 'basic semicolon split');
  is_deeply([_split_statements("SELECT 1;")], ["SELECT 1"], 'single statement');
  is_deeply([_split_statements("SELECT 1; SELECT 2")],
    ["SELECT 1", "SELECT 2"], 'no trailing semicolon');
};

subtest '_split_statements dollar quoting' => sub {
  # $$ toggles dollar quoting state - semicolons inside are not split
  my $sql1 = "SELECT \$\$; SELECT 1;";
  my @r1 = _split_statements($sql1);
  is($r1[0], 'SELECT $$', '$$ does not split - first stmt');
  is($r1[1], 'SELECT 1', '$$ does not split - second stmt');

  # Tagged dollar quotes ($a$)
  my $sql2 = "SELECT \$a\$; SELECT 2;";
  my @r2 = _split_statements($sql2);
  is($r2[0], 'SELECT $a$', 'tagged dollar quotes - first stmt');
  is($r2[1], 'SELECT 2', 'tagged dollar quotes - second stmt');

  # A string literal protects its semicolons just as $$ does
  is_deeply([_split_statements("SELECT 'foo;bar'; SELECT 1;")],
    ["SELECT 'foo;bar'", 'SELECT 1'], 'single quotes protect a semicolon');
};

subtest '_split_statements whitespace and blanks' => sub {
  is_deeply([_split_statements("   SELECT 1;   SELECT 2;   ")],
    ["SELECT 1", "SELECT 2"], 'trim whitespace');
  is_deeply([_split_statements(";SELECT 1;;SELECT 2;;")],
    ["SELECT 1", "SELECT 2"], 'blank statements discarded');
};

subtest '_split_statements empty' => sub {
  is_deeply([_split_statements("")], [], 'empty string');
  is_deeply([_split_statements("   ")], [], 'whitespace only');
  is_deeply([_split_statements(";;;")], [], 'semicolons only');
};

subtest '_split_statements real world' => sub {
  is_deeply([_split_statements("CREATE TABLE foo (id INT); INSERT INTO foo VALUES (1);")],
    ["CREATE TABLE foo (id INT)", "INSERT INTO foo VALUES (1)"], 'DDL + DML');
  # A semicolon in a comment ends nothing; the comment stays where it is
  is_deeply(
    [_split_statements("SELECT 1 -- comment; not a real semicolon\n; SELECT 2")],
    ["SELECT 1 -- comment; not a real semicolon", 'SELECT 2'],
    'semicolon in a line comment inside a statement');
};

subtest '_split_statements dollar quotes across lines' => sub {
  my $sql = "CREATE FUNCTION foo() RETURNS TEXT AS \$\$\nSELECT 'hello';\n\$\$ LANGUAGE SQL;";
  my @r = _split_statements($sql);
  is(scalar(@r), 1, 'dollar quote spans lines - single stmt');
  is($r[0], "CREATE FUNCTION foo() RETURNS TEXT AS \$\$\nSELECT 'hello';\n\$\$ LANGUAGE SQL", 'dollar quote spans lines - content');
};

# --- the text is read as SQL (karr k326) -------------------------------------
# Every case names the statements the engine has to receive. A piece cut at a
# semicolon inside a literal, an identifier, a comment or a trigger body is
# refused by the engine; two statements read as one are refused as well, and a
# statement dropped with its comment never runs at all.

sub splits_ok {
  my ($sql, $want, $name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is_deeply([_split_statements($sql)], $want, $name)
    or diag explain [_split_statements($sql)];
}

subtest '_split_statements string literals' => sub {
  splits_ok("CREATE TABLE s (id int, s text DEFAULT 'a;b');",
    ["CREATE TABLE s (id int, s text DEFAULT 'a;b')"],
    'semicolon in a column default');
  splits_ok("CREATE VIEW v AS SELECT 'x;y' AS c;",
    ["CREATE VIEW v AS SELECT 'x;y' AS c"],
    'semicolon in a view literal');
  splits_ok("INSERT INTO t VALUES ('it''s; ok'); SELECT 2",
    ["INSERT INTO t VALUES ('it''s; ok')", 'SELECT 2'],
    "a doubled '' stays inside the literal");
  splits_ok("SELECT 'a' || '''' || ';'; SELECT 2",
    ["SELECT 'a' || '''' || ';'", 'SELECT 2'],
    'a literal that is one quote');
  splits_ok("SELECT q'[it's; here]' FROM dual; SELECT 2 FROM dual",
    ["SELECT q'[it's; here]' FROM dual", 'SELECT 2 FROM dual'],
    "Oracle q'[...]' is one literal, apostrophe and all");
  splits_ok("SELECT nq'!it's!' FROM dual; SELECT 2 FROM dual",
    ["SELECT nq'!it's!' FROM dual", 'SELECT 2 FROM dual'],
    "Oracle nq'!...!' does not leave a quote open");
};

subtest '_split_statements quoted identifiers' => sub {
  splits_ok('CREATE TABLE "a;b" (id int); SELECT 1',
    ['CREATE TABLE "a;b" (id int)', 'SELECT 1'], 'double quotes');
  splits_ok('CREATE TABLE "a"";b" (id int); SELECT 1',
    ['CREATE TABLE "a"";b" (id int)', 'SELECT 1'], 'doubled "" inside');
  splits_ok('CREATE TABLE `a;b` (id int); SELECT 1',
    ['CREATE TABLE `a;b` (id int)', 'SELECT 1'], 'backticks');
  splits_ok('CREATE TABLE `a``;b` (id int); SELECT 1',
    ['CREATE TABLE `a``;b` (id int)', 'SELECT 1'], 'doubled `` inside');
  splits_ok('CREATE TABLE [a;b] (id int); SELECT 1',
    ['CREATE TABLE [a;b] (id int)', 'SELECT 1'], 'brackets after a keyword');
  splits_ok('SELECT [dbo].[a]];b] FROM [t;u]; SELECT 1',
    ['SELECT [dbo].[a]];b] FROM [t;u]', 'SELECT 1'], 'doubled ]] inside');
  splits_ok(q{SELECT "it's" FROM t; SELECT 'a"b' FROM t},
    [q{SELECT "it's" FROM t}, q{SELECT 'a"b' FROM t}],
    'a quote of the other kind inside opens nothing');
};

subtest '_split_statements brackets that are no identifiers' => sub {
  splits_ok("SELECT ARRAY['a]', 'b;c']; SELECT 2",
    ["SELECT ARRAY['a]', 'b;c']", 'SELECT 2'],
    'array constructor: its literals are read as literals');
  splits_ok("SELECT ARRAY[name, 'a];b'] FROM t; SELECT 2",
    ["SELECT ARRAY[name, 'a];b'] FROM t", 'SELECT 2'],
    'array constructor that opens on a column');
  splits_ok("SELECT col[1], (data)[k || 'a];b'], m[1][k || 'c];d'] FROM t; SELECT 2",
    ["SELECT col[1], (data)[k || 'a];b'], m[1][k || 'c];d'] FROM t", 'SELECT 2'],
    'subscript after a word, a ) and a ]');
  splits_ok("SELECT ARRAY[['a]', 'b'], ['c;d', 'e']]; SELECT 2",
    ["SELECT ARRAY[['a]', 'b'], ['c;d', 'e']]", 'SELECT 2'],
    'a bracket inside an array is an array');
  # ClickHouse and DuckDB write a list without a word in front. What opens on
  # a literal or on a further bracket is such a list, not an identifier.
  splits_ok("CREATE VIEW v AS SELECT multiMatchAny(s, ['[0-9]+', 'a;b']) FROM t; SELECT 2",
    ["CREATE VIEW v AS SELECT multiMatchAny(s, ['[0-9]+', 'a;b']) FROM t", 'SELECT 2'],
    'a list of literals: its literals are read as literals');
  splits_ok("SELECT ['[0-9]+', 'x'] AS l; SELECT 2",
    ["SELECT ['[0-9]+', 'x'] AS l", 'SELECT 2'],
    'a ] inside a list literal leaves no quote open');
  splits_ok("SELECT [\n  ['a]'], [ 'b;c' ]\n] AS l; SELECT 2",
    ["SELECT [\n  ['a]'], [ 'b;c' ]\n] AS l", 'SELECT 2'],
    'a list of lists');
};

subtest '_split_statements comments' => sub {
  splits_ok("CREATE TABLE c (id int /* a; b */);",
    ['CREATE TABLE c (id int /* a; b */)'],
    'semicolon in a block comment');
  splits_ok("CREATE TABLE c (\n  id int, -- x; y\n  n text\n); SELECT 1",
    ["CREATE TABLE c (\n  id int, -- x; y\n  n text\n)", 'SELECT 1'],
    'semicolon in a line comment inside a statement');
  splits_ok("SELECT 1 /* it's */; SELECT 2 -- don't\n; SELECT 3",
    ["SELECT 1 /* it's */", "SELECT 2 -- don't", 'SELECT 3'],
    'an apostrophe in a comment opens no literal');
  splits_ok("SELECT '-- no comment'; SELECT '/* nor this'; SELECT 3",
    ["SELECT '-- no comment'", "SELECT '/* nor this'", 'SELECT 3'],
    'a comment marker inside a literal opens no comment');
  splits_ok("SELECT 1 /* a /* b */; SELECT 2 /* c */",
    ['SELECT 1 /* a /* b */', 'SELECT 2 /* c */'],
    'block comments do not nest: the first */ closes');
};

subtest '_split_statements comments are not statements' => sub {
  splits_ok("-- users\nCREATE TABLE t (id int);\nCREATE TABLE u (id int);",
    ['CREATE TABLE t (id int)', 'CREATE TABLE u (id int)'],
    'a comment line before a statement: delivered, without the comment');
  splits_ok("/* head */ -- more\n  /* and more */\nCREATE TABLE t (id int)",
    ['CREATE TABLE t (id int)'],
    'several leading comments of both kinds');
  splits_ok("SELECT 1;\n-- only a comment\n;\n/* another */;\nSELECT 2;\n-- tail",
    ['SELECT 1', 'SELECT 2'],
    'a piece that is only comments is no statement');
  splits_ok("-- nothing here", [], 'a text that is one comment');
  splits_ok("/* never closed; SELECT 1", [], 'an unclosed block comment');
  splits_ok("/*!40101 SET x=1 */;\nSELECT 1",
    ['/*!40101 SET x=1 */', 'SELECT 1'],
    'a MySQL /*! ... */ is code and stays');
  splits_ok("-- lead\n/*!40101 SET x=1 */;",
    ['/*!40101 SET x=1 */'],
    'a comment before a /*! ... */ goes, the /*! ... */ stays');
  splits_ok("/*+ hint */ SELECT 1; SELECT 2",
    ['/*+ hint */ SELECT 1', 'SELECT 2'],
    'a /*+ hint */ is code and stays');
  splits_ok("-- lead\nSELECT 1 /* inner */ + 1 -- trailing",
    ['SELECT 1 /* inner */ + 1 -- trailing'],
    'comments inside and behind a statement are left as they are');
};

subtest '_split_statements dollar quoting follows the PostgreSQL rule' => sub {
  splits_ok('SELECT a$b$ FROM x; SELECT c$b$ FROM y;',
    ['SELECT a$b$ FROM x', 'SELECT c$b$ FROM y'],
    'a $ behind a word character belongs to the identifier');
  splits_ok('SELECT $1, $1; SELECT $1, $1;',
    ['SELECT $1, $1', 'SELECT $1, $1'],
    '$1 is a placeholder, no tag');
  splits_ok('SELECT $1$ a; SELECT $1$ b;',
    ['SELECT $1$ a', 'SELECT $1$ b'],
    'a tag does not start with a digit');
  splits_ok(q{CREATE FUNCTION f() RETURNS text AS $$ BEGIN RETURN 'it''s; x'; END; $$ LANGUAGE plpgsql; SELECT 2},
    [q{CREATE FUNCTION f() RETURNS text AS $$ BEGIN RETURN 'it''s; x'; END; $$ LANGUAGE plpgsql}, 'SELECT 2'],
    '$$ body with semicolons and literals');
  splits_ok(q{CREATE FUNCTION f() RETURNS text AS $fn$ SELECT 'isn't; $$ ' $fn$ LANGUAGE sql; SELECT 2},
    [q{CREATE FUNCTION f() RETURNS text AS $fn$ SELECT 'isn't; $$ ' $fn$ LANGUAGE sql}, 'SELECT 2'],
    '$fn$ body with a semicolon, an odd quote and a $$ inside');
  splits_ok(q{SELECT '$$'; SELECT '$$';},
    [q{SELECT '$$'}, q{SELECT '$$'}],
    'a $$ inside a literal opens nothing');
  splits_ok(q{SELECT 1 -- $$ in a comment; x} . "\n" . q{; SELECT '$$'},
    [q{SELECT 1 -- $$ in a comment; x}, q{SELECT '$$'}],
    'a $$ inside a comment opens nothing');
};

subtest '_split_statements backslash: both readings' => sub {
  # PostgreSQL E'...' is the backslash reading whatever the dialect.
  splits_ok(q{SELECT E'it\'s; x'; SELECT 2},
    [q{SELECT E'it\'s; x'}, 'SELECT 2'], q{E'...' reads \' as an escaped quote});
  splits_ok(q{SELECT e'a\\\\'; SELECT 2},
    [q{SELECT e'a\\\\'}, 'SELECT 2'], q{E'...' reads two backslashes as one});
  splits_ok(q{SELECT E'it''s \'; x'; SELECT 2},
    [q{SELECT E'it''s \'; x'}, 'SELECT 2'],
    q{a doubled '' does not end an E'...': what follows is still read with backslashes});

  # Without a declared reading the terminators of both count, so a text that
  # is right under either one is never read as fewer statements than it has.
  splits_ok(q{INSERT INTO t VALUES ('it\'s'); SELECT 2},
    [q{INSERT INTO t VALUES ('it\'s')}, 'SELECT 2'],
    q{MySQL form 'it\'s' followed by a statement stays two});
  splits_ok(q{INSERT INTO t VALUES ('C:\'); SELECT 2},
    [q{INSERT INTO t VALUES ('C:\')}, 'SELECT 2'],
    q{standard form 'C:\' followed by a statement stays two});
  splits_ok(q{SELECT "it\"s"; SELECT 2},
    [q{SELECT "it\"s"}, 'SELECT 2'],
    q{MySQL "it\"s" followed by a statement stays two});
  splits_ok(q{CREATE TABLE `a\`b` (id int); SELECT 2},
    [q{CREATE TABLE `a\`b` (id int)}, 'SELECT 2'],
    q{ClickHouse `a\`b` followed by a statement stays two});

  # The same text under each reading, and under both.
  my $sql = q{SELECT 'a\'; b'; SELECT 2};
  is_deeply([_split_statements($sql, { backslash_escapes => 1 })],
    [q{SELECT 'a\'; b'}, 'SELECT 2'],
    q{backslash_escapes => 1: \' is an escaped quote});
  is_deeply([_split_statements($sql, { backslash_escapes => 0 })],
    [q{SELECT 'a\'}, q{b'; SELECT 2}],
    q{backslash_escapes => 0: \ is a character});
  is_deeply([_split_statements($sql)],
    [q{SELECT 'a\'}, q{b'}, 'SELECT 2'],
    'no reading declared: the terminators of both');
  is_deeply([_split_statements($sql, {})],
    [q{SELECT 'a\'}, q{b'}, 'SELECT 2'],
    'an options hash without the key declares nothing');

  is_deeply([_split_statements(q{SELECT 'it\'s'; SELECT 2}, { backslash_escapes => 0 })],
    [q{SELECT 'it\'s'; SELECT 2}],
    q{backslash_escapes => 0 on the MySQL form: the literal never closes});
  is_deeply([_split_statements(q{SELECT 'C:\'; SELECT 2}, { backslash_escapes => 1 })],
    [q{SELECT 'C:\'; SELECT 2}],
    q{backslash_escapes => 1 on the standard form: the literal never closes});
  is_deeply([_split_statements(q{SELECT E'a\'; b'; SELECT 2}, { backslash_escapes => 0 })],
    [q{SELECT E'a\'; b'}, 'SELECT 2'],
    q{E'...' is the backslash reading under backslash_escapes => 0 too});

  # A dollar-quoted body keeps its semicolons against the reading that has
  # lost its place: LIKE ... ESCAPE '\' leaves the backslash reading inside a
  # literal, and it comes out of it in front of the semicolon of 'a;b'.
  splits_ok(
    q{CREATE VIEW v AS SELECT 1 WHERE 'a' LIKE 'a' ESCAPE '\';}
    . "\n" . q{CREATE FUNCTION f() RETURNS text AS $$ SELECT 'a;b' $$ LANGUAGE sql;},
    [ q{CREATE VIEW v AS SELECT 1 WHERE 'a' LIKE 'a' ESCAPE '\'},
      q{CREATE FUNCTION f() RETURNS text AS $$ SELECT 'a;b' $$ LANGUAGE sql} ],
    q{ESCAPE '\' before a $$ body does not cut the body});

  # ... and the same reading takes what stands BETWEEN two bodies for a
  # dollar-quoted string. That must not cost the statement boundary there.
  splits_ok(
    q{SELECT 'C:\' || $fn$ it's; odd $fn$;} . "\n" . q{SELECT 'b' || $fn$ SELECT 'a;b'; $fn$},
    [ q{SELECT 'C:\' || $fn$ it's; odd $fn$}, q{SELECT 'b' || $fn$ SELECT 'a;b'; $fn$} ],
    q{'C:\' before two $fn$ bodies: neither is cut, and they stay two statements});
};

subtest '_split_statements trigger bodies' => sub {
  splits_ok("CREATE TRIGGER tr AFTER INSERT ON t BEGIN UPDATE t SET id = 1; DELETE FROM u; END;",
    ['CREATE TRIGGER tr AFTER INSERT ON t BEGIN UPDATE t SET id = 1; DELETE FROM u; END'],
    'the body of a trigger is one statement');
  splits_ok(
    "CREATE TRIGGER tr AFTER UPDATE ON t BEGIN\n"
    . "  UPDATE t SET n = CASE WHEN NEW.n > 0 THEN 1 ELSE 0 END WHERE id = NEW.id;\n"
    . "  SELECT CASE WHEN NEW.n IS NULL THEN RAISE(ABORT, 'no; n') END;\n"
    . "END;\nCREATE TABLE u (id int);",
    [ "CREATE TRIGGER tr AFTER UPDATE ON t BEGIN\n"
      . "  UPDATE t SET n = CASE WHEN NEW.n > 0 THEN 1 ELSE 0 END WHERE id = NEW.id;\n"
      . "  SELECT CASE WHEN NEW.n IS NULL THEN RAISE(ABORT, 'no; n') END;\n"
      . "END",
      'CREATE TABLE u (id int)' ],
    'SQLite trigger: the END of a CASE does not end the body');
  splits_ok(
    "CREATE TRIGGER tr BEFORE INSERT ON t FOR EACH ROW BEGIN\n"
    . "  IF NEW.n < 0 THEN SET NEW.n = 0; END IF;\n"
    . "  WHILE NEW.n > 9 DO SET NEW.n = NEW.n - 1; END WHILE;\n"
    . "  l: LOOP SET NEW.n = NEW.n + 1; LEAVE l; END LOOP;\n"
    . "  REPEAT SET NEW.n = NEW.n - 1; UNTIL NEW.n < 5 END REPEAT;\n"
    . "  CASE NEW.n WHEN 1 THEN SET NEW.m = 1; ELSE SET NEW.m = 2; END CASE;\n"
    . "  b: BEGIN SET NEW.m = 3; END b;\n"
    . "END;\nCREATE TABLE u (id int);",
    [ "CREATE TRIGGER tr BEFORE INSERT ON t FOR EACH ROW BEGIN\n"
      . "  IF NEW.n < 0 THEN SET NEW.n = 0; END IF;\n"
      . "  WHILE NEW.n > 9 DO SET NEW.n = NEW.n - 1; END WHILE;\n"
      . "  l: LOOP SET NEW.n = NEW.n + 1; LEAVE l; END LOOP;\n"
      . "  REPEAT SET NEW.n = NEW.n - 1; UNTIL NEW.n < 5 END REPEAT;\n"
      . "  CASE NEW.n WHEN 1 THEN SET NEW.m = 1; ELSE SET NEW.m = 2; END CASE;\n"
      . "  b: BEGIN SET NEW.m = 3; END b;\n"
      . "END",
      'CREATE TABLE u (id int)' ],
    'END IF / END WHILE / END LOOP / END REPEAT close nothing, END CASE closes its CASE');
  splits_ok(
    "create trigger tr after insert on t begin update t set e = new.end, b = new.begin, c = new.case; end;\nselect 1",
    [ 'create trigger tr after insert on t begin update t set e = new.end, b = new.begin, c = new.case; end',
      'select 1' ],
    'lower case, and a column named like a keyword is a column');
  splits_ok(
    "-- audit\nCREATE TRIGGER \"begin\" AFTER INSERT ON t BEGIN SELECT 'BEGIN; END'; /* END; */ END;\nSELECT 1",
    [ "CREATE TRIGGER \"begin\" AFTER INSERT ON t BEGIN SELECT 'BEGIN; END'; /* END; */ END", 'SELECT 1' ],
    'BEGIN and END in an identifier, a literal or a comment are not keywords');

  for my $head (
    'CREATE OR REPLACE TRIGGER tr',
    'CREATE OR ALTER TRIGGER tr',
    'CREATE TEMP TRIGGER tr',
    'CREATE TEMPORARY TRIGGER tr',
    'CREATE DEFINER = `root`@`localhost` TRIGGER tr',
    "CREATE DEFINER='admin'\@'%' TRIGGER tr",
    'CREATE DEFINER=CURRENT_USER TRIGGER tr',
    "CREATE\n  TRIGGER IF NOT EXISTS tr",
  ) {
    my $trigger = "$head AFTER INSERT ON t BEGIN DELETE FROM u; END";
    splits_ok("$trigger; SELECT 1", [ $trigger, 'SELECT 1' ], "head: $head");
  }
};

subtest '_split_statements BEGIN outside a trigger is a word' => sub {
  splits_ok("CREATE TABLE t (begin date); CREATE TABLE u (id int);",
    ['CREATE TABLE t (begin date)', 'CREATE TABLE u (id int)'],
    'a column named begin');
  splits_ok("BEGIN; CREATE TABLE t (id int); COMMIT;",
    ['BEGIN', 'CREATE TABLE t (id int)', 'COMMIT'],
    'a transaction script');
  splits_ok("CREATE TABLE triggers (begin date, trigger_name text); SELECT 1",
    ['CREATE TABLE triggers (begin date, trigger_name text)', 'SELECT 1'],
    'TRIGGER elsewhere in a CREATE does not make it a trigger');
  splits_ok("CREATE TRIGGER tr BEFORE INSERT ON t FOR EACH ROW EXECUTE FUNCTION f(); BEGIN; COMMIT;",
    ['CREATE TRIGGER tr BEFORE INSERT ON t FOR EACH ROW EXECUTE FUNCTION f()', 'BEGIN', 'COMMIT'],
    'a trigger without a body ends at its semicolon; the BEGIN after it is a statement');

  # Whether a statement is a trigger is asked of each statement anew.
  my $trigger = 'CREATE TRIGGER tr AFTER INSERT ON t BEGIN DELETE FROM u; END';
  splits_ok("BEGIN; $trigger; COMMIT;", ['BEGIN', $trigger, 'COMMIT'],
    'a trigger inside a transaction script: the BEGIN before it decides nothing');
  splits_ok("$trigger; BEGIN; CREATE TABLE t (id int); COMMIT;",
    [$trigger, 'BEGIN', 'CREATE TABLE t (id int)', 'COMMIT'],
    'a transaction script behind a trigger: its BEGIN opens no block');

  # The limit, pinned: a routine body is NOT read. Its semicolons still cut,
  # as they always did; a routine has to come in $$ quotes or reach the handle
  # whole. Extending the block reading to routines changes this test.
  splits_ok("CREATE PROCEDURE p() BEGIN SELECT 1; END; SELECT 2",
    ['CREATE PROCEDURE p() BEGIN SELECT 1', 'END', 'SELECT 2'],
    'CREATE PROCEDURE: the body is not read as a block');
  splits_ok("CREATE FUNCTION f() RETURNS int BEGIN RETURN 1; END; SELECT 2",
    ['CREATE FUNCTION f() RETURNS int BEGIN RETURN 1', 'END', 'SELECT 2'],
    'CREATE FUNCTION: the body is not read as a block');
};

# --- a bare end/begin as a column, a ; in parentheses (karr k332) ------------
# WHY: a trigger body is cut where its END is, and a column called end or begin
# looks like that END/BEGIN. Read as the keyword, it either cuts the body
# short (end) or never closes it, so the trigger and every statement behind it
# arrive as one (begin). Both are visible only behind a following statement,
# which is why every case ends in one.

subtest '_split_statements a column named end or begin in a trigger body' => sub {
  for my $case (
    [ 'end',   'UPDATE t SET end = 1 WHERE id = NEW.id' ],
    [ 'begin', 'UPDATE t SET begin = 1 WHERE id = NEW.id' ],
    [ 'begin', 'UPDATE t SET begin = 2 WHERE begin = 1' ],
    [ 'end',   'UPDATE t SET a = 1, end = 2, begin = 3 WHERE end > begin' ],
    [ 'end',   'SELECT end, begin FROM t' ],
  ) {
    my ($col, $first) = @$case;
    for my $f (sub { $_[0] }, sub { lc $_[0] }) {
      my $trigger = $f->("CREATE TRIGGER t AFTER UPDATE ON t BEGIN $first; INSERT INTO log (msg) VALUES (1); END");
      my $next    = $f->('CREATE TABLE after (id INTEGER)');
      splits_ok("$trigger; $next;", [ $trigger, $next ], "$col as a column: $first");
    }
  }

  # What still closes: END behind a semicolon, behind the body's BEGIN, a CASE
  # that stands where a column would.
  my $trigger = 'CREATE TRIGGER t AFTER UPDATE ON t BEGIN UPDATE t SET end = CASE WHEN begin = 1 THEN 2 ELSE 3 END; END';
  splits_ok("$trigger; SELECT 1", [ $trigger, 'SELECT 1' ],
    'a CASE inside the body is closed by its END, a column named end is not');
  splits_ok("CREATE TRIGGER t AFTER UPDATE ON t BEGIN END; SELECT 1",
    [ 'CREATE TRIGGER t AFTER UPDATE ON t BEGIN END', 'SELECT 1' ],
    'an END right behind the BEGIN closes it');
  my $nested = "CREATE TRIGGER t BEFORE INSERT ON t FOR EACH ROW BEGIN IF NEW.n < 0 THEN BEGIN SET NEW.end = 0; END; END IF; END";
  splits_ok("$nested; SELECT 1", [ $nested, 'SELECT 1' ],
    'a BEGIN behind THEN opens a level, END behind a semicolon closes it');
};

subtest '_split_statements a semicolon in parentheses' => sub {
  splits_ok(
    'CREATE RULE r AS ON INSERT TO t DO ALSO (INSERT INTO a VALUES (1); INSERT INTO b VALUES (2)); SELECT 1',
    [ 'CREATE RULE r AS ON INSERT TO t DO ALSO (INSERT INTO a VALUES (1); INSERT INTO b VALUES (2))', 'SELECT 1' ],
    'a rule\'s command list in parentheses is one statement');
  splits_ok("CREATE RULE r AS ON INSERT TO t DO ALSO (SELECT '(' ; SELECT ')'); SELECT 1",
    [ "CREATE RULE r AS ON INSERT TO t DO ALSO (SELECT '(' ; SELECT ')')", 'SELECT 1' ],
    'a parenthesis in a literal counts for nothing');  splits_ok('SELECT 1); SELECT 2; SELECT 3',
    [ 'SELECT 1)', 'SELECT 2', 'SELECT 3' ],
    'a stray ) does not take the depth below zero');
  splits_ok("CREATE TRIGGER tr AFTER INSERT ON t BEGIN INSERT INTO u VALUES (1); DELETE FROM v; END; SELECT 1",
    [ 'CREATE TRIGGER tr AFTER INSERT ON t BEGIN INSERT INTO u VALUES (1); DELETE FROM v; END', 'SELECT 1' ],
    'the semicolons of a trigger body are still not cuts, parentheses or not');
};

# The backslash is where the dialects part. A literal that ends on one --
# 'C:\' -- is complete under the standard reading and unfinished under
# MySQL's, where \' is an escaped quote. The text cannot say which one it is
# written in, so the caller that knows its engine names it.
subtest '_split_statements dialect' => sub {
  my $text = q{SELECT 'C:\'; SELECT 'a;b'; SELECT 3};
  my @standard = (
    q{SELECT 'C:\'},
    q{SELECT 'a;b'},
    'SELECT 3',
  );

  # The documented limit: with no dialect both readings are taken, and the
  # semicolon of 'a;b' ends a statement under the MySQL one.
  isnt join("\0", _split_statements($text)), join("\0", @standard),
    'no dialect: both readings are taken, the documented limit stays';

  is_deeply([_split_statements($text, { dialect => $_ })], \@standard,
    "dialect $_ reads the backslash as a character")
    for qw(postgresql sqlite);

  my $mysql = q{SELECT 'it\'s;'; SELECT 2};
  is_deeply([_split_statements($mysql, { dialect => 'mysql' })],
    [ q{SELECT 'it\'s;'}, 'SELECT 2' ],
    q{dialect mysql reads \' as an escaped quote: one literal});
  is((_split_statements($mysql, { dialect => 'postgresql' }))[0],
    q{SELECT 'it\'s},
    'dialect postgresql ends the literal at the backslash-quote');

  is_deeply(
    [_split_statements($mysql, { dialect => 'postgresql', backslash_escapes => 1 })],
    [ q{SELECT 'it\'s;'}, 'SELECT 2' ],
    'an explicit backslash_escapes wins over the dialect');
  is_deeply(
    [_split_statements($text, { dialect => 'mysql', backslash_escapes => 0 })],
    \@standard,
    '... in the other direction as well');

  is_deeply([_split_statements($text, { dialect => undef })],
    [_split_statements($text)], 'an undef dialect is no dialect');

  eval { _split_statements('SELECT 1', { dialect => 'oracel' }) };
  like $@, qr/unknown SQL dialect 'oracel'.*mysql.*postgresql.*sqlite/s,
    'an unknown dialect throws, naming the ones there are';
};

# WHY: PostgreSQL 14+ writes a routine body as a list of statements between
# BEGIN ATOMIC and END, no dollar quote. The semicolons between them end
# nothing -- cutting there hands the engine half a function. Only PostgreSQL
# says so; for any other reading BEGIN ATOMIC stays a word like any other,
# and that default is held here as the documented limit.
subtest '_split_statements BEGIN ATOMIC (postgresql)' => sub {
  my $fn = "CREATE FUNCTION f(a int) RETURNS int LANGUAGE sql\n"
         . "BEGIN ATOMIC\n  SELECT a + 1;\n  SELECT (CASE WHEN a > 0 THEN 1 ELSE 2 END);\nEND";
  my %pg = (dialect => 'postgresql');

  is_deeply([_split_statements("$fn; SELECT 9", \%pg)], [ $fn, 'SELECT 9' ],
    'the semicolons in a BEGIN ATOMIC body end nothing; END closes at ;');
  is_deeply([_split_statements("$fn;\n", \%pg)], [$fn], 'END before the final ;');
  is_deeply([_split_statements($fn, \%pg)], [$fn], 'END at the end of the text');

  my $or = "CREATE OR REPLACE PROCEDURE p() LANGUAGE sql BEGIN ATOMIC INSERT INTO t VALUES (1); "
         . "INSERT INTO t VALUES ('x;y'); /* a; b */ -- c; d\nEND";
  is_deeply(
    [_split_statements("SELECT 1; $or; CREATE TABLE u (id int); $fn; SELECT 2", \%pg)],
    [ 'SELECT 1', $or, 'CREATE TABLE u (id int)', $fn, 'SELECT 2' ],
    'several statements around two routines; literals and comments in the body');

  my $empty = 'CREATE FUNCTION g() RETURNS void LANGUAGE sql BEGIN ATOMIC END';
  is_deeply([_split_statements("$empty; SELECT 1", \%pg)], [ $empty, 'SELECT 1' ],
    'END directly behind BEGIN ATOMIC');

  my $dq = 'CREATE FUNCTION h() RETURNS int LANGUAGE sql AS $$ SELECT 1; SELECT 2 $$';
  is_deeply([_split_statements("$dq; SELECT 3", \%pg)], [ $dq, 'SELECT 3' ],
    'a dollar-quoted function is untouched');

  my $col = 'SELECT begin, atomic FROM t';
  is_deeply([_split_statements("$col; SELECT 1", \%pg)], [ $col, 'SELECT 1' ],
    'begin as a column stays a column');

  # The documented limit: no dialect, or another one, takes BEGIN ATOMIC as a word.
  for my $opt ({}, { dialect => 'sqlite' }, { dialect => 'mysql' }) {
    my @got = _split_statements("$fn; SELECT 9", $opt);
    isnt scalar(@got), 2, 'without the postgresql dialect the body is cut at its semicolons'
      or diag explain \@got;
  }
};

# WHY: PostgreSQL nests /* ... */, so a semicolon in /* a /* b; */ c; */ is
# still inside the comment. The other engines close at the first */ and the
# rest is code. The comment in front of a statement is taken off by the same
# reading, or a remainder "c; */" would stay behind as a statement.
subtest '_split_statements nested comments (postgresql)' => sub {
  my $nest = '/* a /* b; */ c; */';
  my %pg = (dialect => 'postgresql');

  is_deeply([_split_statements("SELECT 1 $nest + 2; SELECT 3", \%pg)],
    [ "SELECT 1 $nest + 2", 'SELECT 3' ], 'nested comment inside a statement');
  is_deeply([_split_statements("$nest SELECT 1; SELECT 2", \%pg)],
    [ 'SELECT 1', 'SELECT 2' ], 'nested comment in front of a statement is taken off');
  is_deeply([_split_statements("SELECT 1; $nest", \%pg)], ['SELECT 1'],
    'a piece of nothing but a nested comment is no statement');
  is_deeply([_split_statements("SELECT 1; /* a /* b */ c; */ -- x\n SELECT 2", \%pg)],
    [ 'SELECT 1', 'SELECT 2' ], 'comments in a row in front');
  is_deeply([_split_statements("SELECT 1; /* never /* closed; SELECT 2", \%pg)],
    ['SELECT 1'], 'a comment never closed runs to the end');
  is_deeply([_split_statements("SELECT 1; /* a /* b */ c; SELECT 2", \%pg)],
    ['SELECT 1'], 'one level closed leaves the outer one open');

  # The documented limit: the other reading closes at the first */.
  for my $opt ({}, { dialect => 'sqlite' }, { dialect => 'mysql' }) {
    is_deeply([_split_statements("$nest SELECT 1", $opt)], [ 'c', '*/ SELECT 1' ],
      'without the postgresql dialect the first */ closes');
  }
};

done_testing;