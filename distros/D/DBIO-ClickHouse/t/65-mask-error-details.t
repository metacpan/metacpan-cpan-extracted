use strict;
use warnings;
use Test::More;

# t/65-mask-error-details.t -- the error text of the engine names keys,
# columns and options, never the values bound to the statement.
#
# ClickHouse is reached over the MySQL wire protocol; DBD::mysql puts the bind
# values into the statement on the client and the engine quotes what it
# received, in half a dozen sentences of its own. The texts below are the ones
# a ClickHouse 25.3 server answered (statement and values are the probes'; the
# values are markers such as 'geheim42'). Each case names what must be gone
# (the value, also a part of it) and what must stay (the error code, the type,
# the column, the constraint, the table, the position).

use DBIO::ClickHouse::Util qw(mask_error_details);

my $VERSION_TAIL = ' (version 25.3.14.14 (official build))';

# The plan of a failed function, as the engine writes it after an insert.
my $PLAN = q~while executing 'FUNCTION if(isNull(-dummy-0) : 3, defaultValueOfTypeName('Int32') :: 2, _CAST(-dummy-0, 'Int32') :: 4) -> if(isNull(-dummy-0), defaultValueOfTypeName('Int32'), _CAST(-dummy-0, 'Int32')) Int32 : 1': While executing ValuesBlockInputFormat.~;
my $NOTE = q~syntax error at begin of string. Note: there are toInt32OrZero and toInt32OrNull functions, which returns zero/NULL instead of throwing exception.~;

my @cases = (
  {
    name   => 'Cannot parse string, in an insert with the plan of the function',
    raw    => qq~Code: 6. DB::Exception: Cannot parse string 'geheim42' as Int32: $NOTE: $PLAN (CANNOT_PARSE_TEXT)~,
    secret => ['geheim42', '42'],
    keep   => ["Cannot parse string '***' as Int32", 'Code: 6.', '(CANNOT_PARSE_TEXT)', 'While executing ValuesBlockInputFormat.'],
  },
  {
    name   => 'Cannot parse string, a short value',
    raw    => qq~Code: 6. DB::Exception: Cannot parse string 'ab' as Int32: $NOTE: $PLAN (CANNOT_PARSE_TEXT)~,
    secret => ["'ab'"],
    keep   => ["Cannot parse string '***' as Int32"],
  },
  {
    name   => 'Cannot parse string, the parsed prefix of a number',
    raw    => q~Code: 6. DB::Exception: Cannot parse string '7.5' as Int32: syntax error at position 1 (parsed just '7'). Note: there are toInt32OrZero and toInt32OrNull functions, which returns zero/NULL instead of throwing exception.: In scope SELECT toInt32('7.5'). (CANNOT_PARSE_TEXT)~,
    secret => ['7.5', "'7'"],
    keep   => ["as Int32: syntax error at position 1 (parsed just '***')", 'SELECT toInt32(***)'],
  },
  {
    name   => 'Cannot parse string, a quote, a comma and a colon in the value',
    raw    => qq~Code: 6. DB::Exception: Cannot parse string 'ge\\'heim"q, x: y' as Int32: $NOTE: $PLAN (CANNOT_PARSE_TEXT)~,
    secret => ["heim", 'q, x', 'x: y'],
    keep   => ["Cannot parse string '***' as Int32: syntax error at begin of string."],
  },
  {
    name   => 'Cannot parse string, a newline in the value',
    raw    => q~Code: 6. DB::Exception: Cannot parse string 'geheim\nzeile2' as Int32: syntax error at begin of string.: In scope SELECT toInt32('geheim\nzeile2'). (CANNOT_PARSE_TEXT)~,
    secret => ['geheim', 'zeile2'],
    keep   => ["Cannot parse string '***' as Int32", 'SELECT toInt32(***)'],
  },
  {
    name   => 'Cannot parse string, a value that imitates the end of the sentence and the error code',
    raw    => q~Code: 6. DB::Exception: Cannot parse string 'geheim\' as Int32: x. (FOO) (version 1)' as Int32: syntax error at begin of string.: In scope SELECT toInt32('geheim\' as Int32: x. (FOO) (version 1)'). (CANNOT_PARSE_TEXT)~,
    secret => ['geheim', 'FOO', 'version 1'],
    keep   => ["Cannot parse string '***' as Int32: syntax error", 'SELECT toInt32(***)', '(CANNOT_PARSE_TEXT)'],
  },
  {
    name   => 'Cannot parse string, a long value',
    raw    => qq~Code: 6. DB::Exception: Cannot parse string 'geheim@{[ 'z' x 300 ]}' as Int32: syntax error at begin of string.: In scope SELECT toInt32('geheim@{[ 'z' x 300 ]}'). (CANNOT_PARSE_TEXT)~,
    secret => ['geheim', 'zzzz'],
    keep   => ["Cannot parse string '***' as Int32", 'SELECT toInt32(***)'],
  },
  {
    name   => 'Cannot parse string, a decimal type with a comma in it',
    raw    => qq~Code: 6. DB::Exception: Cannot parse string 'geheimdec' as Decimal(5, 2): syntax error at begin of string: $PLAN (CANNOT_PARSE_TEXT)~,
    secret => ['geheimdec'],
    keep   => ["as Decimal(5, 2): syntax error"],
  },
  {
    name   => 'Cannot convert string, in a mutation',
    raw    => q~Code: 53. DB::Exception: Cannot convert string 'geheim55' to type Int32: while executing 'FUNCTION equals(id : 0, 'geheim55' : 1) -> equals(id, 'geheim55') UInt8 : 2'. (TYPE_MISMATCH)~,
    secret => ['geheim55', '55'],
    keep   => ["Cannot convert string '***' to type Int32", '(TYPE_MISMATCH)', 'Code: 53.'],
  },
  {
    name   => 'Cannot convert string, an unescaped quote in the value',
    raw    => q~Code: 53. DB::Exception: Cannot convert string 'ge'heim' to type Int32: while executing 'FUNCTION equals(id : 0, 'ge\'heim' : 1) -> equals(id, 'ge\'heim') UInt8 : 2'. (TYPE_MISMATCH)~,
    secret => ['heim'],
    keep   => ["Cannot convert string '***' to type Int32", '(TYPE_MISMATCH)'],
  },
  {
    name   => 'Cannot convert string, a select',
    raw    => q~Code: 53. DB::Exception: Cannot convert string 'geheim56' to type Int32. (TYPE_MISMATCH)~,
    secret => ['geheim56'],
    keep   => ["Cannot convert string '***' to type Int32. (TYPE_MISMATCH)"],
  },
  {
    name   => 'Cannot parse date here, without quotes',
    raw    => qq~Code: 38. DB::Exception: Cannot parse date here: geheimdate: Cannot parse Date from String: $PLAN (CANNOT_PARSE_DATE)~,
    secret => ['geheimdate'],
    keep   => ['Cannot parse date here: ***: Cannot parse Date from String', '(CANNOT_PARSE_DATE)'],
  },
  {
    name   => 'Cannot parse date here, a cut-off value',
    raw    => qq~Code: 38. DB::Exception: Cannot parse date here: 31337-99-9: Cannot parse Date from String: $PLAN (CANNOT_PARSE_DATE)~,
    secret => ['31337', '99-9'],
    keep   => ['Cannot parse date here: ***: Cannot parse Date from String'],
  },
  {
    name   => 'Cannot parse date here, a quote, a comma, a colon and a newline in the value',
    raw    => qq~Code: 38. DB::Exception: Cannot parse date here: ge'heim"q,\nzei, x: : Cannot parse Date from String: $PLAN (CANNOT_PARSE_DATE)~,
    secret => ['heim', 'q,', 'zei', 'x:'],
    keep   => ['Cannot parse date here: ***: Cannot parse Date from String'],
  },
  {
    name   => 'Cannot parse date: no value in it',
    raw    => qq~Code: 38. DB::Exception: Cannot parse date: value is too short: Cannot parse Date from String: $PLAN (CANNOT_PARSE_DATE)~,
    secret => [],
    keep   => ['Cannot parse date: value is too short: Cannot parse Date from String'],
  },
  {
    name   => 'Cannot parse uuid',
    raw    => qq~Code: 376. DB::Exception: Cannot parse uuid geheimuuid: Cannot parse UUID from String: $PLAN (CANNOT_PARSE_UUID)~,
    secret => ['geheimuuid'],
    keep   => ['Cannot parse uuid ***: Cannot parse UUID from String'],
  },
  {
    name   => 'Cannot parse IPv4 and IPv6',
    raw    => q~Code: 675. DB::Exception: Cannot parse IPv4 geheim102: Cannot parse IPv4 from String: In scope SELECT toIPv4('geheim102'). (CANNOT_PARSE_IPV4)~,
    secret => ['geheim102'],
    keep   => ['Cannot parse IPv4 ***: Cannot parse IPv4 from String', 'SELECT toIPv4(***)'],
  },
  {
    name   => 'Cannot parse IPv6',
    raw    => q~Code: 676. DB::Exception: Cannot parse IPv6 geheim103: Cannot parse IPv6 from String: In scope SELECT toIPv6('geheim103'). (CANNOT_PARSE_IPV6)~,
    secret => ['geheim103'],
    keep   => ['Cannot parse IPv6 ***: Cannot parse IPv6 from String'],
  },
  {
    name   => 'Unknown element for an enum',
    raw    => q~Code: 691. DB::Exception: Unknown element 'geheimenum' for enum: In scope SELECT CAST('geheimenum', 'Enum8(\'x\' = 1)'). (UNKNOWN_ELEMENT_OF_ENUM)~,
    secret => ['geheimenum'],
    keep   => ["Unknown element '***' for enum: In scope SELECT CAST(***, ***)", '(UNKNOWN_ELEMENT_OF_ENUM)'],
  },
  {
    name   => 'Unknown element for an enum, a number and the labels',
    raw    => q~Code: 691. DB::Exception: Unknown element '5' for enum, maybe you meant: ['a']: In scope SELECT CAST('5', 'Enum8(\'a\' = 1)'). (UNKNOWN_ELEMENT_OF_ENUM)~,
    secret => ["'5'"],
    keep   => ["Unknown element '***' for enum, maybe you meant: ['a']"],
  },
  {
    name   => 'Cannot parse boolean value',
    raw    => q~Code: 467. DB::Exception: Cannot parse boolean value here: 'geheim99', should be 'true' or 'false' controlled by setting bool_true_representation and bool_false_representation or one of True/False/T/F/Y/N/Yes/No/On/Off/Enable/Disable/Enabled/Disabled/1/0: In scope SELECT CAST('geheim99', 'Bool'). (CANNOT_PARSE_BOOL)~,
    secret => ['geheim99'],
    keep   => ["Cannot parse boolean value here: '***', should be 'true' or 'false' controlled by setting bool_true_representation", '(CANNOT_PARSE_BOOL)'],
  },
  {
    name   => 'Cannot read array from text, one character of the value',
    raw    => qq~Code: 130. DB::Exception: Cannot read array from text, expected comma or end of array, found 'g': $PLAN (CANNOT_READ_ARRAY_FROM_TEXT)~,
    secret => ["found 'g'"],
    keep   => ["expected comma or end of array, found '***'", '(CANNOT_READ_ARRAY_FROM_TEXT)'],
  },
  {
    name   => 'Cannot parse input, a map',
    raw    => q~Code: 27. DB::Exception: Cannot parse input: expected '{' before: 'geheimmap': while converting 'geheimmap' to Map(String, Int32):  at row 0: While executing ValuesBlockInputFormat. (CANNOT_PARSE_INPUT_ASSERTION_FAILED)~,
    secret => ['geheimmap'],
    keep   => ["expected '{' before: '***': while converting '***' to Map(String, Int32):  at row 0", '(CANNOT_PARSE_INPUT_ASSERTION_FAILED)'],
  },
  {
    name   => 'Cannot parse input, a tuple, with the plan',
    raw    => q~Code: 27. DB::Exception: Cannot parse input: expected '(' before: 'geheimtup': while executing 'FUNCTION if(isNull(-dummy-0) : 3, defaultValueOfTypeName('Tuple(Int32, String)') :: 2) -> if(isNull(-dummy-0), defaultValueOfTypeName('Tuple(Int32, String)')) Tuple(Int32, String) : 1': While executing ValuesBlockInputFormat. (CANNOT_PARSE_INPUT_ASSERTION_FAILED)~,
    secret => ['geheimtup'],
    keep   => ["expected '(' before: '***': while executing '***': While executing ValuesBlockInputFormat."],
  },
  {
    name   => 'Cannot parse input, the rest of a statement, a csv row of two lines',
    raw    => qq~Code: 27. DB::Exception: Cannot parse input: expected ',' before: 'geheim69,5': (at row 1)\n: Could not print diagnostic info because two last rows aren't in buffer (rare case)\n: While executing CSVRowInputFormat. (CANNOT_PARSE_INPUT_ASSERTION_FAILED)~,
    secret => ['geheim69'],
    keep   => ["expected ',' before: '***': (at row 1)", 'Could not print diagnostic info', 'While executing CSVRowInputFormat.'],
  },
  {
    name   => 'Cannot parse input, expected eof',
    raw    => q~Code: 27. DB::Exception: Cannot parse input: expected 'eof' before: 'geheim126'. (CANNOT_PARSE_INPUT_ASSERTION_FAILED)~,
    secret => ['geheim126'],
    keep   => ["expected 'eof' before: '***'. (CANNOT_PARSE_INPUT_ASSERTION_FAILED)"],
  },
  {
    name   => 'Cannot parse expression of type, the rest of a multi-row insert',
    raw    => q~Code: 62. DB::Exception: Cannot parse expression of type Int32 here: '2','geheim71'): While executing ValuesBlockInputFormat. (SYNTAX_ERROR)~,
    secret => ['geheim71', "'2'"],
    keep   => ['Cannot parse expression of type Int32 here: ***: While executing ValuesBlockInputFormat. (SYNTAX_ERROR)'],
  },
  {
    name   => 'Cannot parse JSON object here',
    raw    => q~Code: 117. DB::Exception: Cannot parse JSON object here: {geheimjson: In scope SELECT CAST('{geheimjson', 'JSON'). (INCORRECT_DATA)~,
    secret => ['geheimjson'],
    keep   => ['Cannot parse JSON object here: ***: In scope SELECT CAST(***, ***)', '(INCORRECT_DATA)'],
  },
  {
    name   => 'In scope, a select with a cast',
    raw    => q~Code: 6. DB::Exception: Cannot parse string 'geheim45' as Int32: syntax error at begin of string.: In scope SELECT CAST('geheim45', 'INTEGER') FROM pr_p. (CANNOT_PARSE_TEXT)~,
    secret => ['geheim45', 'INTEGER'],
    keep   => ['In scope SELECT CAST(***, ***) FROM pr_p. (CANNOT_PARSE_TEXT)'],
  },
  {
    name   => 'In scope, numbers of every shape and the names around them',
    raw    => q~Code: 6. DB::Exception: Cannot parse string 'x' as Int32: syntax error at begin of string.: In scope SELECT ((((toInt32('x') + 12345) + 3500.) - 31) + c1) + `c2` + "c3" FROM db2.ck2 WHERE a1 = 1e5 AND b = .5. (CANNOT_PARSE_TEXT)~,
    secret => ['12345', '3500', '1e5', "'x'"],
    keep   => ['SELECT ((((toInt32(***) + ***) + ***) - ***) + c1) + `c2` + "c3" FROM db2.ck2 WHERE a1 = *** AND b = ***. (CANNOT_PARSE_TEXT)'],
  },
  {
    name   => 'In scope, a quote and a newline in a value, a comma, parentheses',
    raw    => q~Code: 47. DB::Exception: Unknown expression or function identifier `AND` in scope SELECT * FROM ck WHERE (id = 'ge\'heim\n(x, y)') AND AND. (UNKNOWN_IDENTIFIER)~,
    secret => ['heim', 'x, y'],
    keep   => ['Unknown expression or function identifier `AND` in scope SELECT * FROM ck WHERE (id = ***) AND AND. (UNKNOWN_IDENTIFIER)'],
  },
  {
    name   => 'In scope, a value that holds the error code',
    raw    => q~Code: 6. DB::Exception: Cannot parse string 'geheim. (CANNOT_PARSE_TEXT) (version 25)' as Int32: syntax error at begin of string.: In scope SELECT toInt32('geheim. (CANNOT_PARSE_TEXT) (version 25)'). (CANNOT_PARSE_TEXT)~,
    secret => ['geheim', '(version 25)'],
    keep   => ['In scope SELECT toInt32(***). (CANNOT_PARSE_TEXT)'],
  },
  {
    name   => 'In scope, ended by the format of the insert, not by the code',
    raw    => q~Code: 43. DB::Exception: Illegal types UInt8 and String of arguments of function plus: In scope 1 + 'geheim118': While executing ValuesBlockInputFormat. (ILLEGAL_TYPE_OF_ARGUMENT)~,
    secret => ['geheim118'],
    keep   => ['In scope *** + ***: While executing ValuesBlockInputFormat. (ILLEGAL_TYPE_OF_ARGUMENT)'],
  },
  {
    name   => 'In scope, a list of suggestions',
    raw    => q~Code: 46. DB::Exception: Function with name `toInt8OrThrow` does not exist. In scope SELECT toInt8OrThrow('99999'). Maybe you meant: ['toInt8OrZero','toUInt8OrZero']. (UNKNOWN_FUNCTION)~,
    secret => ['99999'],
    keep   => ['Function with name `toInt8OrThrow` does not exist.', '(UNKNOWN_FUNCTION)'],
  },
  {
    name   => 'In scope, a bound value in a where',
    raw    => q~Code: 47. DB::Exception: Unknown expression identifier `nocol` in scope SELECT nocol FROM pr_p WHERE id = 'geheim67'. (UNKNOWN_IDENTIFIER)~,
    secret => ['geheim67'],
    keep   => ['Unknown expression identifier `nocol` in scope SELECT nocol FROM pr_p WHERE id = ***. (UNKNOWN_IDENTIFIER)'],
  },
  {
    name   => 'While processing, a mutation',
    raw    => q~Code: 38. DB::Exception: Cannot parse date: value is too short: Cannot parse Date from String: While processing _CAST(if(id = '3', _CAST('geheim54', 'Date'), d), 'Date'). (CANNOT_PARSE_DATE)~,
    secret => ['geheim54', "'3'"],
    keep   => ['While processing _CAST(if(id = ***, _CAST(***, ***), d), ***). (CANNOT_PARSE_DATE)'],
  },
  {
    name   => 'Syntax error, an update of a key',
    raw    => q~Code: 62. DB::Exception: Syntax error: failed at position 1 (UPDATE): UPDATE pr_p SET id = '987654321' WHERE id = 3. Expected one of: Query, Query with output, EXPLAIN, SELECT query, possibly with UNION, list of union elements. (SYNTAX_ERROR)~,
    secret => ['987654321'],
    keep   => ['Syntax error: failed at position 1 (UPDATE): UPDATE pr_p SET id = *** WHERE id = ***. Expected one of: Query, Query with output, EXPLAIN, SELECT query, possibly with UNION, list of union elements. (SYNTAX_ERROR)'],
  },
  {
    name   => 'Syntax error, a literal is the token',
    raw    => q~Code: 62. DB::Exception: Syntax error: failed at position 19 ('geheim65'): 'geheim65' FROM pr_p. Expected one of: OR, AND, alias. (SYNTAX_ERROR)~,
    secret => ['geheim65'],
    keep   => ['Syntax error: failed at position 19 (***): *** FROM pr_p. Expected one of: OR, AND, alias.'],
  },
  {
    name   => 'Syntax error, a number is the token',
    raw    => q~Code: 62. DB::Exception: Syntax error: failed at position 14 (678): 678. Expected one of: token, DoubleColon, OR. (SYNTAX_ERROR)~,
    secret => ['678'],
    keep   => ['failed at position 14 (***): ***. Expected one of: token, DoubleColon, OR.'],
  },
  {
    name   => 'Syntax error, end of query with a value in front of it',
    raw    => q~Code: 62. DB::Exception: Syntax error: failed at position 43 (end of query): . Expected one of: OR, AND. (SYNTAX_ERROR)~,
    secret => [],
    keep   => ['failed at position 43 (end of query): . Expected one of: OR, AND. (SYNTAX_ERROR)'],
  },
  {
    name   => 'Syntax error, a multi-statement text and no list of expectations',
    raw    => q~Code: 62. DB::Exception: Syntax error (Multi-statements are not allowed): failed at position 9 (end of query): ; SELECT 'geheim97'. . (SYNTAX_ERROR)~,
    secret => ['geheim97'],
    keep   => ['Syntax error (Multi-statements are not allowed): failed at position 9 (end of query): ; SELECT ***. . (SYNTAX_ERROR)'],
  },
  {
    name   => 'Syntax error, a string with a quote, a colon and a bracket in the statement',
    raw    => qq~Code: 62. DB::Exception: Syntax error: failed at position 30 ('x'): 'x' = 'ge\\'heim): z\nzeile' AND a = 7. Expected one of: AND. (SYNTAX_ERROR)~,
    secret => ['heim', "z\nzeile", 'zeile'],
    keep   => ['failed at position 30 (***): ', 'AND a = ***. Expected one of: AND. (SYNTAX_ERROR)'],
  },
  {
    name   => 'Column values, a constraint',
    raw    => q~Code: 469. DB::Exception: Constraint `bnn` for table dbio_ch_probe_1.ck (39b0ec4d-15b0-42ec-a651-3d20c88a3e95) is violated at row 1. Expression: (b != 'x'). Column values: a = -5, b = 'x'. (VIOLATED_CONSTRAINT)~,
    secret => ['-5'],
    keep   => ['Constraint `bnn` for table dbio_ch_probe_1.ck (39b0ec4d-15b0-42ec-a651-3d20c88a3e95) is violated at row 1. Expression: (b != \'x\'). Column values: a = ***, b = ***. (VIOLATED_CONSTRAINT)'],
  },
  {
    name   => 'Column values, a string with a comma, a name, a quote and a newline',
    raw    => q~Code: 469. DB::Exception: Constraint `c` for table d.t (u) is violated at row 2. Expression: (a > 0). Column values: a = 1, b = 'x, y = \'q\'\nz', c = 3. (VIOLATED_CONSTRAINT)~,
    secret => ['x, y', 'q\\', '\nz'],
    keep   => ['Column values: a = ***, b = ***, c = ***. (VIOLATED_CONSTRAINT)', 'at row 2.'],
  },
  {
    name   => 'Column values, a compound value is masked as a whole',
    raw    => q~Code: 469. DB::Exception: Constraint `c` for table d.t (u) is violated at row 1. Expression: (a > 0). Column values: a = ['x, b = y', 'z'], b = 1. (VIOLATED_CONSTRAINT)~,
    secret => ['x, b', 'b = y', "'z'"],
    keep   => ['Column values: ***. (VIOLATED_CONSTRAINT)', 'Constraint `c` for table d.t (u)'],
  },
  {
    name   => 'Value for a field of a date',
    raw    => q~Code: 41. DB::Exception: Value 60913 for year must be in the range [1970, 2106]: In scope SELECT parseDateTime('geheim127', '%Y'). (CANNOT_PARSE_DATETIME)~,
    secret => ['60913', 'geheim127'],
    keep   => ['Value *** for year must be in the range [1970, 2106]'],
  },
  {
    name   => 'A regular expression the engine cannot compile',
    raw    => q~Code: 427. DB::Exception: OptimizedRegularExpression: cannot compile re2: (geheim129, error: missing ): (geheim129. Look at https://github.com/google/re2/wiki/Syntax for reference.: In scope SELECT match('a', '(geheim129'). (CANNOT_COMPILE_REGEXP)~,
    secret => ['geheim129'],
    keep   => ['cannot compile re2: ***, error: missing ): ***. Look at https://github.com/google/re2/wiki/Syntax'],
  },
);

# Texts without a value in them, or of a form the sentences do not know.
my @plain = (
  q~Code: 420. DB::Exception: Cannot UPDATE key column `id`. (CANNOT_UPDATE_COLUMN)~,
  q~Code: 60. DB::Exception: Table dbio_ch_probe_1.nope does not exist. Maybe you meant system.one?. (UNKNOWN_TABLE)~,
  q~Code: 115. DB::Exception: Setting foo_bar is neither a builtin setting nor started with the prefix 'SQL_' registered for user-defined settings. (UNKNOWN_SETTING)~,
  q~Code: 131. DB::Exception: String too long for type FixedString(3). (TOO_LARGE_STRING_SIZE)~,
  q~Code: 386. DB::Exception: There is no supertype for types String, UInt8 because some of them are String/FixedString/Enum and some of them are not. (NO_COMMON_TYPE)~,
  'DBD::mysql::st execute failed: connection lost',
  "a text\nof two lines",
  "'quoted' text with 12 numbers",
);

plan tests => 5 * @cases + @plain + 9;

for my $case (@cases) {
  my $raw = $case->{raw} . $VERSION_TAIL;

  # the premise: the raw text does hold what the case says must go
  my $holds = 1;
  for my $secret (@{ $case->{secret} }) {
    $holds = 0 unless index($raw, $secret) >= 0;
  }
  ok $holds, "$case->{name}: the raw text holds the value";

  my $masked = mask_error_details($raw);

  my @left = grep { index($masked, $_) >= 0 } @{ $case->{secret} };
  ok !@left, "$case->{name}: no value is left"
    or diag "left: @left\nmasked: $masked";

  my @lost = grep { index($masked, $_) < 0 } @{ $case->{keep} };
  ok !@lost, "$case->{name}: code, type, column, constraint and position stay"
    or diag "lost: @lost\nmasked: $masked";

  like $masked, qr/\Q$VERSION_TAIL\E\z/, "$case->{name}: the version of the engine stays";

  is mask_error_details($masked), $masked, "$case->{name}: masking a masked text changes nothing";
}

for my $text (@plain) {
  is mask_error_details($text), $text, "a text without a value is returned as it is: " . substr($text =~ s/\n/ /gr, 0, 50);
}

# the form of the family: the value goes, the words around it stay
is mask_error_details(q~Code: 6. DB::Exception: Cannot parse string 'geheim42' as Int32: syntax error. (CANNOT_PARSE_TEXT)~),
  q~Code: 6. DB::Exception: Cannot parse string '***' as Int32: syntax error. (CANNOT_PARSE_TEXT)~,
  'a quoted value is replaced between its quotes';

is mask_error_details(q~Column values: a = 1, b = 'x'~),
  q~Column values: a = ***, b = ***~,
  'column values without a code behind them: names stay, values go';

is mask_error_details(q~In scope SELECT CAST('geheim45', 'INTEGER') FROM pr_p~),
  q~In scope SELECT CAST(***, ***) FROM pr_p~,
  'a statement without a code behind it is masked up to its end';

like mask_error_details(q~Syntax error: failed at position 1 (UPDATE): UPDATE t SET id = 'geheim' WHERE id = 3~),
  qr/\ASyntax error: failed at position 1 \(UPDATE\): UPDATE t SET id = \*\*\* WHERE id = \*\*\*\z/,
  'a syntax error without an expectation behind it is masked up to its end';

# a cut-off string at the end of an excerpt is a value up to the end
is mask_error_details(q~In scope SELECT 'geheim cut o~),
  q~In scope SELECT ***~,
  'a string that is cut off is masked up to the end';

is mask_error_details(undef), undef, 'undef is returned as undef';
is mask_error_details(''), '', 'the empty text is returned as it is';

my $ref = [];
is mask_error_details($ref), $ref, 'a reference (an exception object) is returned as it is';

# the premise of the table: DBD::mysql's wording of a failed statement is
# DBI's, around the engine's text; the engine's part is masked in it
is mask_error_details(q~DBD::mysql::st execute failed: Code: 53. DB::Exception: Cannot convert string 'geheim56' to type Int32. (TYPE_MISMATCH) (version 25.3.14.14 (official build)) at /x/y.pl line 3.~),
  q~DBD::mysql::st execute failed: Code: 53. DB::Exception: Cannot convert string '***' to type Int32. (TYPE_MISMATCH) (version 25.3.14.14 (official build)) at /x/y.pl line 3.~,
  'the words of DBI around the text of the engine stay';

