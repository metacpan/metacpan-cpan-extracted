use strict;
use warnings;

use Test::More;
use DBIO::SQL::Util '_split_statements';

# Dialect oracle: a PL/SQL unit is ONE statement, from its CREATE (or its
# DECLARE / BEGIN) to the semicolon behind the END of its outermost level,
# and that semicolon stays -- Oracle needs it behind END. Everything else
# loses its semicolon as in every dialect.

my %ora = (dialect => 'oracle');
sub split_ora { [ _split_statements($_[0], \%ora) ] }

subtest 'function: the inner semicolons end nothing, the last one stays' => sub {
  my $fn = "CREATE OR REPLACE FUNCTION f RETURN NUMBER IS x NUMBER;\n"
         . "BEGIN x := 1; RETURN x; END;";
  is_deeply split_ora($fn), [$fn], 'one statement with its closing semicolon';
  is_deeply split_ora("$fn\n"), [$fn], 'trailing whitespace is not part of it';
  my $named = "CREATE FUNCTION g RETURN NUMBER AS BEGIN RETURN 1; END g;";
  is_deeply split_ora($named), [$named], 'END name; closes with the name';
  my $ed = "CREATE OR REPLACE EDITIONABLE FUNCTION h RETURN NUMBER IS BEGIN RETURN 1; END;";
  is_deeply split_ora($ed), [$ed], 'EDITIONABLE is part of the head';
  my $ned = "CREATE NONEDITIONABLE PROCEDURE p IS BEGIN NULL; END;";
  is_deeply split_ora($ned), [$ned], 'NONEDITIONABLE is part of the head';
};

subtest 'procedure' => sub {
  my $p = "CREATE OR REPLACE PROCEDURE p (a IN NUMBER, b OUT NUMBER) AS\n"
        . "  c NUMBER := 2;\nBEGIN\n  b := a * c;\nEND p;";
  is_deeply split_ora("$p\nSELECT 1 FROM dual;"), [ $p, 'SELECT 1 FROM dual' ],
    'the procedure is one statement, the following one is ordinary';
};

subtest 'package specification and body' => sub {
  my $spec = "CREATE OR REPLACE PACKAGE pk AS\n"
           . "  PROCEDURE a;\n  FUNCTION b(x NUMBER) RETURN NUMBER;\n"
           . "  c CONSTANT NUMBER := 1;\nEND pk;";
  is_deeply split_ora($spec), [$spec],
    'forward declarations (PROCEDURE a;) open no level';

  my $body = "CREATE OR REPLACE PACKAGE BODY pk AS\n"
           . "  PROCEDURE a IS BEGIN NULL; END a;\n"
           . "  FUNCTION b(x NUMBER) RETURN NUMBER IS\n"
           . "    FUNCTION inner_f RETURN NUMBER IS BEGIN RETURN 1; END;\n"
           . "  BEGIN RETURN x + inner_f; END b;\n"
           . "END pk;";
  is_deeply split_ora("$spec\n$body\nDROP TABLE t"), [ $spec, $body, 'DROP TABLE t' ],
    'a body with nested subprograms is one statement';

  my $init = "CREATE PACKAGE BODY pk2 AS\n  v NUMBER;\n"
           . "  PROCEDURE a IS BEGIN NULL; END;\n"
           . "BEGIN v := 1; END pk2;";
  is_deeply split_ora($init), [$init],
    'the BEGIN of the initialisation part belongs to the package level';
};

subtest 'type body' => sub {
  my $tb = "CREATE OR REPLACE TYPE BODY t AS\n"
         . "  MEMBER FUNCTION m RETURN NUMBER IS BEGIN RETURN 1; END;\n"
         . "  CONSTRUCTOR FUNCTION t RETURN SELF AS RESULT IS BEGIN RETURN; END;\n"
         . "END;";
  is_deeply split_ora($tb), [$tb], 'members open levels, AS RESULT opens none';

  my $plain = "CREATE TYPE t AS OBJECT (a NUMBER, MEMBER FUNCTION m RETURN NUMBER)";
  is_deeply split_ora("$plain;\nSELECT 1 FROM dual"), [ $plain, 'SELECT 1 FROM dual' ],
    'a type specification is an ordinary statement and loses its semicolon';
};

subtest 'trigger keeps its semicolon' => sub {
  my $t = "CREATE OR REPLACE TRIGGER trg BEFORE INSERT ON t FOR EACH ROW\n"
        . "BEGIN :new.id := 1; :new.x := 2; END;";
  is_deeply split_ora($t), [$t], 'trigger with BEGIN';
  my $d = "CREATE TRIGGER trg2 BEFORE UPDATE OF begin_at, end_at ON t FOR EACH ROW\n"
        . "DECLARE v NUMBER; BEGIN v := 1; END;";
  is_deeply split_ora($d), [$d], 'trigger with DECLARE, columns named begin_at / end_at';
};

subtest 'compound trigger: sections close only themselves' => sub {
  my $c = "CREATE OR REPLACE TRIGGER ct\n"
        . "FOR INSERT OR UPDATE ON t COMPOUND TRIGGER\n"
        . "  v NUMBER := 0;\n"
        . "  PROCEDURE bump IS BEGIN v := v + 1; END bump;\n"
        . "  FUNCTION fwd RETURN NUMBER;\n"
        . "  BEFORE STATEMENT IS BEGIN v := 0; END BEFORE STATEMENT;\n"
        . "  BEFORE EACH ROW IS BEGIN bump; IF v > 1 THEN NULL; END IF; END BEFORE EACH ROW;\n"
        . "  AFTER EACH ROW IS BEGIN NULL; END AFTER EACH ROW;\n"
        . "  AFTER STATEMENT IS x NUMBER; BEGIN x := v; END AFTER STATEMENT;\n"
        . "END ct;";
  is_deeply split_ora("$c\nSELECT 1 FROM dual;"), [ $c, 'SELECT 1 FROM dual' ],
    'one unit; END <section>; ends the section, END name; the unit';

  my $i = "CREATE TRIGGER v_ct FOR INSERT ON vw COMPOUND TRIGGER\n"
        . "  INSTEAD OF EACH ROW IS BEGIN NULL; END INSTEAD OF EACH ROW;\n"
        . "END;";
  is_deeply split_ora("$i\n/\n$i"), [ $i, $i ], 'INSTEAD OF EACH ROW, unnamed END, / line';

  eval { _split_statements("CREATE TRIGGER t FOR INSERT ON x COMPOUND TRIGGER\n"
    . "BEFORE STATEMENT IS BEGIN NULL; END BEFORE STATEMENT;", \%ora) };
  like $@, qr/PL\/SQL block is not closed/, 'the sections closed, the unit not: refused';
};

subtest 'anonymous block' => sub {
  my $decl = "DECLARE n NUMBER; BEGIN n := 2; END;";
  is_deeply split_ora($decl), [$decl], 'DECLARE ... BEGIN ... END;';
  my $begin = "BEGIN NULL; NULL; END;";
  is_deeply split_ora($begin), [$begin], 'BEGIN ... END;';
  my $nested = "BEGIN BEGIN NULL; END; DECLARE x NUMBER; BEGIN x := 1; END; END;";
  is_deeply split_ora($nested), [$nested], 'nested blocks, with and without DECLARE';
  is_deeply split_ora("select 1 from dual; $begin select 2 from dual;"),
    [ 'select 1 from dual', $begin, 'select 2 from dual' ],
    'a block between ordinary statements';
};

subtest 'END IF / END LOOP / END CASE and CASE expressions' => sub {
  my $b = "CREATE PROCEDURE p IS\n  n NUMBER := 0;\nBEGIN\n"
        . "  IF n = 0 THEN n := 1; ELSE n := 2; END IF;\n"
        . "  FOR i IN 1 .. 3 LOOP n := n + i; END LOOP;\n"
        . "  WHILE n < 10 LOOP n := n + 1; END LOOP lbl;\n"
        . "  CASE n WHEN 1 THEN n := 5; ELSE n := 6; END CASE;\n"
        . "  n := CASE WHEN n > 1 THEN 1 ELSE 0 END;\n"
        . "  IF n = 1 THEN\n    CASE WHEN n = 1 THEN NULL; END CASE;\n  END IF;\n"
        . "END;";
  is_deeply split_ora("$b\nSELECT 1 FROM dual;"), [ $b, 'SELECT 1 FROM dual' ],
    'the construct ends close their own level, the block closes at its END';

  my $cur = "CREATE PACKAGE pk AS\n"
          . "  CURSOR c IS SELECT CASE WHEN a = 1 THEN 'x' ELSE 'y' END v FROM t;\n"
          . "END;";
  is_deeply split_ora($cur), [$cur], 'a CASE expression in a declaration part';
};

subtest 'a column named end or begin is no block boundary' => sub {
  my $b = "BEGIN SELECT t.end, t.begin INTO a, b FROM t WHERE t.end = 1; END;";
  is_deeply split_ora($b), [$b], 'behind a dot';
  my $c = "BEGIN SELECT end INTO a FROM t; UPDATE t SET end = 1; END;";
  is_deeply split_ora($c), [$c], 'end where no statement ends is a column';
};

subtest 'literals and comments in the body' => sub {
  my $b = "BEGIN\n"
        . "  x := 'a; END; b';\n"
        . "  y := q'[c; END; ']';\n"
        . "  z := \"odd; END;\";\n"
        . "  -- comment; END;\n"
        . "  /* block; END; */\n"
        . "  NULL;\nEND;";
  is_deeply split_ora($b), [$b], 'semicolons and ENDs inside them end nothing';

  my $bs = "BEGIN x := 'a\\'; NULL; END;";
  is_deeply split_ora($bs), [$bs], 'a backslash is a character: the quote closes';
  is_deeply split_ora("SELECT 'a\\'; SELECT 2"), [ "SELECT 'a\\'", 'SELECT 2' ],
    'the same outside a unit';
  my $nc = "BEGIN /* a /* b */ NULL; END;";
  is_deeply split_ora($nc), [$nc], 'block comments do not nest: the first */ closes';
};

subtest 'a line of / ends a statement and is not sent' => sub {
  my $p = "CREATE PROCEDURE p IS BEGIN NULL; END;";
  is_deeply split_ora("$p\n/\nSELECT 1 FROM dual\n/\n"), [ $p, 'SELECT 1 FROM dual' ],
    'behind a unit, and behind an ordinary statement without a semicolon';
  is_deeply split_ora("$p\n  /  \n$p\n/"), [ $p, $p ], 'whitespace around the slash';
  is_deeply split_ora("SELECT 4 / 2 FROM dual;\nSELECT\n  4\n  / 2 FROM dual"),
    [ 'SELECT 4 / 2 FROM dual', "SELECT\n  4\n  / 2 FROM dual" ],
    'a division is no slash line';
};

subtest 'several units and ordinary statements in a row' => sub {
  my $f = "CREATE FUNCTION f RETURN NUMBER IS BEGIN RETURN 1; END;";
  my $t = "CREATE TRIGGER tr BEFORE INSERT ON t FOR EACH ROW BEGIN NULL; END;";
  my $a = "BEGIN NULL; END;";
  is_deeply split_ora("CREATE TABLE t (id NUMBER);\n$f\nINSERT INTO t VALUES (1);\n$t\n$a\nCOMMIT;"),
    [ 'CREATE TABLE t (id NUMBER)', $f, 'INSERT INTO t VALUES (1)', $t, $a, 'COMMIT' ],
    'units keep their semicolon, the others lose it';
  is_deeply split_ora("-- lead\n$f"), [$f], 'a comment in front of a unit is taken off';
};

subtest 'an incomplete block is refused' => sub {
  for my $text (
    "CREATE FUNCTION f RETURN NUMBER IS BEGIN RETURN 1;",
    "BEGIN NULL;",
    "DECLARE x NUMBER; BEGIN IF x = 1 THEN NULL; END IF;",
    "CREATE TRIGGER t BEFORE INSERT ON x FOR EACH ROW BEGIN NULL;",
    "SELECT 1 FROM dual;\nBEGIN NULL;\n/\n",
  ) {
    eval { _split_statements($text, \%ora) };
    like $@, qr/PL\/SQL block is not closed/, "refused: " . ($text =~ s/\n/ /gr);
  }
};

subtest 'the other dialects read PL/SQL as before' => sub {
  my $fn = "CREATE FUNCTION f RETURN NUMBER IS BEGIN RETURN 1; END;";
  for my $d (qw(sqlite mysql)) {
    is_deeply [ _split_statements("$fn\n/\nSELECT 1", { dialect => $d }) ],
      [ 'CREATE FUNCTION f RETURN NUMBER IS BEGIN RETURN 1', 'END', "/\nSELECT 1" ],
      "$d: a function is cut at every semicolon";
  }
};

done_testing;
