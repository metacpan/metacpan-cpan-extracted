#!/usr/bin/env perl
# t/71-error-values-masked.t -- the engine's error text names no value that
# came in as a bind.
#
# WHY this matters: DuckDB writes the offending value into its error text
# ("Could not convert string 'x' to INT32", "Duplicate key "email: x" ..."),
# also when the value was a bind. DBIO's rule for the family is that an error
# message names keys, columns and options, never values, and the engine's text
# is the driver's to keep to it (mask_error_details). So each form here binds a
# marker, and the exception must not contain it, while the type, column,
# constraint and table the caller needs to find the cause, the
# "with N bind values" of core's appendix and the caller's own statement text
# (the LINE excerpt) are still there. Every way the engine's text can reach an
# exception is covered: statements, the Appender and the Arrow path.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Test;

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

$dbh->do($_) for (
  q{CREATE TYPE mood AS ENUM ('sad', 'glad')},
  q{CREATE TABLE p (
      id INTEGER PRIMARY KEY, email VARCHAR UNIQUE, nn INTEGER NOT NULL,
      c INTEGER CHECK (c > 0), s SMALLINT, d DATE, ts TIMESTAMP,
      dec DECIMAL(4,1), b BLOB, u UUID, bo BOOLEAN, iv INTERVAL, t TIME,
      h HUGEINT, ub UBIGINT, l INTEGER[], st STRUCT(a INTEGER), j JSON, m mood
    )},
  q{CREATE TABLE ck (a INTEGER, b VARCHAR, PRIMARY KEY (a, b))},
  q{CREATE TABLE ch (id INTEGER, x INTEGER, y VARCHAR, FOREIGN KEY (x, y) REFERENCES ck (a, b))},
  q{CREATE TABLE par (id INTEGER PRIMARY KEY)},
  q{CREATE TABLE chi (id INTEGER, pid INTEGER REFERENCES par (id))},
  q{INSERT INTO p (id, email, nn, c) VALUES (1, 'taken@x.y', 1, 1)},
  q{INSERT INTO p (id, email, nn, c) VALUES (2, 'two@x.y', 1, 1)},
  q{INSERT INTO ck VALUES (1, 'a, b: c"d')},
  q{INSERT INTO par VALUES (1)},
  q{INSERT INTO chi VALUES (1, 1)},
);

# The message of a statement the engine refuses, run the way core runs one
# (_dbh_execute: the statement and its bind count are known to the handler).
sub refused {
  my ($sql, @binds) = @_;
  my $ok = eval {
    $storage->_dbh_execute($storage->_get_dbh, $sql, [ map { [ {}, $_ ] } @binds ]);
    1;
  };
  return $ok ? undef : "$@";
}

# [ name, sql, [binds], marker, [ what stays ] ]
my @forms = (
  [ 'string to INTEGER', 'INSERT INTO p (id, email, nn) VALUES (?, ?, ?)',
    [ 5, 'x', 'geheim42' ], 'geheim42',
    [ qr/Conversion Error: Could not convert string '\*\*\*' to INT32/ ] ],
  [ 'DOUBLE out of range for SMALLINT', 'UPDATE p SET s = ? WHERE id = 1',
    [ 3000000000.0 ], '3000000000',
    [ qr/Type DOUBLE with value \*\*\* can't be cast because the value is out of range for the destination type INT16/ ] ],
  [ 'primary key', 'INSERT INTO p (id, email, nn) VALUES (?, ?, ?)',
    [ 1, 'other', 1 ], 'id: 1',
    [ qr/Duplicate key "id: \*\*\*" violates primary key constraint/ ] ],
  [ 'unique: the marker is the value', 'INSERT INTO p (id, email, nn) VALUES (?, ?, ?)',
    [ 3, 'taken@x.y', 1 ], 'taken@x.y',
    [ qr/Duplicate key "email: \*\*\*" violates unique constraint/ ] ],
  [ 'update of a key', 'UPDATE p SET id = ? WHERE id = 2',
    [ 1 ], 'id: 1',
    [ qr/Duplicate key "id: \*\*\*" violates primary key constraint/ ] ],
  [ 'composite primary key', 'INSERT INTO ck VALUES (?, ?)',
    [ 1, 'a, b: c"d' ], 'c"d',
    [ qr/Duplicate key "\*\*\*" violates primary key constraint/ ] ],
  [ 'foreign key, composite', 'INSERT INTO ch VALUES (?, ?, ?)',
    [ 1, 424242, 'geheimfk' ], 'geheimfk',
    [ qr/Violates foreign key constraint because key "a: \*\*\*, b: \*\*\*" does not exist in the referenced table/ ] ],
  [ 'foreign key, value with comma and colon', 'INSERT INTO ch VALUES (?, ?, ?)',
    [ 1, 7, 'geheim, z: y' ], 'geheim',
    [ qr/Violates foreign key constraint because key "\*\*\*" does not exist in the referenced table/ ] ],
  [ 'foreign key, parent still referenced', 'DELETE FROM par WHERE id = ?',
    [ 1 ], 'pid: 1',
    [ qr/Violates foreign key constraint because key "pid: \*\*\*" is still referenced/ ] ],
  [ 'ON CONFLICT DO UPDATE into a taken key', 'INSERT INTO p (id, email, nn) VALUES (?, ?, ?) ON CONFLICT (id) DO UPDATE SET email = ?',
    [ 2, 'geheimoc', 1, 'taken@x.y' ], 'taken@x.y',
    [ qr/Duplicate key "email: \*\*\*" violates unique constraint/ ] ],
  [ 'ENUM', 'INSERT INTO p (id, email, nn, m) VALUES (?, ?, ?, ?)',
    [ 6, 'e', 1, 'geheimmood' ], 'geheimmood',
    [ qr/Conversion Error: Could not convert string '\*\*\*' to UINT8/ ] ],
  [ 'JSON', 'INSERT INTO p (id, email, nn, j) VALUES (?, ?, ?, ?)',
    [ 7, 'j', 1, '{geheimjson' ], 'geheimjson',
    [ qr/Malformed JSON at byte 1 of input: unexpected character\.\s+Input: "\*\*\*"/ ] ],
  [ 'DATE', 'INSERT INTO p (id, email, nn, d) VALUES (?, ?, ?, ?)',
    [ 8, 'd', 1, '2024-13-99geheim' ], '99geheim',
    [ qr/date field value out of range: "\*\*\*"/ ] ],
  [ 'TIMESTAMP', 'INSERT INTO p (id, email, nn, ts) VALUES (?, ?, ?, ?)',
    [ 9, 'ts', 1, 'geheimts' ], 'geheimts',
    [ qr/invalid timestamp field format: "\*\*\*", expected format is \(YYYY-MM-DD/ ] ],
  [ 'TIME', 'INSERT INTO p (id, email, nn, t) VALUES (?, ?, ?, ?)',
    [ 10, 't', 1, 'geheimtime' ], 'geheimtime',
    [ qr/time field value out of range: "\*\*\*", expected format is/ ] ],
  [ 'DECIMAL', 'INSERT INTO p (id, email, nn, dec) VALUES (?, ?, ?, ?)',
    [ 11, 'dec', 1, '99999.9' ], '99999',
    [ qr/Could not cast value \*\*\* to DECIMAL\(4,1\)/ ] ],
  [ 'DECIMAL from text', 'SELECT CAST(? AS DECIMAL(3,1))',
    [ 'geheimdec' ], 'geheimdec',
    [ qr/Could not convert string "\*\*\*" to DECIMAL\(3,1\)/ ] ],
  [ 'BLOB', 'INSERT INTO p (id, email, nn, b) VALUES (?, ?, ?, ?)',
    [ 12, 'b', 1, '\xZZgeheim' ], 'geheim',
    [ qr/blob conversion of string "\*\*\*"/ ] ],
  [ 'regex', 'SELECT regexp_matches(?, ?)',
    [ 'x', '(geheim' ], 'geheim',
    [ qr/Invalid Input Error: missing \): \*\*\*/ ] ],
  [ 'UUID', 'INSERT INTO p (id, email, nn, u) VALUES (?, ?, ?, ?)',
    [ 13, 'u', 1, 'geheim-uuid' ], 'geheim-uuid',
    [ qr/Could not convert string '\*\*\*' to INT128/ ] ],
  [ 'BOOLEAN', 'INSERT INTO p (id, email, nn, bo) VALUES (?, ?, ?, ?)',
    [ 14, 'bo', 1, 'geheimbool' ], 'geheimbool',
    [ qr/Could not convert string '\*\*\*' to BOOL/ ] ],
  [ 'INTERVAL', 'INSERT INTO p (id, email, nn, iv) VALUES (?, ?, ?, ?)',
    [ 15, 'iv', 1, 'geheimiv' ], 'geheimiv',
    [ qr/Could not convert string '\*\*\*' to INTERVAL/ ] ],
  [ 'INTERVAL with an unknown unit', 'SELECT CAST(? AS INTERVAL)',
    [ '1 geheimunit' ], 'geheimunit',
    [ qr/Conversion Error: extract specifier "\*\*\*" not recognized/ ] ],
  [ 'HUGEINT', 'INSERT INTO p (id, email, nn, h) VALUES (?, ?, ?, ?)',
    [ 16, 'h', 1, 'geheimhuge' ], 'geheimhuge',
    [ qr/Could not convert string '\*\*\*' to INT128/ ] ],
  [ 'UBIGINT, negative', 'INSERT INTO p (id, email, nn, ub) VALUES (?, ?, ?, ?)',
    [ 17, 'ub', 1, -12345 ], '12345',
    [ qr/Type DOUBLE with value \*\*\* can't be cast because the value is out of range for the destination type UINT64/ ] ],
  [ 'LIST element', 'INSERT INTO p (id, email, nn, l) VALUES (?, ?, ?, ?)',
    [ 18, 'l', 1, '[1,geheimli]' ], 'geheimli',
    [ qr/Could not convert string '\*\*\*' to INT32/ ] ],
  [ 'STRUCT field', 'INSERT INTO p (id, email, nn, st) VALUES (?, ?, ?, ?)',
    [ 19, 'st', 1, '{a: geheimst}' ], 'geheimst',
    [ qr/Could not convert string '\*\*\*' to INT32/ ] ],
  [ 'STRUCT, whole value cast', 'SELECT CAST(? AS STRUCT(a INTEGER))',
    [ '{b: geheimsw}' ], 'geheimsw',
    [ qr/Type VARCHAR with value \*\*\* can't be cast to the destination type STRUCT\(a INTEGER\)/ ] ],
  [ 'value with quotes, comma and colon', 'SELECT CAST(? AS INTEGER)',
    [ q{geheim's "q", x: y} ], 'geheim',
    [ qr/Could not convert string '\*\*\*' to INT32/ ] ],
  [ 'arithmetic overflow', 'SELECT CAST(? AS INTEGER) * 1000000',
    [ 5000 ], '5000',
    [ qr/Overflow in multiplication of INT32 \(\*\*\*\)!/ ] ],
  [ 'BIT', 'SELECT CAST(? AS BIT)',
    [ 'qgeheim' ], 'q',
    [ qr/bit conversion: '\*\*\*'/ ] ],
  [ 'time zone', 'SET TimeZone = ?',
    [ 'Geheim/Zone' ], 'Geheim/Zone',
    [ qr/Unknown TimeZone '\*\*\*'/ ] ],
  [ 'strptime', 'SELECT strptime(?, ?)',
    [ 'geheimval', '%Y-%m-%d' ], 'geheimval',
    [ qr/Could not parse string "\*\*\*" according to format specifier/ ] ],
  [ 'hex digit', 'SELECT unhex(?)',
    [ 'zzgeheim' ], 'z',
    [ qr/Invalid input for hex digit: \*\*\*/ ] ],
  [ 'name taken from a bind (sequence)', 'SELECT nextval(?)',
    [ 'geheimseq' ], 'geheimseq',
    [ qr/Catalog Error: Sequence with name \*\*\* does not exist/ ] ],
  [ 'file path taken from a bind', 'SELECT * FROM read_csv(?)',
    [ '/nonexistent/geheim.csv' ], 'geheim.csv',
    [ qr/IO Error/ ] ],
);

for my $form (@forms) {
  my ($name, $sql, $binds, $marker, $stays) = @$form;
  $marker //= do { my ($v) = grep { !/^\d+$/ } @$binds; $v };
  my $err = refused($sql, @$binds);
  ok defined $err, "$name: the engine refuses it" or next;
  unlike $err, qr/\Q$marker\E/, "$name: the bound value is not in the message"
    or diag $err;
  like $err, $_, "$name: what the caller needs stays" or diag $err for @$stays;
  my $n = @$binds;
  like $err, qr/with $n bind values?\]/, "$name: core's appendix keeps the bind count";
}

# What does not hold a value is not touched.
{
  my $err = refused('INSERT INTO p (id, email, nn) VALUES (?, ?, ?)', 20, 'nn', undef);
  like $err, qr/NOT NULL constraint failed: p\.nn/, 'NOT NULL: column and table stay';
  $err = refused('INSERT INTO p (id, email, nn, c) VALUES (?, ?, ?, ?)', 21, 'chk', 1, -5);
  like $err, qr/CHECK constraint failed on table p with expression CHECK\(\(c > 0\)\)/,
    'CHECK: table and expression stay';
  unlike $err, qr/-5/, 'CHECK: the value is not in the message';
}

# The statement is the caller's text: a literal in the LINE excerpt and in
# core's appendix stays, the value in the engine's own sentence does not.
{
  my $err = refused(q{SELECT CAST('literalstays' AS INTEGER), CAST(? AS INTEGER)}, 'geheim42');
  unlike $err, qr/string 'literalstays'|geheim42 /, 'a literal in the engine sentence is masked';
  like $err, qr/Could not convert string '\*\*\*' to INT32\s+LINE 1: SELECT CAST\('literalstays' AS INTEGER\)/s,
    'the LINE excerpt keeps the statement text';
  like $err, qr/\[for Statement "SELECT CAST\('literalstays' AS INTEGER\), CAST\(\? AS INTEGER\)" with 1 bind value\]/,
    'core appendix keeps the statement and the bind count';
}

# A syntax error names no bind; it is the caller's statement and stays whole.
{
  my $err = refused('SELEC literalstays FROM p');
  like $err, qr/Parser Error: syntax error at or near "SELEC"/, 'a parser error is left as it is';
  like $err, qr/LINE 1: SELEC literalstays FROM p/, 'with its excerpt';
}

# The exception is still the Server exception of core, with its sqlstate path.
{
  my $e = refused('SELECT CAST(? AS INTEGER)', 'geheim42');
  my $obj;
  eval { $storage->_dbh_execute($storage->_get_dbh, 'SELECT CAST(? AS INTEGER)', [ [ {}, 'geheim42' ] ]); 1 }
    or $obj = $@;
  isa_ok $obj, 'DBIO::Exception', 'still a DBIO exception';
  ok !exists $obj->{detail}, 'DuckDB reports no detail field that could carry a value';
}

# ResultSet level: the same path through create.
{
  my $rs = $schema->resultset('Artist');
  $rs->create({ name => 'geheimdup' });
  my $err;
  eval { $storage->dbh_do(sub { $_[1]->do('CREATE UNIQUE INDEX artist_name_u ON artist (name)') }); 1 };
  eval { $rs->create({ name => 'geheimdup' }); 1 } or $err = "$@";
  ok defined $err, 'a second artist of the same name is refused';
  unlike $err, qr/geheimdup/, 'the artist name is not in the message';
  like $err, qr/Constraint Error: Duplicate key "name: \*\*\*" violates unique constraint/,
    'the column and the constraint kind stay';
}

# A bound value that looks like the excerpt DuckDB appends, or like core's
# appendix, is still a value: nothing in the text is the statement's own
# unless DuckDB appended it to this statement.
{
  $dbh->do(q{CREATE TABLE u (id INTEGER PRIMARY KEY, email VARCHAR UNIQUE)});
  my $insert = 'INSERT INTO u (id, email) VALUES (?, ?)';
  my $id = 0;
  for my $case (
    [ 'LINE marker after a blank',          "geheimC\n LINE 2: x" ],
    [ 'LINE marker at the start of a line', "ab\nLINE 1: geheimA" ],
    [ 'a whole excerpt with its caret line', "x\nLINE 1: SELECT 1\n        ^geheimK" ],
    [ 'an excerpt that ends in a caret line', "geheimR\n\nLINE 1: INSERT INTO u\n        ^" ],
    [ "core's appendix marker",             'ab [for Statement "geheimM' ],
  ) {
    my ($name, $value) = @$case;
    my ($marker) = $value =~ /(geheim\w)/;
    my $first = refused($insert, ++$id, $value);
    ok !defined $first, "$name: the first insert goes through" or diag $first;
    my $err = refused($insert, ++$id, $value);
    ok defined $err, "$name: the second is refused";
    unlike $err, qr/\Q$marker\E/, "$name: the value is not in the message" or diag $err;
    like $err, qr/Constraint Error: Duplicate key "[^"]*\*\*\*[^"]*" violates unique constraint/,
      "$name: the constraint stays" or diag $err;
    like $err, qr/\[for Statement "INSERT INTO u \(id, email\) VALUES \(\?, \?\)" with 2 bind values\]/,
      "$name: core's appendix is its own" or diag $err;
  }
}

# ---- Appender ---------------------------------------------------------

$dbh->do(q{CREATE TABLE ap (id INTEGER PRIMARY KEY, n VARCHAR UNIQUE, v INTEGER NOT NULL)});
$dbh->do(q{INSERT INTO ap VALUES (1, 'one', 1)});

{
  my $warned = '';
  local $SIG{__WARN__} = sub { $warned .= $_[0] };

  my $a = $storage->duckdb_appender('ap');
  $a->append_row(id => 1, n => 'geheimapp', v => 1);
  my $err = do { eval { $a->flush; 1 } ? undef : "$@" };
  ok defined $err, 'appender: a duplicate key is refused at flush';
  unlike $err, qr/geheimapp/, 'appender: the value of the key is not in the message';
  like $err, qr/Duplicate key "id: \*\*\*" violates primary key constraint/, 'appender: the column and constraint stay';

  $a = $storage->duckdb_appender('ap');
  $a->append_row(id => 2, n => 'one', v => 1);
  $err = do { eval { $a->close; 1 } ? undef : "$@" };
  ok defined $err, 'appender: a duplicate unique value is refused at close';
  unlike $err, qr/\bone\b/, 'appender: the unique value is not in the message';
  like $err, qr/Duplicate key "n: \*\*\*" violates unique constraint/, 'appender: the column stays';

  $a = $storage->duckdb_appender('chi');
  $a->append_row(id => 2, pid => 424242);
  $err = do { eval { $a->flush; 1 } ? undef : "$@" };
  ok defined $err, 'appender: a foreign key without parent is refused';
  unlike $err, qr/424242/, 'appender: the key value is not in the message';
  like $err, qr/Violates foreign key constraint because key "id: \*\*\*" does not exist/, 'appender: the form stays';

  # what DBD::DuckDB's DESTROY says of an appender left with a refused row goes
  # through the same handler
  undef $a;
  unlike $warned, qr/424242|geheimapp/, 'appender: nothing printed from a destroyed one names a value';
}

# ---- Arrow ------------------------------------------------------------

{
  my $err = do { eval { $storage->duckdb_arrow_fetch('SELECT CAST(? AS INTEGER)', [ 'geheimarrow' ]); 1 } ? undef : "$@" };
  ok defined $err, 'arrow: a refused statement throws';
  unlike $err, qr/geheimarrow/, 'arrow: the bound value is not in the message';
  like $err, qr/Could not convert string '\*\*\*' to INT32\s+LINE 1: SELECT CAST\(\? AS INTEGER\)/s,
    'arrow: the type and the excerpt stay';

  $err = do { eval { $storage->duckdb_arrow_fetch(q{SELECT CAST(x AS INTEGER) FROM (VALUES ('1'), (?)) t(x)}, [ 'geheimlate' ]); 1 } ? undef : "$@" };
  ok defined $err, 'arrow: a value refused while the rows are made throws';
  unlike $err, qr/geheimlate(?!.*LINE 1:.*\(\?\))/s, 'arrow: that bound value is not in the message';

  # the failure libduckdb's Arrow conversion reports: through the masker too
  no warnings 'redefine';
  require DBIO::DuckDB::Arrow;
  local *DBIO::DuckDB::Arrow::_error = sub {
    return "Conversion Error: Could not convert string 'geheimconv' to INT32";
  };
  $err = do { eval { $storage->duckdb_arrow_fetch('SELECT CAST(? AS VARCHAR)', [ 'geheimconv' ]); 1 } ? undef : "$@" };
  ok defined $err, 'arrow: a failure of the conversion throws';
  unlike $err, qr/geheimconv/, 'arrow: the value is not in the failure of the conversion';
  like $err, qr/Could not convert string '\*\*\*' to INT32/, 'arrow: the form stays';
}

done_testing;
