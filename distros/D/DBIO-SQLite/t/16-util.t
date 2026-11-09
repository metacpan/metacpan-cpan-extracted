use strict;
use warnings;
use Test::More;

use DBIO::SQLite::Util qw(
  column_is_nullable create_table_name_index default_literal_sql
  pk_is_rowid_alias quote_identifier sql_tokens token_identifier type_affinity
);

# column_is_nullable is the driver's single rule for SQLite column nullability
# (karr k29). The first two arguments are what PRAGMA table_info reports; the
# third says whether a key column is the INTEGER PRIMARY KEY rowid alias, which
# is the only key on this engine that cannot hold NULL. t/39 proves each of
# these answers against a real database -- this file pins the rule in isolation.

is(column_is_nullable(0, 0, 0), 1, 'plain column, no NOT NULL: nullable');
is(column_is_nullable(1, 0, 0), 0, 'declared NOT NULL: not nullable');

# A key column with no NOT NULL attribute: the alias flag decides, and it is
# the whole point of the third argument. Reporting the first case as 0 would be
# reporting NOT NULL for a column SQLite lets hold NULL.
is(column_is_nullable(0, 1, 0), 1,
  'PRIMARY KEY that is not the rowid alias: nullable, because SQLite stores NULL there');
is(column_is_nullable(0, 1, 1), 0,
  'INTEGER PRIMARY KEY rowid alias: not nullable, NULL is only the "assign a rowid" token');

# NOT NULL always wins -- that is the engine's own constraint, whatever the key
# shape is. WITHOUT ROWID reaches us this way (PRAGMA reports notnull=1).
is(column_is_nullable(1, 1, 0), 0, 'NOT NULL + non-alias key: not nullable');
is(column_is_nullable(1, 1, 1), 0, 'NOT NULL + rowid alias: not nullable');

# Omitting the alias flag answers "nullable". Of the two possible guesses only
# 0 can do damage: it generates a schema that refuses rows the database holds,
# while 1 leaves the engine's own constraint to reject a bad INSERT.
is(column_is_nullable(0, 1), 1, 'unknown key shape falls to the harmless guess');

SKIP: {
  eval { require DBD::SQLite; require DBI; 1 }
    or skip 'DBD::SQLite required', 4;

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
  $dbh->do('CREATE TABLE alias_pk (id INTEGER PRIMARY KEY)');
  $dbh->do('CREATE TABLE text_pk  (name TEXT PRIMARY KEY)');
  $dbh->do('CREATE TABLE no_pk    (name TEXT)');

  is(pk_is_rowid_alias($dbh, 'alias_pk'), 1, 'INTEGER PRIMARY KEY is the rowid alias');
  is(pk_is_rowid_alias($dbh, 'text_pk'),  0, 'TEXT PRIMARY KEY is a real index, not the alias');
  is(pk_is_rowid_alias($dbh, 'no_pk'),    1, 'keyless table reads as alias (never consulted)');

  # No fact available: fall back to the DBIO::Introspect::Base answer rather
  # than invent a new one.
  is(pk_is_rowid_alias($dbh, 'does_not_exist'), 1, 'unavailable PRAGMA falls back to alias');

  # The table is named to the PRAGMA through quote_identifier, so a name that
  # needs its quotes -- a reserved word, one with a double quote in it -- is
  # asked about like any other.
  $dbh->do('CREATE TABLE "order" (name TEXT PRIMARY KEY)');
  $dbh->do('CREATE TABLE "a""b"  (name TEXT PRIMARY KEY)');
  $dbh->do('CREATE TABLE "c""d"  (id INTEGER PRIMARY KEY)');
  is(pk_is_rowid_alias($dbh, 'order'), 0, 'a table named by a reserved word');
  is(pk_is_rowid_alias($dbh, 'a"b'),   0, 'a table with a double quote in its name: a real key');
  is(pk_is_rowid_alias($dbh, 'c"d'),   1, 'and one whose key is the alias');
}

# quote_identifier is the one quoter of the driver (karr k57): always in double
# quotes, a double quote inside doubled. Always, because a reserved word has
# the shape of any other name -- a quoter that leaves "simple" names bare
# writes CREATE TABLE order, which is a syntax error.
for my $case (
  [ 'item'       => '"item"'       ],
  [ 'order'      => '"order"'      ],   # reserved, and shaped like item
  [ 'MixedCase'  => '"MixedCase"'  ],
  [ 'my table'   => '"my table"'   ],
  [ 'a"b'        => '"a""b"'       ],
  [ '"'          => '""""'         ],
  [ q{it's}      => q{"it's"}      ],   # an apostrophe needs nothing
  [ 'a.b'        => '"a.b"'        ],   # one name with a dot, not schema.table
  [ '1st'        => '"1st"'        ],
  [ ''           => '""'           ],
) {
  my ($name, $sql) = @$case;
  is(quote_identifier($name), $sql, "quote_identifier: <$name> is $sql");
}

{
  my $name = 'a"b';
  quote_identifier($name);
  is($name, 'a"b', 'quote_identifier leaves its argument alone');
}

# sql_tokens is the one lexer for a statement SQLite stored. What its callers
# rely on: the tokens joined are the statement again; whatever is in quotes is
# one token, with its commas, parentheses and keywords; a comment is skipped.
{
  my $sql = qq{CREATE TABLE "a""b" (\n  [x y] INT, -- a, comment (\n}
    . q{  `c``d` TEXT DEFAULT 'it''s, (1)' /* ) */ CHECK (n>-1)} . "\n)";
  my @tokens = sql_tokens($sql);

  is(join('', map { $_->[1] } @tokens), $sql,
    'sql_tokens: the texts joined are the statement, character for character');

  is_deeply(
    [ grep { $_->[0] ne 'skip' } @tokens ],
    [
      [ word   => 'CREATE' ], [ word => 'TABLE' ], [ quoted => '"a""b"' ],
      [ punct  => '(' ],
      [ quoted => '[x y]' ], [ word => 'INT' ], [ punct => ',' ],
      [ quoted => '`c``d`' ], [ word => 'TEXT' ], [ word => 'DEFAULT' ],
      [ quoted => q{'it''s, (1)'} ],
      [ word   => 'CHECK' ], [ punct => '(' ], [ word => 'n>' ], [ word => '-' ],
      [ word   => '1' ], [ punct => ')' ],
      [ punct  => ')' ],
    ],
    'sql_tokens: quoted, punct and word; comments and whitespace are skip',
  );

  my %skipped = map { $_->[1] => 1 } grep { $_->[0] eq 'skip' } @tokens;
  ok($skipped{" -- a, comment (\n  "} && $skipped{' /* ) */ '},
    'sql_tokens: a run of whitespace and comments is one skip token');

  is_deeply([ sql_tokens('') ], [], 'sql_tokens: no text, no tokens');
}

# token_identifier: the name a token stands for. The four quotings SQLite
# takes for a name are one name; the doubled quote character is one again.
for my $case (
  [ word   => 'item',       'item'  ],
  [ quoted => '"item"',     'item'  ],
  [ quoted => '`item`',     'item'  ],
  [ quoted => '[item]',     'item'  ],
  [ quoted => q{'item'},    'item'  ],
  [ quoted => '"a""b"',     'a"b'   ],
  [ quoted => '`a``b`',     'a`b'   ],
  [ quoted => q{'it''s'},   q{it's} ],
  [ quoted => '[a"b]',      'a"b'   ],
  [ quoted => '"a`b"',      'a`b'   ],
  [ quoted => '"my table"', 'my table' ],
  [ quoted => '""""',       '"'     ],
) {
  my ($kind, $text, $name) = @$case;
  is(token_identifier($kind, $text), $name, "token_identifier: $text is <$name>");
}

# A name through the quoter and back through the lexer is the name.
for my $name ('item', 'order', 'my table', 'a"b', '"', 'a""b', q{it's}, 'x(y),z') {
  my @tokens = sql_tokens(quote_identifier($name));
  is(scalar @tokens, 1, "<$name> quoted is one token");
  is(token_identifier(@{ $tokens[0] }), $name, "and reads back as <$name>");
}

# create_table_name_index: where the table's name stands in a CREATE TABLE.
for my $case (
  [ 'CREATE TABLE item (id INTEGER)'              => 'item'      ],
  [ 'CREATE TABLE item(id INTEGER)'               => 'item'      ],
  [ 'CREATE TABLE "item" (id INTEGER)'            => 'item'      ],
  [ 'CREATE TABLE "a""b" (id INTEGER)'            => 'a"b'       ],
  [ 'CREATE TABLE "my table"(id INTEGER)'         => 'my table'  ],
  [ 'CREATE TABLE `item` (id INTEGER)'            => 'item'      ],
  [ 'CREATE TABLE [item] (id INTEGER)'            => 'item'      ],
  [ "  create\n table /* c */ item (id INTEGER)"  => 'item'      ],
  [ 'CREATE TABLE IF NOT EXISTS item (id INTEGER)' => 'item'     ],
  [ 'CREATE TABLE key (id INTEGER)'               => 'key'       ],   # a keyword SQLite takes bare
  [ 'CREATE TABLE "table" (id INTEGER)'           => 'table'     ],
  [ 'CREATE TABLE main.item (id INTEGER)'         => 'main.item' ],
  [ 'CREATE VIEW v AS SELECT 1'                   => undef       ],
  [ 'CREATE VIRTUAL TABLE f USING fts5(body)'     => undef       ],
  [ 'CREATE TABLE'                                => undef       ],
  [ 'CREATE TABLE (id INTEGER)'                   => undef       ],
  [ ''                                            => undef       ],
) {
  my ($sql, $name) = @$case;
  my @tokens = sql_tokens($sql);
  my $at     = create_table_name_index(\@tokens);
  (my $shown = $sql) =~ s/\s+/ /g;
  is(defined $at ? token_identifier(@{ $tokens[$at] }) : undef, $name,
    "create_table_name_index: <$shown> names " . ($name // 'no table'));
}

# type_affinity is SQLite's rule for the affinity of a declared type
# (https://sqlite.org/datatype3.html, 3.1): five tests on the type's text, in
# this order, the first that matches decides. The order is the rule -- CHARINT
# holds CHAR and is INTEGER, because INT is asked first.
my @AFFINITY = (
  [ 'INTEGER'              => 'INTEGER' ],
  [ 'INT'                  => 'INTEGER' ],
  [ 'BIGINT'               => 'INTEGER' ],
  [ 'int'                  => 'INTEGER' ],
  [ 'CHARINT'              => 'INTEGER' ],   # INT before CHAR
  [ 'POINT'                => 'INTEGER' ],   # anywhere in the name
  [ 'TEXT'                 => 'TEXT'    ],
  [ 'text'                 => 'TEXT'    ],
  [ 'VARCHAR(10)'          => 'TEXT'    ],
  [ 'VARCHAR'              => 'TEXT'    ],
  [ 'CHAR(3)'              => 'TEXT'    ],
  [ 'CHARACTER VARYING(5)' => 'TEXT'    ],
  [ 'NVARCHAR(20)'         => 'TEXT'    ],
  [ 'CLOB'                 => 'TEXT'    ],
  [ 'MEDIUMTEXT'           => 'TEXT'    ],
  [ 'BLOB'                 => 'BLOB'    ],
  [ ''                     => 'BLOB'    ],   # no declared type
  [ 'REAL'                 => 'REAL'    ],
  [ 'DOUBLE PRECISION'     => 'REAL'    ],
  [ 'FLOAT'                => 'REAL'    ],
  [ 'NUMERIC'              => 'NUMERIC' ],
  [ 'NUMERIC(10,2)'        => 'NUMERIC' ],
  [ 'DECIMAL'              => 'NUMERIC' ],
  [ 'BOOLEAN'              => 'NUMERIC' ],
  [ 'DATE'                 => 'NUMERIC' ],
  [ 'DATETIME'             => 'NUMERIC' ],
  [ 'STRING'               => 'NUMERIC' ],   # none of the five words
);

for my $case (@AFFINITY) {
  my ($type, $affinity) = @$case;
  is(type_affinity($type), $affinity, "type_affinity: <$type> is $affinity");
}
is(type_affinity(undef), 'BLOB', 'type_affinity: no type at all is BLOB, like the empty one');

# The same list against SQLite itself. A column does not say which affinity it
# has, it shows it: the text '007' and the integer 7 are stored, and typeof()
# of the two answers. INTEGER and NUMERIC store alike -- SQLite tells them
# apart in a CAST only -- so those two share a line here.
SKIP: {
  eval { require DBD::SQLite; require DBI; 1 }
    or skip 'DBD::SQLite required', scalar @AFFINITY;

  my %stores = (
    TEXT    => 'text text',
    BLOB    => 'text integer',
    REAL    => 'real real',
    INTEGER => 'integer integer',
    NUMERIC => 'integer integer',
  );

  my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1 });
  my $n = 0;
  for my $case (@AFFINITY) {
    my ($type, $affinity) = @$case;
    my $table = 'aff' . ++$n;
    $dbh->do("CREATE TABLE $table (c $type)");
    $dbh->do("INSERT INTO $table (c) VALUES ('007'), (7)");
    my $stored = join ' ', @{ $dbh->selectcol_arrayref(
      "SELECT typeof(c) FROM $table ORDER BY rowid") };
    is($stored, $stores{$affinity}, "SQLite stores into <$type> as $affinity affinity does");
  }
}

# default_literal_sql is where a plain default_value becomes SQL (karr k57,
# karr k68): install_ddl writes its answer and target_from_compiled puts the
# same answer into its model. t/50 and t/47 run these through a database; this
# pins the rule. A number in its canonical form -- sign, digits without leading
# zeros, a fraction without trailing zeros, nothing more -- is bare.
# Everything else is a string literal with its apostrophes doubled, whatever
# SQLite might have made of it bare.
#
# That is the rule for a column that does not have TEXT affinity, and for a
# call that names no type: what kind of value a Perl scalar holds cannot be
# seen from the scalar, so the cases are the same with any such type behind
# them.
for my $type (undef, 'INTEGER', 'NUMERIC(10,2)', 'REAL', 'BLOB', 'DATE', 'CHARINT', '') {
  my $named = defined $type ? "<$type>" : 'no type';
  for my $case (
    [ 5        => q{5}        ],
    [ 0        => q{0}        ],
    [ -1       => q{-1}       ],
    [ '1.5'    => q{1.5}      ],
    [ '10'     => q{10}       ],
    [ '1.50'   => q{'1.50'}   ],
    [ '007'    => q{'007'}    ],
    [ '-007'   => q{'-007'}   ],
    [ 'abc'    => q{'abc'}    ],
    [ ''       => q{''}       ],
    [ q{it's}  => q{'it''s'}  ],
    [ q{a''b}  => q{'a''''b'} ],
    [ q{'}     => q{''''}     ],
    [ '1e3'    => q{'1e3'}    ],
    [ '.5'     => q{'.5'}     ],
    [ '+1'     => q{'+1'}     ],
    [ '0x10'   => q{'0x10'}   ],
    [ "5\n"    => qq{'5\n'}   ],
    [ 'NULL'   => q{'NULL'}   ],
  ) {
    my ($value, $sql) = @$case;
    (my $label = $value) =~ s/\n/\\n/g;
    is(default_literal_sql($value, $type), $sql,
      "default_literal_sql, $named: <$label> is $sql");
  }
}

# A column with TEXT affinity holds strings, and its default is one: always a
# literal in apostrophes, also when it looks like a number. Bare, SQLite reads
# 007 as the number 7 and the column's affinity makes the text '7' of it -- the
# declared '007' never arrives (t/50 shows that on a row).
for my $type ('TEXT', 'VARCHAR(10)', 'CHAR(3)', 'varchar', 'CLOB', 'CHARACTER VARYING(5)') {
  for my $case (
    [ '007'    => q{'007'}    ],
    [ 5        => q{'5'}      ],
    [ 0        => q{'0'}      ],
    [ 10       => q{'10'}     ],
    [ -5       => q{'-5'}     ],
    [ '1.50'   => q{'1.50'}   ],
    [ 'abc'    => q{'abc'}    ],
    [ q{it's}  => q{'it''s'}  ],
    [ '1e3'    => q{'1e3'}    ],
    [ ''       => q{''}       ],
  ) {
    my ($value, $sql) = @$case;
    is(default_literal_sql($value, $type), $sql,
      "default_literal_sql, <$type>: <$value> is $sql");
  }
}

done_testing;
