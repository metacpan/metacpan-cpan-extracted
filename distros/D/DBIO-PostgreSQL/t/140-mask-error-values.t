use strict;
use warnings;
use Test::More;

# OFFLINE test: the values in the text of a server's error.
#
# WHY: PostgreSQL writes the offending value into its error text, also when the
# value was a bind: the quoted value of the primary text, the key and the row
# of the detail, the parameters, the JSON excerpt and the COPY line of the
# context. The family's rule is that a message names keys, columns and
# options, never values (a value is a password, a token, a person's data), and
# no part of a value may stay either. What this file claims, for the texts the
# server wrote (measured on PostgreSQL 18, each form with a long value and
# with a one-character one):
#   1. every quoted value of the primary text, the detail and the context is
#      *** and the marker the test bound is nowhere in the message;
#   2. what finds the cause stays: the type, the column, the constraint, the
#      table, the line and the caret of the statement excerpt, with its
#      literal, which is the statement's text;
#   3. a value with a quote, a double quote, ", ", ":" or a line break is
#      masked whole;
#   4. a text of no known form is returned as it is, and every rule gives the
#      same text when it is applied to its own result;
#   5. the DBI prefix and the "[for Statement ...]" it appends are no part of
#      a rule.

use DBIO::PostgreSQL::Util ();

sub mask { DBIO::PostgreSQL::Util::mask_error_details($_[0]) }

# [ name, message, expected, [ markers that must be gone ] ]
my $rude = qq|ge'he"im, 4:2\nzeile|;
my $rude_ctx = qq|ge''he"im, 4:2\nzeile|;

my @cases = (
  [ 'int, long',
    qq|ERROR:  invalid input syntax for type integer: "geheim42"\nCONTEXT:  unnamed portal parameter \$1 = 'geheim42'\n|,
    qq|ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'int, one character',
    qq|ERROR:  invalid input syntax for type integer: "x"\nCONTEXT:  unnamed portal parameter \$1 = 'x'\n|,
    qq|ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    [] ],
  [ 'int, a value with quotes, comma, colon and a line break',
    qq|ERROR:  invalid input syntax for type integer: "$rude"\nCONTEXT:  unnamed portal parameter \$1 = '$rude_ctx'\n|,
    qq|ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    [q{he"im}, 'zeile', '4:2'] ],
  [ 'type with spaces',
    qq|ERROR:  invalid input syntax for type timestamp with time zone: "geheimtz"\n|,
    qq|ERROR:  invalid input syntax for type timestamp with time zone: "***"\n|,
    ['geheimtz'] ],
  [ 'double precision, no "type" word',
    qq|ERROR:  invalid input syntax for double precision: "geheim42"\n|,
    qq|ERROR:  invalid input syntax for double precision: "***"\n|,
    ['geheim42'] ],
  [ 'enum',
    qq|ERROR:  invalid input value for enum mood: "geheim42"\nCONTEXT:  unnamed portal parameter \$1 = 'geheim42'\n|,
    qq|ERROR:  invalid input value for enum mood: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'enum, one character',
    qq|ERROR:  invalid input value for enum mood: "x"\n|,
    qq|ERROR:  invalid input value for enum mood: "***"\n|,
    [] ],
  [ 'bigint out of range',
    qq|ERROR:  value "99999999999999999999" is out of range for type bigint\nCONTEXT:  unnamed portal parameter \$1 = '99999999999999999999'\n|,
    qq|ERROR:  value "***" is out of range for type bigint\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['99999999999999999999'] ],
  [ 'smallint out of range, short value',
    qq|ERROR:  value "7" is out of range for type smallint\n|,
    qq|ERROR:  value "***" is out of range for type smallint\n|,
    [] ],
  [ 'date field value out of range, hint stays',
    qq|ERROR:  date/time field value out of range: "31337-99-99"\nHINT:  Perhaps you need a different "DateStyle" setting.\nCONTEXT:  unnamed portal parameter \$1 = '31337-99-99'\n|,
    qq|ERROR:  date/time field value out of range: "***"\nHINT:  Perhaps you need a different "DateStyle" setting.\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['31337'] ],
  [ 'interval field value out of range',
    qq|ERROR:  interval field value out of range: "geheim42"\n|,
    qq|ERROR:  interval field value out of range: "***"\n|,
    ['geheim42'] ],
  [ 'timestamp out of range',
    qq|ERROR:  timestamp out of range: "geheim42"\n|,
    qq|ERROR:  timestamp out of range: "***"\n|,
    ['geheim42'] ],
  [ 'bytea hexadecimal digit',
    qq|ERROR:  invalid hexadecimal digit: "Z"\nCONTEXT:  unnamed portal with parameters: \$1 = '\\xZZgeheim'\n|,
    qq|ERROR:  invalid hexadecimal digit: "***"\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheim', 'ZZ'] ],
  [ 'bit digit',
    qq|ERROR:  "g" is not a valid binary digit\nCONTEXT:  unnamed portal parameter \$1 = 'geheim42'\n|,
    qq|ERROR:  "***" is not a valid binary digit\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'hexadecimal digit sentence',
    qq|ERROR:  "q" is not a valid hexadecimal digit\n|,
    qq|ERROR:  "***" is not a valid hexadecimal digit\n|,
    [] ],
  [ 'malformed array',
    qq|ERROR:  malformed array literal: "geheim42"\nDETAIL:  Array value must start with "{" or dimension information.\nCONTEXT:  unnamed portal parameter \$1 = 'geheim42'\n|,
    qq|ERROR:  malformed array literal: "***"\nDETAIL:  Array value must start with "{" or dimension information.\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'malformed record, too many columns',
    qq|ERROR:  malformed record literal: "(1,x,geheim42)"\nDETAIL:  Too many columns.\nCONTEXT:  unnamed portal parameter \$1 = '(1,x,geheim42)'\n|,
    qq|ERROR:  malformed record literal: "***"\nDETAIL:  Too many columns.\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'malformed range',
    qq|ERROR:  malformed range literal: "geheim42"\nDETAIL:  Missing left parenthesis or bracket.\n|,
    qq|ERROR:  malformed range literal: "***"\nDETAIL:  Missing left parenthesis or bracket.\n|,
    ['geheim42'] ],
  [ 'malformed multirange',
    qq|ERROR:  malformed multirange literal: "geheim42"\n|,
    qq|ERROR:  malformed multirange literal: "***"\n|,
    ['geheim42'] ],
  [ 'tsvector',
    qq|ERROR:  syntax error in tsvector: "'geheim42"\nCONTEXT:  unnamed portal parameter \$1 = '''geheim42'\n|,
    qq|ERROR:  syntax error in tsvector: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'tsquery',
    qq|ERROR:  no operand in tsquery: "geheim42 &"\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheim42 &'\n|,
    qq|ERROR:  no operand in tsquery: "***"\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'invalid byte sequence',
    qq|ERROR:  invalid byte sequence for encoding "UTF8": 0xc3 0x28\nCONTEXT:  unnamed portal with parameters: \$1 = 'c328'\n|,
    qq|ERROR:  invalid byte sequence for encoding "UTF8": ***\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['0xc3', '0x28'] ],
  [ 'character with byte sequence',
    qq|ERROR:  character with byte sequence 0xe2 0x82 0xac in encoding "UTF8" has no equivalent in encoding "LATIN1"\n|,
    qq|ERROR:  character with byte sequence *** in encoding "UTF8" has no equivalent in encoding "LATIN1"\n|,
    ['0xe2'] ],
  [ 'to_date: invalid value for a format',
    qq|ERROR:  invalid value "gehe" for "YYYY"\nDETAIL:  Value must be an integer.\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheimdatum', \$2 = 'YYYY-MM-DD'\n|,
    qq|ERROR:  invalid value "***" for "YYYY"\nDETAIL:  Value must be an integer.\nCONTEXT:  unnamed portal with parameters: \$1 = '***', \$2 = '***'\n|,
    ['gehe', 'YYYY-MM-DD'] ],
  [ 'invalid destination encoding name',
    qq|ERROR:  invalid destination encoding name "geheimenc"\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheimenc'\n|,
    qq|ERROR:  invalid destination encoding name "***"\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    [ 'geheimenc' ] ],
  [ 'unrecognized encoding',
    qq|ERROR:  unrecognized encoding: "geheimenc"\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheimenc'\n|,
    qq|ERROR:  unrecognized encoding: "***"\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheimenc'] ],
  [ 'time zone not recognized',
    qq|ERROR:  time zone "geheimzone" not recognized\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheimzone'\n|,
    qq|ERROR:  time zone "***" not recognized\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheimzone'] ],
  [ 'unrecognized time zone name',
    qq|ERROR:  unrecognized time zone name: "geheimzone"\n|,
    qq|ERROR:  unrecognized time zone name: "***"\n|,
    ['geheimzone'] ],
  [ 'invalid value for parameter, the parameter stays',
    qq|ERROR:  invalid value for parameter "TimeZone": "geheimzone"\n|,
    qq|ERROR:  invalid value for parameter "TimeZone": "***"\n|,
    ['geheimzone'] ],
  [ 'invalid configuration parameter name',
    qq|ERROR:  invalid configuration parameter name "geheim.42"\nDETAIL:  Custom parameter names must be two or more simple identifiers separated by dots.\n|,
    qq|ERROR:  invalid configuration parameter name "***"\nDETAIL:  Custom parameter names must be two or more simple identifiers separated by dots.\n|,
    ['geheim.42'] ],
  [ 'jsonpath syntax error',
    qq|ERROR:  syntax error at or near "?" of jsonpath input\nCONTEXT:  unnamed portal parameter \$1 = '\$.geheim42 ??'\n|,
    qq|ERROR:  syntax error at or near "***" of jsonpath input\nCONTEXT:  unnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'regular expression option',
    qq|ERROR:  invalid regular expression option: "z"\n|,
    qq|ERROR:  invalid regular expression option: "***"\n|,
    [] ],
  [ 'json: token, excerpt and parameter',
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Token "geheim42" is invalid.\nCONTEXT:  JSON data, line 1: {"a":geheim42...\nunnamed portal parameter \$1 = '{"a":geheim42}'\n|,
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Token "***" is invalid.\nCONTEXT:  JSON data, line 1: ***\nunnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'json: a value over two lines',
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Token "geheim42" is invalid.\nCONTEXT:  JSON data, line 2:  geheim42...\nunnamed portal parameter \$1 = '{"a":\n geheim42}'\n|,
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Token "***" is invalid.\nCONTEXT:  JSON data, line 2: ***\nunnamed portal parameter \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'json: expected, but found',
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Expected string, but found "}".\nCONTEXT:  JSON data, line 1: {"a":"geheim42",}\n|,
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Expected string, but found "***".\nCONTEXT:  JSON data, line 1: ***\n|,
    ['geheim42'] ],
  [ 'json: escape sequence',
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Escape sequence "\\q" is invalid.\nCONTEXT:  JSON data, line 1: "\\q...\n|,
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Escape sequence "***" is invalid.\nCONTEXT:  JSON data, line 1: ***\n|,
    ['\\q'] ],
  [ 'json: a character that must be escaped',
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Character with value 0x0a must be escaped.\n|,
    qq|ERROR:  invalid input syntax for type json\nDETAIL:  Character with value *** must be escaped.\n|,
    ['0x0a'] ],
  [ 'unexpected character in an array or record',
    qq|ERROR:  malformed array literal: "{1}x"\nDETAIL:  Unexpected "x" character.\n|,
    qq|ERROR:  malformed array literal: "***"\nDETAIL:  Unexpected "***" character.\n|,
    [] ],
  [ 'COPY line',
    qq|ERROR:  invalid input syntax for type integer: "geheim42"\nCONTEXT:  COPY t, line 3, column i: "geheim42"\n|,
    qq|ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  COPY t, line 3, column i: "***"\n|,
    ['geheim42'] ],
  [ 'COPY line, no column',
    qq|ERROR:  extra data after last expected column\nCONTEXT:  COPY t, line 1: "1\tgeheim42"\n|,
    qq|ERROR:  extra data after last expected column\nCONTEXT:  COPY t, line 1: "***"\n|,
    ['geheim42'] ],
  [ 'unique violation, one column',
    qq|ERROR:  duplicate key value violates unique constraint "u2_e_key"\nDETAIL:  Key (e)=(geheim42) already exists.\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheim42', \$2 = 'zz'\n|,
    qq|ERROR:  duplicate key value violates unique constraint "u2_e_key"\nDETAIL:  Key (e)=(***) already exists.\nCONTEXT:  unnamed portal with parameters: \$1 = '***', \$2 = '***'\n|,
    ['geheim42', 'zz'] ],
  [ 'unique violation, short value',
    qq|ERROR:  duplicate key value violates unique constraint "t_pkey"\nDETAIL:  Key (id)=(1) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "t_pkey"\nDETAIL:  Key (id)=(***) already exists.\n|,
    [] ],
  [ 'unique violation, several columns',
    qq|ERROR:  duplicate key value violates unique constraint "c2_pkey"\nDETAIL:  Key (a, b)=(5, geheim42) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "c2_pkey"\nDETAIL:  Key (a, b)=(***) already exists.\n|,
    ['geheim42'] ],
  [ 'unique violation, a value with parentheses, equals sign and line break',
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key (e)=(a)=(b\nzeile) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key (e)=(***) already exists.\n|,
    ['zeile', '(b'] ],
  [ 'unique violation, a value that holds the words of the sentence',
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key (e)=(x already exists. geheim42) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key (e)=(***) already exists.\n|,
    ['geheim42'] ],
  [ 'unique violation, a quoted column name is not read',
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key ("a)=(b")=(geheim42) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "u"\nDETAIL:  Key *** already exists.\n|,
    ['geheim42', 'a)=(b'] ],
  [ 'unique violation, an expression key',
    qq|ERROR:  duplicate key value violates unique constraint "i"\nDETAIL:  Key (lower(email::text))=(geheim42) already exists.\n|,
    qq|ERROR:  duplicate key value violates unique constraint "i"\nDETAIL:  Key (lower(email::text))=(***) already exists.\n|,
    ['geheim42'] ],
  [ 'foreign key, not present',
    qq|ERROR:  insert or update on table "fk" violates foreign key constraint "fk_x_y_fkey"\nDETAIL:  Key (x, y)=(9, geheim42) is not present in table "c2".\n|,
    qq|ERROR:  insert or update on table "fk" violates foreign key constraint "fk_x_y_fkey"\nDETAIL:  Key (x, y)=(***) is not present in table "c2".\n|,
    ['geheim42'] ],
  [ 'foreign key, still referenced',
    qq|ERROR:  update or delete on table "c2" violates foreign key constraint "fk_x_y_fkey" on table "fk"\nDETAIL:  Key (a, b)=(9, geheim42) is still referenced from table "fk".\n|,
    qq|ERROR:  update or delete on table "c2" violates foreign key constraint "fk_x_y_fkey" on table "fk"\nDETAIL:  Key (a, b)=(***) is still referenced from table "fk".\n|,
    ['geheim42'] ],
  [ 'exclusion constraint, both values',
    qq|ERROR:  conflicting key value violates exclusion constraint "ex_r_excl"\nDETAIL:  Key (r)=([1,5)) conflicts with existing key (r)=([1,3)).\nCONTEXT:  unnamed portal with parameters: \$1 = '[1,5)'\n|,
    qq|ERROR:  conflicting key value violates exclusion constraint "ex_r_excl"\nDETAIL:  Key (r)=(***) conflicts with existing key (r)=(***).\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['[1,5)', '[1,3)'] ],
  [ 'unique index creation',
    qq|ERROR:  could not create unique index "i"\nDETAIL:  Key (e)=(geheim42) is duplicated.\n|,
    qq|ERROR:  could not create unique index "i"\nDETAIL:  Key (e)=(***) is duplicated.\n|,
    ['geheim42'] ],
  [ 'not null, the row is masked',
    qq|ERROR:  null value in column "nn" of relation "t" violates not-null constraint\nDETAIL:  Failing row contains (1, null, geheim42).\nCONTEXT:  unnamed portal with parameters: \$1 = NULL\n|,
    qq|ERROR:  null value in column "nn" of relation "t" violates not-null constraint\nDETAIL:  Failing row contains (***).\nCONTEXT:  unnamed portal with parameters: \$1 = NULL\n|,
    ['geheim42'] ],
  [ 'check, a row with a line break',
    qq|ERROR:  new row for relation "t" violates check constraint "t_chk_check"\nDETAIL:  Failing row contains (1, ge\nheim42, -123456).\nCONTEXT:  unnamed portal with parameters: \$1 = '-123456'\n|,
    qq|ERROR:  new row for relation "t" violates check constraint "t_chk_check"\nDETAIL:  Failing row contains (***).\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['heim42', '123456'] ],
  [ 'partition key',
    qq|ERROR:  no partition of relation "pp" found for row\nDETAIL:  Partition key of the failing row contains (k) = (7).\nCONTEXT:  unnamed portal with parameters: \$1 = '7', \$2 = 'geheim42'\n|,
    qq|ERROR:  no partition of relation "pp" found for row\nDETAIL:  Partition key of the failing row contains (k) = (***).\nCONTEXT:  unnamed portal with parameters: \$1 = '***', \$2 = '***'\n|,
    ['geheim42'] ],
  [ 'xml, libxml repeats the input',
    qq|ERROR:  invalid XML document\nDETAIL:  line 1: Premature end of data in tag a line 1\n<a>geheim42\n           ^\nCONTEXT:  unnamed portal with parameters: \$1 = '<a>geheim42'\n|,
    qq|ERROR:  invalid XML document\nDETAIL:  line 1: ***\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheim42'] ],
  [ 'a parameter that is cut by the server',
    qq|ERROR:  value too long for type character varying(5)\nCONTEXT:  unnamed portal with parameters: \$1 = 'geheim42geheim4...'\n|,
    qq|ERROR:  value too long for type character varying(5)\nCONTEXT:  unnamed portal with parameters: \$1 = '***'\n|,
    ['geheim'] ],
  [ 'the DBI prefix and the statement tail stay, the value goes',
    qq|DBD::Pg::st execute failed: ERROR:  invalid input syntax for type integer: "geheim42"\nCONTEXT:  unnamed portal parameter \$1 = 'geheim42' [for Statement "INSERT INTO t (i) VALUES (?)"]|,
    qq|DBD::Pg::st execute failed: ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***' [for Statement "INSERT INTO t (i) VALUES (?)"]|,
    [] ],
  [ 'a primary text that ends the message, with the DBI place of the caller',
    qq|DBD::Pg::st execute failed: ERROR:  invalid input syntax for type integer: "geheim42" at /x/y.pl line 12.|,
    qq|DBD::Pg::st execute failed: ERROR:  invalid input syntax for type integer: "***" at /x/y.pl line 12.|,
    ['geheim42'] ],
  [ 'a primary text without the other fields',
    qq|ERROR:  invalid input syntax for type uuid: "geheimuuid"|,
    qq|ERROR:  invalid input syntax for type uuid: "***"|,
    ['geheimuuid'] ],
);

# What stays: the statement's own text, the names, the numbers.
my @unchanged = (
  [ 'a syntax error with its excerpt',
    qq|ERROR:  syntax error at or near ")"\nLINE 1: INSERT INTO t (id,i) VALUES (1,\$1,)\n                                          ^\n| ],
  [ 'a literal in the statement stays in the excerpt',
    qq|ERROR:  column "geheim42" does not exist\nLINE 1: SELECT geheim42 FROM t WHERE i=\$1\n               ^\n| ],
  [ 'a relation that does not exist',
    qq|ERROR:  relation "users" does not exist\nCONTEXT:  unnamed portal parameter \$1 = NULL\n| ],
  [ 'numeric overflow with its detail',
    qq|ERROR:  numeric field overflow\nDETAIL:  A field with precision 3, scale 1 must round to an absolute value less than 10^2.\n| ],
  [ 'a value that is too long for the type',
    qq|ERROR:  value too long for type character varying(5)\n| ],
  [ 'a hint',
    qq|ERROR:  operator does not exist: text = integer\nLINE 1: SELECT 1 WHERE \$1::text = 1\n                                ^\nHINT:  No operator matches the given name and argument types. You might need to add explicit type casts.\n| ],
  [ 'a lock detail', qq|ERROR:  deadlock detected\nDETAIL:  Process 1 waits for ShareLock on transaction 5; blocked by process 2.\n| ],
  [ 'text of no known form', 'something else entirely: "kept" (as it is)' ],
  [ 'empty', '' ],
);

# The statement's literal in the excerpt stays while the bound value goes.
{
  my $msg = qq|ERROR:  invalid input syntax for type integer: "geheimlit"\nLINE 1: INSERT INTO t (id,i,d) VALUES (1,'geheimlit',\$1)\n                                         ^\n|;
  # the primary text is the server's value of the literal, which is a value too
  my $masked = mask($msg);
  like $masked, qr/: "\*\*\*"\nLINE 1: INSERT INTO t \(id,i,d\) VALUES \(1,'geheimlit',\$1\)\n +\^\n\z/,
    'the LINE excerpt of the statement and its caret stay, the quoted value of the text goes';
}

for my $case (@cases) {
  my ($name, $in, $want, $markers) = @$case;
  my $got = mask($in);
  is $got, $want, $name;
  for my $m (@$markers) {
    ok index($got, $m) < 0, "... '$m' is nowhere in the message" or diag $got;
  }
  is mask($got), $got, '... masking the masked text changes nothing';
}

for my $case (@unchanged) {
  my ($name, $text) = @$case;
  is mask($text), $text, "as it is: $name";
}

# The bare detail field, without its label.
is DBIO::PostgreSQL::Util::mask_detail_values('Key (id)=(5) is not present in table "users".'),
  'Key (id)=(***) is not present in table "users".', 'a bare detail: the key';
is DBIO::PostgreSQL::Util::mask_detail_values("line 1: Premature end\n<a>geheim42\n   ^"),
  'line 1: ***', 'a bare detail: libxml';
is DBIO::PostgreSQL::Util::mask_detail_values('Token "x" is invalid.'),
  'Token "***" is invalid.', 'a bare detail: json token';
is DBIO::PostgreSQL::Util::mask_detail_values(undef), undef, 'undef stays undef';
is DBIO::PostgreSQL::Util::mask_error_details(undef), undef, '... for the message too';

done_testing;
