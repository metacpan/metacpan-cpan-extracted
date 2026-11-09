#!/usr/bin/env perl
# t/72-error-mask-unit.t -- DBIO::DuckDB::Util::mask_error_details on the
# engine's texts, without an engine.
#
# WHY this matters: the masker is the one place that knows the engine's
# sentences. Each form maps a text that holds a value to the same text with
# the value replaced by ***; the type, column, constraint and table stay, and
# the statement's own text (the LINE excerpt, core's appendix) is never
# touched. What the masker does not know stays as it is: a message is not
# switched off, and a text that is not the engine's is not mangled.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Util ();

sub mask { DBIO::DuckDB::Util::mask_error_details(@_) }

my @forms = (
  [ "Conversion Error: Could not convert string 'geheim42' to INT32",
    "Conversion Error: Could not convert string '***' to INT32" ],
  [ q{Conversion Error: Could not convert string "geheimdec" to DECIMAL(3,1)},
    q{Conversion Error: Could not convert string "***" to DECIMAL(3,1)} ],
  [ "Conversion Error: Could not convert string 'a' to INT32' to INT32",
    "Conversion Error: Could not convert string '***' to INT32" ],
  [ "Conversion Error: Could not convert string 'x' to INT32 when casting from source column x",
    "Conversion Error: Could not convert string '***' to INT32 when casting from source column x" ],
  [ "Conversion Error: Type DOUBLE with value 3000000000.0 can't be cast because the value is out of range for the destination type INT16",
    "Conversion Error: Type DOUBLE with value *** can't be cast because the value is out of range for the destination type INT16" ],
  [ "Conversion Error: Type VARCHAR with value '{b: 1}' can't be cast to the destination type STRUCT(a INTEGER)",
    "Conversion Error: Type VARCHAR with value *** can't be cast to the destination type STRUCT(a INTEGER)" ],
  [ 'Constraint Error: Duplicate key "id: 1" violates primary key constraint.',
    'Constraint Error: Duplicate key "id: ***" violates primary key constraint.' ],
  [ 'Constraint Error: Duplicate key "email: geheim@x.y" violates unique constraint.',
    'Constraint Error: Duplicate key "email: ***" violates unique constraint.' ],
  [ 'Constraint Error: Duplicate key "a: 1, b: x" violates primary key constraint.',
    'Constraint Error: Duplicate key "a: ***, b: ***" violates primary key constraint.' ],
  [ 'Failed to append: Duplicate key "id: 1" violates primary key constraint.',
    'Failed to append: Duplicate key "id: ***" violates primary key constraint.' ],
  [ 'Constraint Error: Violates foreign key constraint because key "id: 424242" does not exist in the referenced table',
    'Constraint Error: Violates foreign key constraint because key "id: ***" does not exist in the referenced table' ],
  [ 'Constraint Error: Violates foreign key constraint because key "pid: 1" is still referenced by a foreign key in a different table. If this is an unexpected constraint violation, please refer to our foreign key limitations in the documentation',
    'Constraint Error: Violates foreign key constraint because key "pid: ***" is still referenced by a foreign key in a different table. If this is an unexpected constraint violation, please refer to our foreign key limitations in the documentation' ],
  [ q~Conversion Error: Malformed JSON at byte 1 of input: unexpected character.  Input: "{geheimjson"~,
    q~Conversion Error: Malformed JSON at byte 1 of input: unexpected character.  Input: "***"~ ],
  [ q{Conversion Error: Malformed JSON at byte 0 of input: input length is 0.  Input: ""},
    q{Conversion Error: Malformed JSON at byte 0 of input: input length is 0.  Input: "***"} ],
  [ q{Conversion Error: date field value out of range: "2024-13-99geheim"},
    q{Conversion Error: date field value out of range: "***"} ],
  [ q{Conversion Error: invalid date field format: "geheim-01-01", expected format is (YYYY-MM-DD)},
    q{Conversion Error: invalid date field format: "***", expected format is (YYYY-MM-DD)} ],
  [ q{Conversion Error: invalid timestamp field format: "geheimts", expected format is (YYYY-MM-DD HH:MM:SS[.US][±HH[:MM[:SS]]| ZONE])},
    q{Conversion Error: invalid timestamp field format: "***", expected format is (YYYY-MM-DD HH:MM:SS[.US][±HH[:MM[:SS]]| ZONE])} ],
  [ q{Conversion Error: time field value out of range: "25:99:99geheim", expected format is ([YYYY-MM-DD ]HH:MM:SS[.MS])},
    q{Conversion Error: time field value out of range: "***", expected format is ([YYYY-MM-DD ]HH:MM:SS[.MS])} ],
  [ q{Conversion Error: timestamp field value out of range: "2024-02-30 99:00:00"},
    q{Conversion Error: timestamp field value out of range: "***"} ],
  [ 'Conversion Error: Could not cast value 99999.900000 to DECIMAL(4,1)',
    'Conversion Error: Could not cast value *** to DECIMAL(4,1)' ],
  [ q{Conversion Error: Invalid hex escape code encountered in string -> blob conversion of string "\xZZgeheim": \xZZ},
    q{Conversion Error: Invalid hex escape code encountered in string -> blob conversion of string "***": ***} ],
  [ 'Invalid Input Error: missing ): (geheim',
    'Invalid Input Error: missing ): ***' ],
  [ 'Invalid Input Error: Invalid input for hex digit: g',
    'Invalid Input Error: Invalid input for hex digit: ***' ],
  [ qq{Invalid Input Error: Could not parse string "geheimval" according to format specifier "%Y-%m-%d"\ngeheimval\n^\nError: Expected a number},
    qq{Invalid Input Error: Could not parse string "***" according to format specifier "%Y-%m-%d"\n***\n^\nError: Expected a number} ],
  [ q(Conversion Error: Invalid character encountered in string -> bit conversion: 'g'),
    q(Conversion Error: Invalid character encountered in string -> bit conversion: '***') ],
  [ 'Out of Range Error: Overflow in multiplication of INT32 (5000 * 1000000)!',
    'Out of Range Error: Overflow in multiplication of INT32 (***)!' ],
  [ "Conversion Error: Unknown TimeZone 'Geheim/Zone'!\n\nCandidate time zones: \"America/Denver\"",
    "Conversion Error: Unknown TimeZone '***'!\n\nCandidate time zones: \"America/Denver\"" ],
  [ 'Conversion Error: extract specifier "geheimunit" not recognized',
    'Conversion Error: extract specifier "***" not recognized' ],
  [ q{Binder Error: JSON path error near '.[geheimpath'},
    q{Binder Error: JSON path error near '***'} ],
);

for my $f (@forms) {
  my ($in, $out) = @$f;
  (my $name = $in) =~ s/\n/ /g;
  is mask($in), $out, substr($name, 0, 90);
  is mask($out), $out, '  idempotent';
}

# Forms that hold no value are not touched.
for my $text (
  'Constraint Error: CHECK constraint failed on table p with expression CHECK((c > 0))',
  'Constraint Error: NOT NULL constraint failed: p.nn',
  'Binder Error: LIMIT/OFFSET cannot be negative',
  'Parser Error: syntax error at or near "SELEC"',
  'Out of Range Error: Overflow in negation of numeric value!',
  'something nobody has seen: geheim',
  '',
) {
  is mask($text), $text, "left as it is: " . ($text eq '' ? '(empty)' : substr($text, 0, 60));
}
is mask(undef), undef, 'undef stays undef';

# The statement's own text is the caller's: the LINE excerpt and core's
# appendix stay whole, whatever they hold.
{
  my $excerpt = "\n\nLINE 1: SELECT CAST('geheimlit' AS INTEGER)\n               ^";
  my $sql = "SELECT CAST('geheimlit' AS INTEGER)";
  is mask("Conversion Error: Could not convert string 'geheimlit' to INT32$excerpt", undef, $sql),
    "Conversion Error: Could not convert string '***' to INT32$excerpt",
    'the sentence is masked, the LINE excerpt is not';

  is mask("Conversion Error: Could not convert string 'geheimlit' to INT32$excerpt", undef, $sql),
    "Conversion Error: Could not convert string '***' to INT32$excerpt",
    'the excerpt stays when the statement is the one it was cut from';
  is mask("Conversion Error: Could not convert string 'geheimlit' to INT32$excerpt"),
    "Conversion Error: Could not convert string '***' to INT32$excerpt",
    'no statement known: all of it is masked (nothing in the excerpt is a sentence)';
}

# A key text is read as column: value pairs only where that is unambiguous.
{
  my $key = sub { qq(Constraint Error: Duplicate key "$_[0]" violates primary key constraint.) };
  is mask($key->('a: 1, b: c"d, e: f')), $key->('a: ***, b: ***, e: ***'),
    'a quote in a value is no problem for the parse';
  is mask($key->('a: 1, b: x: y')), $key->('***'),
    'a value with a colon makes the key text unreadable: all of it is masked';
  is mask($key->('a: 1, geheim')), $key->('***'),
    'a part without a column makes it unreadable';
  is mask($key->('a: 1, a: 2')), $key->('***'),
    'a column twice makes it unreadable';
  is mask($key->('id: 5, b: x, y: z'), [ 'x, y: z' ]), $key->('***'),
    'a bound value with a comma and a colon in it: all of it is masked';
  is mask($key->('id: 5, b: x'), [ 5, 'x' ]), $key->('id: ***, b: ***'),
    'plain bound values: the columns stay';
}

# Bound values the sentences do not know are masked wherever they stand in the
# message before the excerpt, if long enough to be a value and not a word of
# the engine.
{
  is mask("Catalog Error: Sequence with name geheimseq does not exist!", [ 'geheimseq' ]),
    'Catalog Error: Sequence with name *** does not exist!', 'a bound name';
  is mask("IO Error: No files found that match the pattern \"/x/geheim.csv\"\n\nLINE 1: SELECT * FROM read_csv('/x/geheim.csv')\n                ^",
          [ '/x/geheim.csv' ], "SELECT * FROM read_csv('/x/geheim.csv')"),
    "IO Error: No files found that match the pattern \"***\"\n\nLINE 1: SELECT * FROM read_csv('/x/geheim.csv')\n                ^",
    'a bound path; the excerpt stays';
  is mask('Constraint Error: NOT NULL constraint failed: p.nn', [ 'p', 1, undef, \'ref' ]),
    'Constraint Error: NOT NULL constraint failed: p.nn',
    'short, undefined and reference binds are no reason to change a text';
}

# What looks like the excerpt or the appendix but is not DuckDB's own is part of
# the message, and a bound value in it is masked. The excerpt counts only when
# it ends the text, is one line of the statement (cut with ... at either end)
# and is followed by the caret line.
{
  my $sql   = 'INSERT INTO u (id, email) VALUES (?, ?)';
  my $dup   = sub { qq(Constraint Error: Duplicate key "email: $_[0]" violates unique constraint.) };
  my $plain = sub { my $v = shift; my $m = mask($dup->($v), [ 1, $v ], $sql); $m };

  for my $v ("geheimC\n LINE 2: x", "ab\nLINE 1: geheimA", 'ab [for Statement "geheimM',
             "x\nLINE 1: SELECT 1\n        ^geheimK") {
    my ($marker) = $v =~ /(geheim\w)/;
    unlike $plain->($v), qr/\Q$marker\E/, "a value that looks like a marker is masked: " . ($v =~ s/\n/\\n/gr);
  }

  # at the end of the text, with a statement line that is not the statement's
  my $tail = "\n\nLINE 1: SELECT 1\n        ^";
  is mask("Invalid Input Error: missing ): geheimR$tail", [ 'geheimR' ], 'SELECT regexp_matches(?, ?)'),
    "Invalid Input Error: missing ): ***$tail",
    'an excerpt that is not a piece of the statement is plain text: the value before it is masked';

  # a real excerpt: cut at either end, any line of the statement, caret line last
  my $multi = "SELECT 1,\r\n  CAST('geheimlit' AS INTEGER) || 'abcdefghijklmnopqrstuvwxyz'\n, 3";
  for my $line ("LINE 2:   CAST('geheimlit' AS INTEGER) || 'abcdefghijklmnopqrstuvwxyz'",
                "LINE 2: ...CAST('geheimlit' AS INTEGER) || 'abcdefghijkl...") {
    my $ex = "\n\n$line\n          ^";
    is mask("Conversion Error: Could not convert string 'geheimlit' to INT32$ex", undef, $multi),
      "Conversion Error: Could not convert string '***' to INT32$ex", "a real excerpt stays: $line";
  }
  is mask("Conversion Error: Could not convert string 'geheimlit' to INT32\n\nLINE 3: , 3\n  ^", undef, $multi),
    "Conversion Error: Could not convert string '***' to INT32\n\nLINE 3: , 3\n  ^", 'any line of the statement';
  my $wrong = "\n\nLINE 1:   CAST('geheimlit' AS INTEGER)\n  ^";
  unlike mask("Conversion Error: Could not convert string 'x' to INT32$wrong", [ 'geheimlit' ], $multi),
    qr/geheimlit/, 'the line number must belong to the excerpt: otherwise it is masked as text';

  # a Statement appendix is no part of the engine's text here: not split off
  my $m = mask(qq(Constraint Error: Duplicate key "email: x [for Statement "geheimP" violates unique constraint.), [ 'x [for Statement "geheimP' ], $sql);
  unlike $m, qr/geheimP/, 'the appendix marker inside a value is masked';
}

done_testing;
