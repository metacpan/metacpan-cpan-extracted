#!/usr/bin/env perl
# t/100-error-values-mask.t -- DBIO::Oracle::Util::mask_error_details on the
# server's texts, without a server.
#
# WHY this matters: Oracle 23ai writes the value of a statement into the error
# text, also when it was a bind (ORA-03302, ORA-03301, ORA-01438, ORA-61800,
# ORA-01428). The family's rule is that a message names keys, columns and
# options, never values. The masker is the one place that knows the server's
# sentences: each form maps a text that holds a value to the same text with the
# value replaced by ***; the code, the type, the column, the constraint and the
# table stay, and the statement the DBD appends stays whole. What the masker
# does not know stays as it is.
#
# The fixtures are texts measured on Oracle 23ai Free with DBD::Oracle 1.95.

use strict;
use warnings;
use Test::More;
use DBIO::Oracle::Util ();

sub mask { DBIO::Oracle::Util::mask_error_details(@_) }

my $HELP = sub { "\nHelp: https://docs.oracle.com/error-help/db/ora-$_[0]/" };
my $EXEC = ' (DBD ERROR: OCIStmtExecute)';

my @forms = (
  # ORA-01722 / ORA-03302: a string that is no number
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42" . $HELP->('01722') . $EXEC,
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') . $EXEC ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: g" . $HELP->('01722') . $EXEC,
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') . $EXEC ],
  [ "ORA-01722: unable to convert string value containing ' ' to a number: \nORA-03302: (ORA-01722 details) invalid string value:  geheim42 " . $HELP->('01722'),
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') ],
  [ "ORA-01722: unable to convert string value containing 'i' to a number: \nORA-03302: (ORA-01722 details) invalid string value: it's 'geheim42'" . $HELP->('01722'),
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') ],
  [ "ORA-01722: unable to convert string value containing UNISTR('\\FFFD') to a number: \nORA-03302: (ORA-01722 details) invalid string value: \x{fc}n\x{ef}geheim42" . $HELP->('01722'),
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42\nzweite zeile" . $HELP->('01722'),
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: g\nHelp: https://docs.oracle.com/error-help/db/ora-01722/ x" . $HELP->('01722'),
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722') ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42\nORA-06512: at line 1" . $HELP->('01722') . $EXEC,
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***\nORA-06512: at line 1" . $HELP->('01722') . $EXEC ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42\nORA-06512: at \"APP.PKG\", line 12\nORA-06512: at line 1",
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***\nORA-06512: at \"APP.PKG\", line 12\nORA-06512: at line 1" ],

  # ORA-00001 / ORA-03301: the key of the row
  [ "ORA-00001: unique constraint (DBIO.SYS_C0044816) violated on table DBIO.FW_P columns (ID)\nORA-03301: (ORA-00001 details) row with column values (ID:987654321) already exists" . $HELP->('00001') . $EXEC,
    "ORA-00001: unique constraint (DBIO.SYS_C0044816) violated on table DBIO.FW_P columns (ID)\nORA-03301: (ORA-00001 details) row with column values (ID:***) already exists" . $HELP->('00001') . $EXEC ],
  [ "ORA-00001: unique constraint (DBIO.FW_UQ) violated on table DBIO.FW_P columns (EMAIL)\nORA-03301: (ORA-00001 details) row with column values (EMAIL:'geheim\@x.y') already exists" . $HELP->('00001') . $EXEC,
    "ORA-00001: unique constraint (DBIO.FW_UQ) violated on table DBIO.FW_P columns (EMAIL)\nORA-03301: (ORA-00001 details) row with column values (EMAIL:***) already exists" . $HELP->('00001') . $EXEC ],
  [ "ORA-00001: unique constraint (DBIO.FW_KPK) violated on table DBIO.FW_K columns (A, B)\nORA-03301: (ORA-00001 details) row with column values (A:1, B:'x') already exists" . $HELP->('00001') . $EXEC,
    "ORA-00001: unique constraint (DBIO.FW_KPK) violated on table DBIO.FW_K columns (A, B)\nORA-03301: (ORA-00001 details) row with column values (A:***, B:***) already exists" . $HELP->('00001') . $EXEC ],
  [ "ORA-00001: unique constraint (DBIO.FW_UL) violated on table DBIO.FW_L columns (lower, Mixed Col)\nORA-03301: (ORA-00001 details) row with column values (lower:-3, Mixed Col:'geheim42') already exists" . $HELP->('00001') . $EXEC,
    "ORA-00001: unique constraint (DBIO.FW_UL) violated on table DBIO.FW_L columns (lower, Mixed Col)\nORA-03301: (ORA-00001 details) row with column values (lower:***, Mixed Col:***) already exists" . $HELP->('00001') . $EXEC ],
  # values of every type the server prints in the key
  [ "ORA-00001: unique constraint (DBIO.UD) violated on table DBIO.T columns (D)\nORA-03301: (ORA-00001 details) row with column values (D:02-JAN-24) already exists",
    "ORA-00001: unique constraint (DBIO.UD) violated on table DBIO.T columns (D)\nORA-03301: (ORA-00001 details) row with column values (D:***) already exists" ],
  [ "ORA-00001: unique constraint (DBIO.UT) violated on table DBIO.T columns (TS)\nORA-03301: (ORA-00001 details) row with column values (TS:02-JAN-24 03.04.05.123456 AM) already exists",
    "ORA-00001: unique constraint (DBIO.UT) violated on table DBIO.T columns (TS)\nORA-03301: (ORA-00001 details) row with column values (TS:***) already exists" ],
  [ "ORA-00001: unique constraint (DBIO.UR) violated on table DBIO.T columns (R)\nORA-03301: (ORA-00001 details) row with column values (R:'0102030405060708090A0B0C0D0E0F10') already exists",
    "ORA-00001: unique constraint (DBIO.UR) violated on table DBIO.T columns (R)\nORA-03301: (ORA-00001 details) row with column values (R:***) already exists" ],
  [ "ORA-00001: unique constraint (DBIO.UB) violated on table DBIO.T columns (BF)\nORA-03301: (ORA-00001 details) row with column values (BF:2.5E+000) already exists",
    "ORA-00001: unique constraint (DBIO.UB) violated on table DBIO.T columns (BF)\nORA-03301: (ORA-00001 details) row with column values (BF:***) already exists" ],
  [ "ORA-00001: unique constraint (DBIO.FUI) violated on table DBIO.X columns (SYS_NC00003\$)\nORA-03301: (ORA-00001 details) row with column values (SYS_NC00003\$:'abc') already exists",
    "ORA-00001: unique constraint (DBIO.FUI) violated on table DBIO.X columns (SYS_NC00003\$)\nORA-03301: (ORA-00001 details) row with column values (SYS_NC00003\$:***) already exists" ],
  # values that Oracle does not escape
  [ "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:'it's 'geheim42'') already exists" . $HELP->('00001'),
    "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:***) already exists" . $HELP->('00001') ],
  [ "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:'a, b:c) \"d\"\nline2'geheim42') already exists" . $HELP->('00001'),
    "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:***) already exists" . $HELP->('00001') ],
  [ "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:'p) already exists geheim42') already exists" . $HELP->('00001'),
    "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:***) already exists" . $HELP->('00001') ],
  [ "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:'a\nHelp: https://docs.oracle.com/error-help/db/ora-00001/ geheim42') already exists" . $HELP->('00001'),
    "ORA-00001: unique constraint (DBIO.US) violated on table DBIO.T columns (S)\nORA-03301: (ORA-00001 details) row with column values (S:***) already exists" . $HELP->('00001') ],
  # a composite key whose value holds the next column's delimiter: the pairs cannot be read
  [ "ORA-00001: unique constraint (DBIO.KPK) violated on table DBIO.K columns (A, B)\nORA-03301: (ORA-00001 details) row with column values (A:'x, B:geheim42', B:'y') already exists",
    "ORA-00001: unique constraint (DBIO.KPK) violated on table DBIO.K columns (A, B)\nORA-03301: (ORA-00001 details) row with column values (***) already exists" ],
  # the column line missing: no names to trust
  [ "ORA-03301: (ORA-00001 details) row with column values (ID:geheim42) already exists",
    "ORA-03301: (ORA-00001 details) row with column values (***) already exists" ],
  # the stack of PL/SQL after the key
  [ "ORA-00001: unique constraint (DBIO.KPK) violated on table DBIO.K columns (A)\nORA-03301: (ORA-00001 details) row with column values (A:geheim42) already exists\nORA-06512: at \"APP.PKG\", line 3\nORA-06512: at line 1",
    "ORA-00001: unique constraint (DBIO.KPK) violated on table DBIO.K columns (A)\nORA-03301: (ORA-00001 details) row with column values (A:***) already exists\nORA-06512: at \"APP.PKG\", line 3\nORA-06512: at line 1" ],

  # ORA-01438: precision
  [ "ORA-01438: value 99999.9 greater than specified precision (4, 1) for column " . $HELP->('01438'),
    "ORA-01438: value *** greater than specified precision (4, 1) for column " . $HELP->('01438') ],
  [ "ORA-01438: value -99999.99 greater than specified precision (4, 1) for column " . $HELP->('01438'),
    "ORA-01438: value *** greater than specified precision (4, 1) for column " . $HELP->('01438') ],
  [ "ORA-01438: value 1.2345678901234567890123456789012346E+44 greater than specified precision (38, 0) for column " . $HELP->('01438'),
    "ORA-01438: value *** greater than specified precision (38, 0) for column " . $HELP->('01438') ],

  # ORA-61800: BOOLEAN
  [ "ORA-61800: invalid boolean literal: geheim42" . $HELP->('61800'),
    "ORA-61800: invalid boolean literal: ***" . $HELP->('61800') ],
  [ "ORA-61800: invalid boolean literal: it's 'geheim42'" . $HELP->('61800'),
    "ORA-61800: invalid boolean literal: ***" . $HELP->('61800') ],
  [ "ORA-61800: invalid boolean literal: geheim42\nx" . $HELP->('61800'),
    "ORA-61800: invalid boolean literal: ***" . $HELP->('61800') ],

  # ORA-01428: argument of a numeric function
  [ "ORA-01428: Argument -4 is out of range." . $HELP->('01428'),
    "ORA-01428: Argument *** is out of range." . $HELP->('01428') ],
  [ "ORA-01428: Argument 99999.5 is out of range.",
    "ORA-01428: Argument *** is out of range." ],

  # the DBD's tag on the array execution, per tuple
  [ "ORA-24381: error(s) in array DML\nHelp: https://docs.oracle.com/error-help/db/ora-24381/ (DBD SUCCESS_WITH_INFO: OCIStmtExecute)\nexecuting 2 generated 2 errors",
    "ORA-24381: error(s) in array DML\nHelp: https://docs.oracle.com/error-help/db/ora-24381/ (DBD SUCCESS_WITH_INFO: OCIStmtExecute)\nexecuting 2 generated 2 errors" ],
  # the bare tag of an array execution that stopped on a row
  [ "ORA-00001: unique constraint (DBIO.FW_UQ) violated on table DBIO.FW_P columns (EMAIL)\nORA-03301: (ORA-00001 details) row with column values (EMAIL:'ab') already exists" . $HELP->('00001') . ' (DBD SUCCESS_WITH_INFO)',
    "ORA-00001: unique constraint (DBIO.FW_UQ) violated on table DBIO.FW_P columns (EMAIL)\nORA-03301: (ORA-00001 details) row with column values (EMAIL:***) already exists" . $HELP->('00001') . ' (DBD SUCCESS_WITH_INFO)' ],
  [ "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42" . $HELP->('01722') . " (DBD SUCCESS_WITH_INFO) S1000",
    "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" ],
);

for my $f (@forms) {
  my ($in, $out) = @$f;
  (my $name = $in) =~ s/\n/ /g;
  $name = substr($name, 0, 100);
  # the one form without a known end of the value: masked to the end of the text
  if ($in =~ /SUCCESS_WITH_INFO\) S1000\z/) {
    like mask($in), qr/invalid string value: \*\*\*\z/, 'to the end when nothing known follows: ' . substr($name, 0, 60);
    unlike mask($in), qr/geheim42|S1000/, '  and not a part of the value is left';
    next;
  }
  my $got = mask($in);
  is $got, $out, $name;
  is mask($got), $got, '  idempotent';
  unlike $got, qr/geheim42|987654321|99999\.9/, '  the marker is gone' if $in =~ /geheim42|987654321|99999\.9/;
}

# Forms that hold no value are not touched: the code, the column, the constraint
# stay, and so does what the server says about a value (its length).
for my $text (
  'ORA-12899: value too large for column "DBIO"."FW_P"."S" (actual: 10, maximum: 5)' . $HELP->('12899'),
  'ORA-02290: check constraint (DBIO.FW_CK) violated' . $HELP->('02290') . $EXEC,
  'ORA-02291: integrity constraint (DBIO.FW_FK) violated - parent key not found' . $HELP->('02291') . $EXEC,
  'ORA-02292: integrity constraint (DBIO.FW_FK) violated - child record found' . $HELP->('02292') . $EXEC,
  'ORA-01400: cannot insert NULL into ("DBIO"."FW_P"."NN")' . $HELP->('01400') . $EXEC,
  'ORA-01407: cannot update ("DBIO"."FW_P"."NN") to NULL',
  'ORA-01858: A non-numeric character was found instead of a numeric character.' . $HELP->('01858'),
  'ORA-01861: literal does not match format string' . $HELP->('01861'),
  'ORA-01843: An invalid month was specified.',
  'ORA-01847: day of month must be between 1 and last day of month',
  'ORA-01841: (full) year must be between -4713 and +9999, and not be 0',
  'ORA-01882: time zone region not found',
  'ORA-01867: the interval is invalid',
  'ORA-01873: the leading precision of the interval is too small',
  'ORA-01465: invalid hex number' . $HELP->('01465'),
  'ORA-40441: JSON syntax error' . "\nJZN-00078: XDK-00078 XDK-00200" . $HELP->('40441'),
  'ORA-40444: JSON processing error' . "\nJZN-00007: XDK-00007",
  'ORA-06502: PL/SQL: value or conversion error: character to number conversion error' . "\nORA-06512: at line 1",
  'ORA-51803: Vector dimension count must match the dimension count specified in the column definition (expected 3 dimensions, specified 2 dimensions).',
  'ORA-24381: error(s) in array DML',
  'ORA-00942: table or view "DBIO"."FW_NOSUCH" does not exist',
  'ORA-00904: "GEHEIM42": invalid identifier',
  'ORA-20001: raised by the application',
  'something nobody has seen: geheim',
  '',
) {
  is mask($text), $text, 'left as it is: ' . ($text eq '' ? '(empty)' : substr($text =~ s/\n/ /gr, 0, 70));
}
is mask(undef), undef, 'undef stays undef';

# The statement the DBD appends is the caller's own text: its literals stay.
{
  my $sql  = "SELECT * FROM FW_P WHERE id = 'geheim42' AND x = ?";
  my $app  = " (DBD ERROR: error possibly near <*> indicator at char 30 in 'SELECT * FROM FW_P WHERE id = <*>'geheim42' AND x = :p1')";
  my $head = "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: geheim42" . $HELP->('01722');
  my $want = "ORA-01722: unable to convert string value containing '***' to a number: \nORA-03302: (ORA-01722 details) invalid string value: ***" . $HELP->('01722');

  is mask($head . $app, [ 'geheim42' ], $sql), $want . $app,
    'the sentence and the bound value are masked, the statement of the DBD is not';
  is mask($want . $app, [ 'geheim42' ], $sql), $want . $app, '  idempotent';

  is mask($head . $app . "\nexecuting 3 generated 1 errors", [ 'geheim42' ], $sql), $want . $app . "\nexecuting 3 generated 1 errors",
    'the count of the array execution after it';

  unlike mask($head . $app, [ 'geheim42' ]), qr/geheim42/,
    'without the statement nothing is known to be the caller\'s: all of it is masked';
  unlike mask($head . $app, [ 'geheim42' ], 'SELECT 1 FROM dual'), qr/geheim42/,
    'a statement that is not the one in the text: masked as text';

  # the marker has to stand where the char number says
  my $off = $app =~ s/char 30/char 31/r;
  unlike mask($head . $off, [ 'geheim42' ], $sql), qr/geheim42/, 'a wrong char number is no appendix of the DBD';

  # a value that imitates the appendix does not protect itself
  my $forged = "ORA-01722: unable to convert string value containing 'g' to a number: \nORA-03302: (ORA-01722 details) invalid string value: "
             . "x (DBD ERROR: error possibly near <*> indicator at char 1 in 'geheim42')" . $HELP->('01722');
  unlike mask($forged, [], 'geheim42'), qr/geheim42/, 'a forged appendix inside a value is masked';

  # a multi-line statement
  my $multi = "INSERT INTO t\n  (id, s)\nVALUES (?, 'geheim42')";
  my $mapp  = " (DBD ERROR: error possibly near <*> indicator at char 33 in 'INSERT INTO t\n  (id, s)\nVALUES (:<*>p1, 'geheim42')')";
  is mask("ORA-01400: cannot insert NULL into (\"A\".\"T\".\"S\")" . $mapp, undef, $multi),
    "ORA-01400: cannot insert NULL into (\"A\".\"T\".\"S\")" . $mapp, 'a statement over several lines';
}

# Bound values the sentences do not know are masked wherever they stand,
# if long enough to be a value and not a word of the server.
{
  is mask('ORA-02289: sequence does not exist: geheimseq', [ 'geheimseq' ]),
    'ORA-02289: sequence does not exist: ***', 'a bound name';
  is mask("ORA-00001: x it''s geheim42 y", [ "it's geheim42" ]),
    'ORA-00001: x *** y', 'the form of $dbh->quote';
  is mask("ORA-00001: x geheim42 y", [ [ {}, 'geheim42' ] ]),
    'ORA-00001: x *** y', 'a bind as the pair of attributes and value';
  is mask('ORA-01400: cannot insert NULL into ("A"."T"."NN")', [ 'T', 1, undef, \'ref', [ 1 ] ]),
    'ORA-01400: cannot insert NULL into ("A"."T"."NN")',
    'short, undefined and reference binds are no reason to change a text';
}

done_testing;
