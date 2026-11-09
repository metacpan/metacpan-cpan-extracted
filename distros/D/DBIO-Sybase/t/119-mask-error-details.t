#!/usr/bin/env perl
# t/119-mask-error-details.t -- DBIO::Sybase::Util::mask_error_details on the
# texts of ASE and its client library, without a server.
#
# WHY this matters: an error text names keys, columns and options, never the
# values of a row. ASE writes the offending value into some of its messages
# (conversion, duplicate key) and so does the client library; the masker is
# the one place that knows those sentences. Each form maps a text that holds a
# value to the same text with the value replaced by ***; type, column,
# constraint, table and message number stay. A text without a known form is
# returned as it is, and every rule gives the same text again when applied
# to its own result.

use strict;
use warnings;
use Test::More;
use DBIO::Sybase::Util ();

sub mask { DBIO::Sybase::Util::mask_error_details(@_) }

my $pre = 'Server message number=249 severity=16 state=1 line=1 server=X text=';

my @forms = (
  # Msg 249/247/241 and the like: conversion of a value
  [ "${pre}Syntax error during implicit conversion of CHAR value 'geheimdate' to a DATE field.",
    "${pre}Syntax error during implicit conversion of CHAR value '***' to a DATE field." ],
  [ "Arithmetic overflow during implicit conversion of INT value '-1294967296' to a SMALLINT field .",
    "Arithmetic overflow during implicit conversion of INT value '***' to a SMALLINT field ." ],
  [ "Syntax error during implicit conversion of CHAR value '25:61:61' to a TIME field .",
    "Syntax error during implicit conversion of CHAR value '***' to a TIME field ." ],
  [ "Arithmetic overflow during implicit conversion of NUMERIC value '99999.9' to a NUMERIC field .",
    "Arithmetic overflow during implicit conversion of NUMERIC value '***' to a NUMERIC field ." ],
  [ "Arithmetic overflow during explicit conversion of INT value '-5' to a UNSIGNED INT field .",
    "Arithmetic overflow during explicit conversion of INT value '***' to a UNSIGNED INT field ." ],
  [ "Scale error during implicit conversion of UNSIGNED BIGINT value '7' to a TINYINT field .",
    "Scale error during implicit conversion of UNSIGNED BIGINT value '***' to a TINYINT field ." ],
  [ qq{Syntax error during implicit conversion of CHAR value 'a'b"c, d:e\nf' to a DATETIME field.},
    "Syntax error during implicit conversion of CHAR value '***' to a DATETIME field." ],
  [ "Syntax error during implicit conversion of CHAR value 'x' to a DATE field. and ' to a INT field.",
    "Syntax error during implicit conversion of CHAR value '***' to a INT field." ],
  [ "Syntax error during implicit conversion of CHAR value 'ab' to a DATE field.\nCommand has been aborted.",
    "Syntax error during implicit conversion of CHAR value '***' to a DATE field.\nCommand has been aborted." ],
  # no closing sentence: all behind the quote goes
  [ "Syntax error during implicit conversion of CHAR value 'geheim",
    "Syntax error during implicit conversion of CHAR value '***'" ],

  # client library
  [ "cs_convert: cslib user api layer: common library error: The conversion/operation resulted in overflow.to_numeric() failed for '99999.9'",
    "cs_convert: cslib user api layer: common library error: The conversion/operation resulted in overflow.to_numeric() failed for '***'" ],
  [ "common library error: x.to_date() failed for 'a'b, c\nd'",
    "common library error: x.to_date() failed for '***'" ],
  [ 'cs_convert failed (to_money(geheimmoney))',
    'cs_convert failed (to_money(***))' ],
  [ 'cs_convert failed (to_money(a)b))) at x.pl line 3.',
    'cs_convert failed (to_money(***)) at x.pl line 3.' ],
  [ 'cs_convert failed (to_numeric(7))',
    'cs_convert failed (to_numeric(***))' ],

  # Msg 1505
  [ qq{Create unique index aborted on duplicate key.  Primary key is '"geheimdup"'},
    q{Create unique index aborted on duplicate key.  Primary key is '***'} ],
  [ "Create unique index aborted on duplicate key.  Primary key is '\"geheim\nzeile\"'\nCommand has been aborted.",
    "Create unique index aborted on duplicate key.  Primary key is '***'\nCommand has been aborted." ],
  [ "Msg 1505: Create unique index aborted on duplicate key.  Primary key is '7'\nCommand has been aborted.",
    "Msg 1505: Create unique index aborted on duplicate key.  Primary key is '***'\nCommand has been aborted." ],

  # Msg 245 (the form of Microsoft SQL Server)
  [ "Syntax error converting the varchar value 'x' to a column of data type int.",
    "Syntax error converting the varchar value '***' to a column of data type int." ],
  [ "Syntax error converting the varchar value 'it's, a' to a column of data type int.",
    "Syntax error converting the varchar value '***' to a column of data type int." ],
);

# texts without a value stay as they are
my @plain = (
  q{Implicit conversion from datatype 'VARCHAR' to 'INT' is not allowed.  Use the CONVERT function to run this query.},
  q{Attempt to insert duplicate key row in object 'dbio_fw_probe' with unique index 'x'},
  q{Attempt to insert NULL value into column 'id', table 'testdb.dbo.t'; column does not allow nulls. Update fails.},
  'Data exception - string data right truncated',
  'Duplicate key was ignored.',
  q{Msg 547 Dependent foreign key constraint violation in a referential integrity constraint. dbname = 'testdb', table name = 'child', constraint name = 'fk1'.},
  q{Msg 548 Foreign key constraint violation occurred, dbname = 'testdb', table name = 'child', constraint name = 'fk1'.},
  q{There is already an object named 'x' in the database.},
  q{Cannot drop the database '_dbio_tmp_1' because it is currently in use.},
  'Server message number=257 severity=16 state=1 line=1 server=X text=Implicit conversion',
  # a literal that is no value position
  q{the value 'x' to a DATE field},
  q{Syntax error during parsing of value 'x' to a DATE field.},
  q{Primary key is the id column},
  q{failed for the table, not for 'x'},
  'cs_convert failed (no value here)',
  '',
);

for my $f (@forms) {
  my ($in, $out) = @$f;
  (my $name = $in) =~ s/\n/\\n/g;
  is mask($in), $out, "masked: " . substr($name, 0, 70);
  is mask($out), $out, "idempotent: " . substr($name, 0, 60);
  is mask(mask($in)), mask($in), "twice is once: " . substr($name, 0, 55);
}

is mask($_), $_, "unchanged: " . (length $_ ? substr($_, 0, 70) : '(empty)') for @plain;

is mask(undef), undef, 'undef stays undef';

# a newline in the key of Msg 1505 would carry the value into the next line
{
  my $t = "Primary key is '\"a\nb\"'\nCommand has been aborted.";
  my $m = mask($t, ["a\nb"]);
  unlike $m, qr/\ba\b|\bb\b/, 'Msg 1505 with a multi-line bound value: nothing of it left';
  like $m, qr/Primary key is '\*\*\*'/, '... key masked';
}

# bound values of four characters or more are found elsewhere in the text
is mask("Cannot find a file geheim.dat for it", ['geheim.dat']),
   'Cannot find a file *** for it', 'a long bound value is masked wherever it stands';
is mask("It holds ab here", ['ab']), 'It holds ab here', 'a short bound value is left to the sentences';
is mask("Syntax error during implicit conversion of CHAR value 'ab' to a DATE field.", ['ab']),
   "Syntax error during implicit conversion of CHAR value '***' to a DATE field.", 'short bound value in a sentence';
is mask("x", [undef, [], 'x']), 'x', 'undef and refs among the binds do no harm';

done_testing;
