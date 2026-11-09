#!/usr/bin/env perl
# t/128-error-mask-unit.t -- DBIO::MSSQL::Util::mask_error_details on the
# server's texts, without a server.
#
# WHY this matters: a message names keys, columns and options, never values.
# The masker is the one place that knows the sentences of SQL Server that quote
# a value. Each form maps a text with a value to the same text with *** in its
# place; type, table, column and constraint stay. The rules work on the text
# inside the frame of either DBD, and a text they do not know is not touched.

use strict;
use warnings;
use Test::More;
use Time::HiRes ();
use DBIO::MSSQL::Util ();

sub mask { DBIO::MSSQL::Util::mask_error_details(@_) }

sub odbc { "[FreeTDS][SQL Server]$_[0] (SQL-22018)" }
sub syb  { "Server message number=245 severity=16 state=1 line=1 server=DBIO text=$_[0]" }
my $terminated = 'The statement has been terminated.';
sub syb2 {
  syb($_[0]) . "\nServer message number=3621 severity=0 state=0 line=1 server=DBIO text=$terminated";
}
sub odbc2 { odbc($_[0]) . "\n[FreeTDS][SQL Server]$terminated (SQL-01000)" }

my @frames = (
  [ bare => sub { $_[0] } ],
  [ odbc => \&odbc ],
  [ sybase => \&syb ],
  [ 'sybase, two messages' => \&syb2 ],
  [ 'odbc, two messages' => \&odbc2 ],
);

my @forms = (
  [ "Conversion failed when converting the varchar value 'geheim42' to data type int.",
    "Conversion failed when converting the varchar value '***' to data type int." ],
  [ "Conversion failed when converting the nvarchar value 'geheim42' to data type bigint.",
    "Conversion failed when converting the nvarchar value '***' to data type bigint." ],
  [ "Conversion failed when converting the char value 'geheim42' to data type decimal.",
    "Conversion failed when converting the char value '***' to data type decimal." ],
  [ "Conversion failed when converting the nchar value 'ab' to data type int.",
    "Conversion failed when converting the nchar value '***' to data type int." ],
  [ "Conversion failed when converting the varchar value '7' to data type int.",
    "Conversion failed when converting the varchar value '***' to data type int." ],
  [ "Conversion failed when converting the varchar value 'geheim42 it''s, a: \"b\"\nline2' to data type int.",
    "Conversion failed when converting the varchar value '***' to data type int." ],
  [ "Conversion failed when converting the varchar value '' to data type int.",
    "Conversion failed when converting the varchar value '***' to data type int." ],
  [ "The conversion of the varchar value '3000000000' overflowed an INT2 column. Use a larger integer column.",
    "The conversion of the varchar value '***' overflowed an INT2 column. Use a larger integer column." ],
  [ "The conversion of the nvarchar value 'geheim42' overflowed an INT1 column. Use a larger integer column.",
    "The conversion of the nvarchar value '***' overflowed an INT1 column. Use a larger integer column." ],
  [ "The conversion of the varchar value '99999999999' overflowed an int column.",
    "The conversion of the varchar value '***' overflowed an int column." ],
  [ "Violation of PRIMARY KEY constraint 'pk_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (11, 22).",
    "Violation of PRIMARY KEY constraint 'pk_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***)." ],
  [ "Violation of UNIQUE KEY constraint 'uq_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (geheim42\@x.y).",
    "Violation of UNIQUE KEY constraint 'uq_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***)." ],
  [ "Violation of PRIMARY KEY constraint 'pk_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (<NULL>).",
    "Violation of PRIMARY KEY constraint 'pk_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***)." ],
  [ "Cannot insert duplicate key row in object 'dbo.t' with unique index 'ix'. The duplicate key value is (a) b, geheim42, 7).",
    "Cannot insert duplicate key row in object 'dbo.t' with unique index 'ix'. The duplicate key value is (***)." ],
  [ "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: 'geheim42'.",
    "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: '***'." ],
  [ "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: ''.",
    "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: '***'." ],
  [ "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: 'it''s geheim42 '.",
    "String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: '***'." ],
  [ "Incorrect syntax near 'GARBAGE'.",
    "Incorrect syntax near '***'." ],
  [ "Incorrect syntax near 'geheim42 it''s'.",
    "Incorrect syntax near '***'." ],
  [ "JSON text is not properly formatted. Unexpected character 'g' is found at position 1.",
    "JSON text is not properly formatted. Unexpected character '***' is found at position 1." ],
  [ "JSON text is not properly formatted. Unexpected character ''' is found at position 12.",
    "JSON text is not properly formatted. Unexpected character '***' is found at position 12." ],
);

for my $f (@forms) {
  my ($in, $out) = @$f;
  (my $name = $in) =~ s/\n/ /g;
  $name = substr $name, 0, 70;
  for my $frame (@frames) {
    my ($fname, $wrap) = @$frame;
    my $got = mask($wrap->($in));
    is $got, $wrap->($out), "$name [$fname]";
    is mask($got), $got, '  idempotent';
    unlike $got, qr/geheim42/, '  marker gone';
  }
}

# Texts that hold no value or are not known stay as they are, in every frame.
my @unchanged = (
  q{The INSERT statement conflicted with the FOREIGN KEY constraint "fk_t_p". The conflict occurred in database "tempdb", table "dbo.p", column 'id'.},
  q{Violation of FOREIGN KEY constraint 'fk_t_p'. The conflict occurred in database "tempdb", table "dbo.p".},
  q{Cannot insert the value NULL into column 'b', table 'tempdb.dbo.t'; column does not allow nulls. INSERT fails.},
  q{Cannot insert explicit value for identity column in table 't' when IDENTITY_INSERT is set to OFF.},
  q{Arithmetic overflow error converting expression to data type int.},
  q{Error converting data type varchar to numeric.},
  q{Operand type clash: uniqueidentifier is incompatible with int},
  q{Conversion failed when converting from a character string to uniqueidentifier.},
  q{Conversion failed when converting date and/or time from character string.},
  q{The INSERT statement conflicted with the CHECK constraint "ck_t". The conflict occurred in database "d", table "dbo.t", column 'c'.},
  q{Incorrect syntax near the keyword 'FROM'.},
  q{Incorrect syntax near ).},
  q{Incorrect syntax near GARBAGE.},
  q{Invalid object name 'dbo.nothere'.},
  q{something nobody has seen: geheim42},
);
for my $text (@unchanged) {
  for my $frame (@frames) {
    my ($fname, $wrap) = @$frame;
    is mask($wrap->($text)), $wrap->($text), "left as it is [$fname]: " . substr($text, 0, 60);
  }
}
is mask(''), '', 'empty stays empty';
is mask(undef), undef, 'undef stays undef';

# Bound values elsewhere in the text: four characters or more, longest first,
# also as the string literal DBI->quote makes of them.
{
  my $text = q{Invalid object name 'geheim42'.};
  is mask($text, [ 'geheim42' ]), q{Invalid object name '***'.}, 'a bound name';
  is mask(odbc($text), [ 'geheim42' ]), odbc(q{Invalid object name '***'.}), 'a bound name, odbc frame';
  is mask(syb2($text), [ 'geheim42' ]), syb2(q{Invalid object name '***'.}), 'a bound name, sybase frame';

  my $m = mask(q{Invalid object name 'it''s a: "b", geheim42'.}, [ q{it's a: "b", geheim42} ]);
  unlike $m, qr/geheim42/, 'a value with apostrophe, comma, colon and quote: found in its literal form';
  is $m, q{Invalid object name '***'.}, '  and replaced whole';

  $m = mask("Invalid object name 'line1\nline2geheim42'.", [ "line1\nline2geheim42" ]);
  is $m, q{Invalid object name '***'.}, 'a value with a line break';

  is mask('Invalid object name geheim42abc', [ 'geheim42', 'geheim42abc' ]),
    'Invalid object name ***', 'the longest value first';
  is mask(q{Invalid object name 'ab'.}, [ 'ab', 7, undef, \'ref', '' ]), q{Invalid object name 'ab'.},
    'short, undefined and reference binds are no reason to change a text';
  is mask(q{Invalid object name 'geheim42'.}, [ 'geheim42' ], 'SELECT 1'), q{Invalid object name '***'.},
    'the statement is accepted';
  my $once = mask($text, [ 'geheim42' ]);
  is mask($once, [ 'geheim42' ]), $once, 'idempotent with binds';
}

# The duplicate key value masks up to the last ")." of the text.
{
  my $in = "Violation of PRIMARY KEY constraint 'pk'. The duplicate key value is (a). b, (c).";
  is mask($in), "Violation of PRIMARY KEY constraint 'pk'. The duplicate key value is (***).",
    'a value holding ")." is masked whole';
}

# The server writes an apostrophe of a value as it is (only "Truncated value"
# doubles it), and the value may hold the words that close the sentence.
{
  my @raw = (
    [ "Conversion failed when converting the varchar value 'a'b' to data type int.",
      "Conversion failed when converting the varchar value '***' to data type int." ],
    [ "Conversion failed when converting the varchar value ''' to data type bit.",
      "Conversion failed when converting the varchar value '***' to data type bit." ],
    [ "Conversion failed when converting the varchar value 'a' to data type int. b' to data type int.",
      "Conversion failed when converting the varchar value '***' to data type int." ],
    [ "Conversion failed when converting the nvarchar value 'x'y' to data type numeric(5,2).",
      "Conversion failed when converting the nvarchar value '***' to data type numeric(5,2)." ],
    [ "The conversion of the varchar value 'a'3000000000' overflowed an INT1 column. Use a larger integer column.",
      "The conversion of the varchar value '***' overflowed an INT1 column. Use a larger integer column." ],
    [ "Incorrect syntax near 'it's'.",
      "Incorrect syntax near '***'." ],
    [ "Incorrect syntax near 'it's x'.",
      "Incorrect syntax near '***'." ],
  );
  for my $c (@raw) {
    my ($in, $out) = @$c;
    for my $frame (@frames) {
      my ($fname, $wrap) = @$frame;
      my $got = mask($wrap->($in));
      is $got, $wrap->($out), "apostrophe as it is [$fname]: " . substr($in, 0, 60);
      is mask($got), $got, '  idempotent';
    }
  }

  # the failing conversion of the TEXTSIZE guard names a column, no value
  my $guard = "Conversion failed when converting the varchar value 'DBIO::MSSQL TEXTSIZE guard: column 'body' holds a value longer than the session's TEXTSIZE, 32768 bytes' to data type int.";
  is mask($guard), $guard, 'the TEXTSIZE guard text is left as it is';
  is mask(syb($guard)), syb($guard), '  also in the sybase frame';
}

# The server cuts a message at about 2000 characters: a long value then runs to
# the end of the message, without its closing quote and the words behind it.
{
  my $long = 'geheim42' . ('x' x 3000);
  my @cut = (
    [ "Conversion failed when converting the varchar value '$long",
      "Conversion failed when converting the varchar value '***'" ],
    [ "The conversion of the nvarchar value '$long",
      "The conversion of the nvarchar value '***'" ],
    [ "String or binary data would be truncated in table 't', column 's'. Truncated value: '$long",
      "String or binary data would be truncated in table 't', column 's'. Truncated value: '***'" ],
    [ "Violation of PRIMARY KEY constraint 'pk'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is ($long",
      "Violation of PRIMARY KEY constraint 'pk'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***" ],
  );
  for my $c (@cut) {
    my ($in, $out) = @$c;
    for my $frame (@frames) {
      my ($fname, $wrap) = @$frame;
      my $got = mask($wrap->($in));
      is $got, $wrap->($out), "cut message [$fname]: " . substr($in, 0, 50);
      is mask($got), $got, '  idempotent';
    }
  }
  is mask("Conversion failed when converting the varchar value '$long  "),
    "Conversion failed when converting the varchar value '***'  ",
    'trailing blanks after a cut message stay';
}

# No backtracking blow-up on big input: every rule, 100 KB of near misses.
for my $case (
  [ 'unterminated quote'      => "Conversion failed when converting the varchar value '" . ('a' x 100_000) ],
  [ 'doubled quotes'          => "Incorrect syntax near '" . ("''" x 50_000) ],
  [ 'repeated openers'        => "Truncated value: '" x 6_000 ],
  [ 'repeated syntax openers' => "Incorrect syntax near 'x" x 4_000 ],
  [ 'repeated overflow'       => "The conversion of the varchar value 'x" x 2_500 ],
  [ 'repeated character'      => "Unexpected character '" x 4_500 ],
  [ 'repeated duplicate key'  => "The duplicate key value is (" x 3_500 ],
  [ 'long valid value'        => "Truncated value: '" . ('b' x 100_000) . "'." ],
  [ 'long key value'          => "The duplicate key value is (" . ('c, ' x 33_000) . ")." ],
  [ 'long bind'               => ('d' x 100_000) ],
) {
  my ($name, $text) = @$case;
  my $t0 = [ Time::HiRes::gettimeofday ];
  my $got = mask($text, [ 'dddd' ]);
  my $took = Time::HiRes::tv_interval($t0);
  cmp_ok $took, '<', 2, "fast on 100 KB: $name (" . sprintf('%.3f', $took) . ' s)';
  ok defined $got, '  answers';
}

done_testing;
