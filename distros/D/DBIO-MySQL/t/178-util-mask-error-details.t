use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Util qw(mask_error_details);

# WHY IT MATTERS. MySQL and MariaDB write the value of a bind into their error
# text ("Incorrect integer value: 'x' for column 'i'", "Duplicate entry 'x' for
# key ..."), and both DBDs put the values into the statement text themselves, so
# a syntax error quotes them in its near '...' excerpt. The family's rule is
# that an error message names keys, columns and options, never values.
# mask_error_details is the driver's one place that keeps the engine's text to
# it. Claims, each one in the table below:
#   a. every sentence of the engine that quotes a value keeps its type, column,
#      constraint, key and position, and loses the value -- whatever quotes,
#      commas, newlines or backslashes the value holds;
#   b. in a syntax error's near '...' excerpt every quoted literal goes (the
#      statement's own with the bound ones), also one the server cut off at the
#      edge of the excerpt, and a bare number, which a typed bind is;
#   c. a text of no known form, and every error without a value, is unchanged;
#   d. a bound value of four characters or more is also replaced where it stands
#      verbatim, in the form DBD quote() gives it as well;
#   e. the result masked again is the result.
# The raw texts are what DBD::mysql 4.055 and DBD::MariaDB 1.24 returned from
# MySQL 8.0.30 and MariaDB 11.8 (server_prepare on or off, the same text).

my $MARK = qr/geheim|sekret|dupmark/;

sub syn {
  my ($product, $excerpt) = @_;
  return "You have an error in your SQL syntax; check the manual that corresponds to your $product server version for the right syntax to use near '$excerpt' at line 1";
}

my @cases = (
  # --- Incorrect <type> value: '...' for column / function
  [ 'integer, MySQL column',
    q{Incorrect integer value: 'geheim42' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, MariaDB column',
    q{Incorrect integer value: 'geheim42' for column `dbio_test`.`fw_t`.`i` at row 1},
    q{Incorrect integer value: '***' for column `dbio_test`.`fw_t`.`i` at row 1} ],
  [ 'integer, a quote in the value',
    q{Incorrect integer value: 'a'b' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, quotes and a comma',
    q{Incorrect integer value: 'a"b, c: 'geheim42' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, the words of the sentence in the value',
    q{Incorrect integer value: 'x' for column 'geheim42' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, a newline in the value',
    qq{Incorrect integer value: 'ab\ncdgeheim42' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, a backslash in the value',
    q{Incorrect integer value: 'a\bgeheim42' for column 'i' at row 1},
    q{Incorrect integer value: '***' for column 'i' at row 1} ],
  [ 'integer, BOOLEAN column',
    q{Incorrect integer value: 'bogeheim42' for column 'bo' at row 1},
    q{Incorrect integer value: '***' for column 'bo' at row 1} ],
  [ 'integer, insert ... on duplicate key update',
    q{Incorrect integer value: 'okgeheim42' for column 'i' at row 2},
    q{Incorrect integer value: '***' for column 'i' at row 2} ],
  [ 'date',
    q{Incorrect date value: 'nodategeheim42' for column 'd' at row 1},
    q{Incorrect date value: '***' for column 'd' at row 1} ],
  [ 'date, a short value',
    q{Incorrect date value: 'ab' for column 'd' at row 1},
    q{Incorrect date value: '***' for column 'd' at row 1} ],
  [ 'datetime, MariaDB',
    q{Incorrect datetime value: 'nodtgeheim42' for column `dbio_test`.`fw_t`.`dt` at row 1},
    q{Incorrect datetime value: '***' for column `dbio_test`.`fw_t`.`dt` at row 1} ],
  [ 'decimal',
    q{Incorrect decimal value: 'decgeheim42' for column 'dec1' at row 1},
    q{Incorrect decimal value: '***' for column 'dec1' at row 1} ],
  [ 'time, MariaDB',
    q{Incorrect time value: 'tmgeheim42' for column `dbio_test`.`fw_t`.`tm` at row 1},
    q{Incorrect time value: '***' for column `dbio_test`.`fw_t`.`tm` at row 1} ],
  [ 'double, MariaDB',
    q{Incorrect double value: 'dblgeheim42' for column `dbio_test`.`fw_t`.`f` at row 1},
    q{Incorrect double value: '***' for column `dbio_test`.`fw_t`.`f` at row 1} ],
  [ 'string, the bytes of the value (MySQL)',
    q{Incorrect string value: '\xE9gehei...' for column 't' at row 1},
    q{Incorrect string value: '***' for column 't' at row 1} ],
  [ 'string, the bytes of the value (MariaDB)',
    q{Incorrect string value: '\xF0\x9F\x98\x80ge...' for column `dbio_test`.`fw_u8`.`s` at row 1},
    q{Incorrect string value: '***' for column `dbio_test`.`fw_u8`.`s` at row 1} ],
  [ 'string, a short value in a function',
    q{Incorrect string value: 'notuuidgeheim42' for function uuid_to_bin},
    q{Incorrect string value: '***' for function uuid_to_bin} ],

  # --- Truncated incorrect <type> value: '...'
  [ 'truncated DOUBLE',
    q{Truncated incorrect DOUBLE value: 'trgeheim42'},
    q{Truncated incorrect DOUBLE value: '***'} ],
  [ 'truncated INTEGER, a quote in the value',
    q{Truncated incorrect INTEGER value: '9x'geheim42'},
    q{Truncated incorrect INTEGER value: '***'} ],
  [ 'truncated, the Perl location behind it',
    q{Truncated incorrect DOUBLE value: 'trgeheim42' at /srv/app/x.pl line 90.},
    q{Truncated incorrect DOUBLE value: '***' at /srv/app/x.pl line 90.} ],

  # --- Duplicate entry '...' for key '...'
  [ 'duplicate, MySQL primary key',
    q{Duplicate entry '1' for key 'fw_t.PRIMARY'},
    q{Duplicate entry '***' for key 'fw_t.PRIMARY'} ],
  [ 'duplicate, MariaDB primary key',
    q{Duplicate entry '1' for key 'PRIMARY'},
    q{Duplicate entry '***' for key 'PRIMARY'} ],
  [ 'duplicate, unique key',
    q{Duplicate entry 'dupmark1' for key 'fw_t.fw_uq'},
    q{Duplicate entry '***' for key 'fw_t.fw_uq'} ],
  [ 'duplicate, a composite key is one text',
    q{Duplicate entry '1-x' for key 'fw_c.PRIMARY'},
    q{Duplicate entry '***' for key 'fw_c.PRIMARY'} ],
  [ 'duplicate, quotes in the value',
    q{Duplicate entry 'dup'q"xgeheim42' for key 'fw_t.fw_uq'},
    q{Duplicate entry '***' for key 'fw_t.fw_uq'} ],
  [ 'duplicate, the key sentence in the value',
    q{Duplicate entry 'a' for key 'geheim42' for key 'fw_uq'},
    q{Duplicate entry '***' for key 'fw_uq'} ],
  [ 'duplicate, a newline in the value',
    qq{Duplicate entry 'nl\nlinegeheim42' for key 'fw_uq'},
    q{Duplicate entry '***' for key 'fw_uq'} ],
  [ 'duplicate, a long value cut by MariaDB',
    q{Duplicate entry 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...' for key 'fw_uq'},
    q{Duplicate entry '***' for key 'fw_uq'} ],
  [ 'duplicate, behind the DBD prefix',
    q{DBD::mysql::st execute failed: Duplicate entry 'dupmark1' for key 'fw_t.fw_uq' at /srv/app/x.pl line 7.},
    q{DBD::mysql::st execute failed: Duplicate entry '***' for key 'fw_t.fw_uq' at /srv/app/x.pl line 7.} ],
  [ 'duplicate, no key part behind it: all that follows goes',
    q{Duplicate entry 'dupmark1 and more},
    q{Duplicate entry '***'} ],

  # --- the other sentences that quote a value
  [ 'invalid character string (MariaDB)',
    q{Invalid utf8mb4 character string: '\xFFA'},
    q{Invalid utf8mb4 character string: '***'} ],
  [ 'cannot convert character (MariaDB)',
    q{Cannot convert 'utf8mb4' character 0xC3A9 to 'ascii'},
    q{Cannot convert 'utf8mb4' character *** to 'ascii'} ],
  [ 'cannot convert string',
    q{Cannot convert string '\xFF\xFEgeheim42' from binary to utf8mb4},
    q{Cannot convert string '***' from binary to utf8mb4} ],
  [ 'time zone',
    q{Unknown or incorrect time zone: 'geheim42'},
    q{Unknown or incorrect time zone: '***'} ],
  [ 'system variable value',
    q{Variable 'sql_mode' can't be set to the value of 'geheim42'},
    q{Variable 'sql_mode' can't be set to the value of '***'} ],
  [ 'character set',
    q{Unknown character set: 'geheim42'},
    q{Unknown character set: '***'} ],
  [ 'collation',
    q{Unknown collation: 'geheim42'},
    q{Unknown collation: '***'} ],
  [ 'precision named by a bind, MariaDB',
    q{Too big precision specified for '1e9999geheim42'. Maximum is 65},
    q{Too big precision specified for '***'. Maximum is 65} ],
  [ 'precision named by a bind, MySQL',
    q{Too-big precision 70 specified for ''1e9999geheim42''. Maximum is 65.},
    q{Too-big precision 70 specified for '***'. Maximum is 65.} ],

  # --- syntax error: near '...'
  [ 'syntax, a bound value in the excerpt',
    syn('MySQL', q{fw_t where s = 'geheimsyn1'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, two bound values',
    syn('MariaDB', q{fw_t where s = 'geheimA' and uq = 'geheimB'}),
    syn('MariaDB', q{fw_t where s = *** and uq = ***}) ],
  [ 'syntax, quotes escaped by the DBD',
    syn('MySQL', q{fw_t where s = 'it\'s geheim\"q'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, a newline escaped by the DBD',
    syn('MySQL', q{fw_t where s = 'ab\ngeheimnl\ncd'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, a real newline in the literal and in the statement',
    syn('MariaDB', qq{fw_t\nwhere s = 'ab\ngeheimnl'\n  and 5 = i}),
    syn('MariaDB', qq{fw_t\nwhere s = ***\n  and *** = i}) ],
  [ 'syntax, a backslash at the end of the value',
    syn('MySQL', q{fw_t where s = 'ab\\\\'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, an empty value',
    syn('MySQL', q{fw_t where s = ''}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, a quote that is doubled in a literal',
    syn('MySQL', q{fw_t where s = 'it''s lit' and i = 'geheimd'}),
    syn('MySQL', q{fw_t where s = *** and i = ***}) ],
  [ 'syntax, a double-quoted literal of the statement goes with the bound one',
    syn('MySQL', q{fw_t where s = "lit" and i = 'geheimd'}),
    syn('MySQL', q{fw_t where s = *** and i = ***}) ],
  [ 'syntax, a literal of the statement does not stay',
    syn('MariaDB', q{foo2 'litsecond'}),
    syn('MariaDB', q{foo2 ***}) ],
  [ 'syntax, the fake end of the excerpt in the value',
    syn('MySQL', q{fw_t where s = 'x\' at line 1 geheimF'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, the fake start of the excerpt in the value',
    syn('MySQL', q{fw_t where s = 'x\' near \'geheimN'}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, a literal cut at the edge (MySQL)',
    syn('MySQL', q{fw_t where s = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxgeheim}),
    syn('MySQL', q{fw_t where s = ***}) ],
  [ 'syntax, a literal cut at the edge (MariaDB, with the dots)',
    syn('MariaDB', q{fw_t where s = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxgeheim...}),
    syn('MariaDB', q{fw_t where s = ***}) ],
  [ 'syntax, the excerpt starts with the value',
    syn('MySQL', q{'geheim42'))}),
    syn('MySQL', q{***))}) ],
  [ 'syntax, a value in a type size',
    syn('MariaDB', q{'geheim42', 2))}),
    syn('MariaDB', q{***, ***))}) ],
  [ 'syntax, a bare number (a typed bind)',
    syn('MySQL', q{fw_t where i = 424242}),
    syn('MySQL', q{fw_t where i = ***}) ],
  [ 'syntax, a short bare number',
    syn('MariaDB', q{fw_t where i = 7}),
    syn('MariaDB', q{fw_t where i = ***}) ],
  [ 'syntax, a negative and a decimal number',
    syn('MySQL', q{fw_t where n = -5 or n = 3.14159 or n = 1.5e10}),
    syn('MySQL', q{fw_t where n = *** or n = *** or n = ***}) ],
  [ 'syntax, names with digits stay',
    syn('MySQL', q{fw_t2 where t1.c2 = 'geheim42'}),
    syn('MySQL', q{fw_t2 where t1.c2 = ***}) ],
  [ 'syntax, a quoted name stays, a quote inside it does not open a literal',
    syn('MySQL', q{`o'rder` = 'geheim42' limit 5}),
    syn('MySQL', q{`o'rder` = *** limit ***}) ],
  [ 'syntax, NULL stays',
    syn('MySQL', q{fw_t where s = NULL}),
    syn('MySQL', q{fw_t where s = NULL}) ],
  [ 'syntax, the statement before the first literal stays',
    syn('MySQL', q{GARBAGE 'geheimsyn3'}),
    syn('MySQL', q{GARBAGE ***}) ],
  [ 'syntax, behind the DBD prefix and with the Perl location',
    q{DBD::mysql::st execute failed: } . syn('MySQL', q{fw_t where s = 'geheimsyn1'}) . q{ at /srv/app/x.pl line 90.},
    q{DBD::mysql::st execute failed: } . syn('MySQL', q{fw_t where s = ***}) . q{ at /srv/app/x.pl line 90.} ],
  [ 'syntax, a message that lost its end: all that follows near goes',
    q{You have an error in your SQL syntax; for the right syntax to use near 'a = 'geheim42' and},
    q{You have an error in your SQL syntax; for the right syntax to use near '***'} ],

  # --- no value in the text: unchanged
  [ 'unchanged: data truncated',      q{Data truncated for column 'e' at row 1} ],
  [ 'unchanged: data too long',       q{Data too long for column 's' at row 1} ],
  [ 'unchanged: out of range',        q{Out of range value for column 'ti' at row 1} ],
  [ 'unchanged: not null',            q{Column 'i' cannot be null} ],
  [ 'unchanged: check, MySQL',        q{Check constraint 'fw_ck_chk_1' is violated.} ],
  [ 'unchanged: check, MariaDB',      q{CONSTRAINT `CONSTRAINT_1` failed for `dbio_test`.`fw_ck`} ],
  [ 'unchanged: json column, MariaDB', q{CONSTRAINT `fw_t.j` failed for `dbio_test`.`fw_t`} ],
  [ 'unchanged: json text, MySQL',
    q{Invalid JSON text: "Missing a name for object member." at position 1 in value for column 'fw_t.j'.} ],
  [ 'unchanged: foreign key child',
    q{Cannot add or update a child row: a foreign key constraint fails (`dbio_test`.`fw_ch`, CONSTRAINT `fw_fk` FOREIGN KEY (`pid`) REFERENCES `fw_p` (`id`))} ],
  [ 'unchanged: foreign key parent',
    q{Cannot delete or update a parent row: a foreign key constraint fails (`dbio_test`.`fw_ch`, CONSTRAINT `fw_fk` FOREIGN KEY (`pid`) REFERENCES `fw_p` (`id`))} ],
  [ 'unchanged: collation mix',
    q{Illegal mix of collations (utf8mb4_unicode_ci,COERCIBLE) and (utf8mb4_uca1400_ai_ci,COERCIBLE) for operation 'regexp'} ],
  [ 'unchanged: collation conversion',
    q{Conversion from collation utf8mb4_general_ci into latin1_swedish_ci impossible for parameter} ],
  [ 'unchanged: unknown column',      q{Unknown column 'zzz' in 'where clause'} ],
  [ 'unchanged: unknown table',       q{Table 'dbio_test.nosuch' doesn't exist} ],
  [ 'unchanged: bind count',          q{called with 1 bind variables when 2 are needed} ],
  [ 'unchanged: syntax without a literal', syn('MySQL', q{bogus}) ],
  [ 'unchanged: syntax at the end',   syn('MariaDB', q{}) ],
  [ 'unchanged: syntax, prepared with the placeholders',
    syn('MySQL', q{fw_t where s = ?}) ],
  [ 'unchanged: no sentence of the engine', q{something else went wrong} ],
);

for my $case (@cases) {
  my ($name, $raw, $want) = @$case;
  $want = $raw unless defined $want;

  my $got = mask_error_details($raw);
  is $got, $want, $name;
  unlike $got, $MARK, "$name: no value left";
  is mask_error_details($got), $got, "$name: masking the result changes nothing";
  is mask_error_details($raw, [ 'geheim42', 7 ], 'SELECT 1'), $want,
    "$name: the same with binds and a statement";
}

# --- the verbatim replacement of bound values (c, d)
{
  my $text = q{Server said geheim42 and also geheim\'x here, ab too, caf} . "\xc3\xa9" . q{x end};
  my @binds = ('geheim42', q{geheim'x}, 'ab', undef, \'refgeheim', "caf\x{e9}x");
  is mask_error_details($text, \@binds),
    q{Server said *** and also *** here, ab too, ***} . q{ end},
    'a bound value of four characters or more is found verbatim, escaped as DBD quote() writes it, or as bytes';
  like mask_error_details($text, \@binds), qr/\bab\b/, 'a value of three characters or less is not looked for';
  is mask_error_details(q{a "q""d" b}, [ q{"q""d"} ]), q{a *** b}, 'a value with quotes of its own';
  is mask_error_details(qq{a x\\ny\\0z\\Z b}, [ qq{x\ny\0z\x1a} ]),
    q{a *** b}, 'a value with a newline, a NUL and a ^Z, as DBD writes them';
  is mask_error_details(q{unchanged text}, [ 'geheim42' ]), q{unchanged text}, 'a bound value not in the text changes nothing';
  is mask_error_details(q{unchanged text}, undef, undef), q{unchanged text}, 'binds and statement are optional';
}

# --- the messages that have nothing to mask
is mask_error_details(undef), undef, 'undef stays undef';
is mask_error_details(''), '', 'an empty message stays empty';

# --- a whole run of text: every value goes, nothing else does
{
  my $raw = q{DBD::MariaDB::st execute failed: Duplicate entry 'dupmark1' for key 'fw_uq'};
  my $got = mask_error_details($raw, [ 'dupmark1' ]);
  is $got, q{DBD::MariaDB::st execute failed: Duplicate entry '***' for key 'fw_uq'},
    'a value that is both in a sentence and in the binds is masked once';
}

done_testing;
