package DBIO::MySQL::Util;
# ABSTRACT: Shared MySQL/MariaDB-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900007';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';

# The shortest bound value that is looked for verbatim in an error text. A
# shorter one is a letter or a number, which is part of any text; the engine's
# sentences that quote a value are known below and catch those.
my $MIN_BOUND_LENGTH = 4;


# The text of the sentences that quote a value in one pair of quotes and name
# what follows the value after it. The value is whatever lies between the first
# quote behind $head and the LAST $tail in the text, so a value that holds quotes
# or the words of the sentence is masked whole. A text that has the head but not
# the tail loses all that follows the head: more is masked, never less.
sub _mask_quoted {
  my ($text, $head, $tail) = @_;

  $text =~ s/($head)'.*'(?=$tail)/$1'$MASK'/s
    or $text =~ s/($head)'.*\z/$1'$MASK'/s;

  return $text;
}

# The sentences of the engine that hold a value, one rule each. A rule keeps
# the words around the value -- the type, the column, the key -- and replaces
# the value, so a rule never leaves a part of it. Every rule gives the same text
# again when it is applied to its own result.
sub _mask_sentences {
  my ($text) = @_;

  # Duplicate entry 'x' for key 'tab.PRIMARY' -- a composite key is one text
  $text = _mask_quoted($text, qr/\bDuplicate entry /, qr/ for key /);

  # Incorrect integer value: 'x' for column 'i' at row 1 (also ... for function f)
  $text = _mask_quoted(
    $text, qr/\bIncorrect [A-Za-z0-9_ ]+? value: /, qr/ for (?:column|function) /,
  );

  # Truncated incorrect DOUBLE value: 'x'
  $text = _mask_quoted($text, qr/\bTruncated incorrect [A-Za-z0-9_ ]+? value: /, qr/[^']*\z/);

  # Invalid utf8mb4 character string: '\xFF'
  $text = _mask_quoted($text, qr/\bInvalid \w+ character string: /, qr/[^']*\z/);

  # Cannot convert string '\xFF' from binary to utf8mb4
  $text = _mask_quoted($text, qr/\bCannot convert string /, qr/ from \w+ to \w+/);

  # Cannot convert 'utf8mb4' character 0xC3A9 to 'ascii'
  $text =~ s/(\bCannot convert '[^'\n]*' character )0[xX][0-9A-Fa-f]+/$1$MASK/g;

  # Unknown or incorrect time zone: 'x' / Unknown character set: 'x' / Unknown collation: 'x'
  $text = _mask_quoted($text, qr/\bUnknown (?:or incorrect time zone|character set|collation): /, qr/[^']*\z/);

  # Variable 'sql_mode' can't be set to the value of 'x'
  $text = _mask_quoted($text, qr/\bVariable '[^'\n]*' can't be set to the value of /, qr/[^']*\z/);

  # Too big precision specified for 'x'. Maximum is 65   (MySQL: Too-big precision 70 specified for ''x''. ...)
  $text = _mask_quoted($text, qr/\b[Tt]oo[- ]big \w+(?: \d+)? specified for /, qr/\. Maximum is/);

  return $text;
}

# The excerpt the server gives of a refused statement: "... for the right syntax
# to use near '<excerpt>' at line N". Both DBDs write the bound values into the
# statement text before it is sent, so the excerpt holds them. What can be a
# value in it goes: every quoted literal (the statement's own with the bound
# ones; a literal the server cut at the edge of the excerpt, with no closing
# quote, to the end), and every bare number, which is what a bind of a numeric
# type is. A quoted name and the words of the statement stay.
sub _mask_excerpt {
  my ($excerpt) = @_;

  $excerpt =~ s{
      ( `(?:[^`]|``)*(?:`|\z) )
    | ( '(?:[^'\\]|\\.?|'')*(?:'|\z) | "(?:[^"\\]|\\.?|"")*(?:"|\z) )
    | (?<![\w.\$]) ( [-+]? (?: 0[xX][0-9A-Fa-f]+ | \d+(?:\.\d*)?(?:[eE][-+]?\d+)? | \.\d+ ) ) (?!\w)
  }{ defined $1 ? $1 : $MASK }gsxe;

  return $excerpt;
}

sub _mask_syntax_error {
  my ($text) = @_;

  $text =~ s/(\bfor the right syntax to use near ')(.*)(' at line \d+.*)\z/$1 . _mask_excerpt($2) . $3/se
    or $text =~ s/(\bfor the right syntax to use near ').*\z/$1$MASK'/s;

  return $text;
}

# The forms a bound value has in a text: as it is, as DBD::mysql and
# DBD::MariaDB write it into a literal (a backslash before a quote, a
# backslash and a letter for the control characters), with a doubled quote, and
# as the UTF-8 bytes of the characters.
sub _bound_forms {
  my ($bound) = @_;

  my %form = ($bound => 1);
  my %escape = ("\\" => '\\\\', "'" => "\\'", '"' => '\\"', "\n" => '\\n',
                "\r" => '\\r', "\0" => '\\0', "\x1a" => '\\Z');

  (my $escaped = $bound) =~ s/([\\'"\n\r\0\x1a])/$escape{$1}/g;
  $form{$escaped} = 1;

  (my $doubled = $bound) =~ s/(['"])/$1$1/g;
  $form{$doubled} = 1;

  for my $text (keys %form) {
    my $bytes = $text;
    utf8::encode($bytes);
    $form{$bytes} = 1;
  }

  return keys %form;
}

# --- Masking by the error code of the server --------------------------------
#
# The server writes an error in the language of the session (lc_messages), and
# only the texts in English are known above. What does not change with the
# language is the code of the error and the quote the server puts around a
# value: a single quote. A code that quotes a value has the structure of its text
# described here, and the value is cut out by that structure, not by the words
# around it.
#
#   ident   the value, then the name of a key, a column or a function that is
#           quoted too: Duplicate entry 'v' for key 'k'
#   last    the value is the last quoted thing, words may follow it
#   var     a quoted name, then the value: Variable 'n' ... 'v'
#   mixed   either of the two, told by the number of quotes (error 1292)
#   excerpt a part of the statement, which holds the values: near '...', or the
#           expression of "... value is out of range in '(a - 5)'"
my %CODE_KIND = (
  1062 => 'ident',     # ER_DUP_ENTRY
  1366 => 'ident',     # ER_TRUNCATED_WRONG_VALUE_FOR_FIELD
  1411 => 'ident',     # ER_WRONG_VALUE_FOR_TYPE
  1300 => 'last',      # ER_INVALID_CHARACTER_STRING
  3854 => 'last',      # ER_CANNOT_CONVERT_STRING
  1298 => 'last',      # ER_UNKNOWN_TIME_ZONE
  1115 => 'last',      # ER_UNKNOWN_CHARACTER_SET
  1273 => 'last',      # ER_UNKNOWN_COLLATION
  1525 => 'last',      # ER_WRONG_VALUE
  1231 => 'var',       # ER_WRONG_VALUE_FOR_VAR
  1292 => 'mixed',     # ER_TRUNCATED_WRONG_VALUE
  1064 => 'excerpt',   # ER_PARSE_ERROR
  1690 => 'excerpt',   # ER_DATA_OUT_OF_RANGE: "BIGINT value is out of range in '(`a` - 5)'"
);

# What takes the place of a text that holds a value and cannot be masked for
# sure.
sub _withheld_text {
  my ($code) = @_;
  return "Server error $code: the text quotes a value and is withheld";
}

# A quote that opens: not the one inside a word (the elision of "d'entier").
my $OPENING_QUOTE = qr/(?<![\w\x80-\xff])'/;

# The span from the first opening quote to the last quote of the text, as the
# positions of the two quotes; nothing when there is no pair.
sub _quoted_span {
  my ($text) = @_;

  $text =~ /$OPENING_QUOTE/g or return;
  my $start = $-[0];
  my $end   = rindex($text, "'");

  return $end > $start ? ($start, $end) : ();
}

# The span replaced; a text without one is withheld (undef).
sub _mask_span {
  my ($text, $start, $end) = @_;
  return undef unless defined $start;

  substr($text, $start, $end - $start + 1) = "'$MASK'";
  return $text;
}

sub _mask_last {
  my ($text) = @_;
  return _mask_span($text, _quoted_span($text));
}

# The value, then a name that is quoted again. The name is the token that ends
# last, of two forms: a chain of quoted identifiers (`db`.`t`.`c`) or a quote
# around one word. The value ends at the last quote before it. A lone quote in
# front of a chain (MariaDB in German: "... Feld '`db`.`t`.`c` in Zeile 1") belongs to
# neither. Without a name of its own the whole span is the value: a function is
# not quoted (... for function str_to_date).
sub _mask_ident_last {
  my ($text) = @_;

  my ($start, $end) = _quoted_span($text) or return undef;

  my ($token_start, $token_end);

  if ($text =~ /\A.*(?<![\w\x80-\xff])('[^\s'`]+')(?![\w\x80-\xff])/s) {
    ($token_start, $token_end) = ($-[1], $+[1]);
  }

  my $last_tick = rindex($text, '`');
  if ($last_tick >= 0
      and substr($text, 0, $last_tick + 1) =~ /(`[^`]+`(?:\.`[^`]+`)*)\z/
      and (!defined $token_end or $last_tick + 1 > $token_end)) {
    ($token_start, $token_end) = ($-[1], $last_tick + 1);
    $token_start-- if $token_start > 0 and substr($text, $token_start - 1, 1) eq "'";
  }

  return _mask_span($text, $start, $end)
    if !defined $token_start or $token_start <= $start;

  my $value_end = rindex(substr($text, 0, $token_start), "'");
  return undef unless $value_end > $start;

  return _mask_span($text, $start, $value_end);
}

# error 1231: the first pair of quotes is the name of the variable
sub _mask_variable {
  my ($text) = @_;

  $text =~ /\A([^']*'[^'\n]*')(.*)\z/s or return undef;
  my ($name, $rest) = ($1, $2);

  my $masked = _mask_last($rest);
  return defined $masked ? $name . $masked : undef;
}

# error 1292 has two sentences that differ in what follows the value:
# "Truncated incorrect DOUBLE value: 'x'" ends with it, "Incorrect date value:
# 'x' for column 'd' at row 1" names a column. A text that ends with a quote and
# has four or more of them is not told apart: all of it is the value.
sub _mask_mixed {
  my ($text) = @_;

  my $quotes = $text =~ tr/'//;
  return undef if $quotes < 2;
  return _mask_last($text) if $quotes == 2 or ($quotes >= 4 and $text =~ /'\s*\z/);
  return _mask_ident_last($text);
}

sub _mask_excerpt_span {
  my ($text) = @_;

  my ($start, $end) = _quoted_span($text) or return undef;
  substr($text, $start + 1, $end - $start - 1) = _mask_excerpt(substr($text, $start + 1, $end - $start - 1));

  return $text;
}

my %MASK_BY_KIND = (
  ident   => \&_mask_ident_last,
  last    => \&_mask_last,
  var     => \&_mask_variable,
  mixed   => \&_mask_mixed,
  excerpt => \&_mask_excerpt_span,
);

# The text masked by the structure of its error code, whatever the language of
# the server. What DBI adds around the text of the server stays out of the way:
# its statement with the values (ParamValues) goes, the DBD prefix, the location
# in Perl and the statement of the storage (placeholder form, number of binds)
# stay. A text that holds a value and does not have the structure of its code
# loses everything but the code.
sub _mask_by_code {
  my ($text, $code) = @_;

  my $kind = defined $code ? $CODE_KIND{$code} : undef;
  return $text unless $kind;

  my $statement = '';
  if ($text =~ s/(\s*\[for Statement ".*)\z//s) {
    my $cut = $1;
    $statement = $cut if $cut =~ /" with \d+ bind values?\](?:\s+at \S+ line \d+\.?\s*)?\z/;
  }

  my ($prefix, $location) = ('', '');
  $prefix   = $1 if $text =~ s/\A((?:DBI Exception: )?(?:DBD::\w+::\w+ \w+ failed: )?)//;
  $location = $1 if $text =~ s/(\s+at \S+ line \d+\.?\s*)\z//;

  my $masked = $MASK_BY_KIND{$kind}->($text);
  $masked = _withheld_text($code) unless defined $masked;

  return $prefix . $masked . $location . $statement;
}


sub mask_error_details {
  my ($message, $binds, $statement, $code) = @_;
  return $message unless defined $message && length $message;

  $message = _mask_by_code($message, $code);
  $message = _mask_syntax_error($message);
  $message = _mask_sentences($message);

  my @bound = sort { length $b <=> length $a }
    map { _bound_forms($_) }
    grep { defined && !ref && length >= $MIN_BOUND_LENGTH } @{ $binds // [] };
  my %seen;
  for my $bound (grep { !$seen{$_}++ } @bound) {
    $message =~ s/\Q$bound\E/$MASK/g;
  }

  return $message;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Util - Shared MySQL/MariaDB-specific helper functions for DBIO

=head1 VERSION

version 0.900007

=head1 SYNOPSIS

  use DBIO::MySQL::Util qw(mask_error_details);

  my $message = mask_error_details(
    q{Duplicate entry 'a@b.c' for key 'users.email'}
  );
  # Duplicate entry '***' for key 'users.email'

=head1 DESCRIPTION

Helpers of the MySQL and MariaDB driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);
  my $message = mask_error_details($message, \@binds);
  my $message = mask_error_details($message, \@binds, $statement);
  my $message = mask_error_details($message, \@binds, $statement, $code);

MySQL and MariaDB write the offending value into their error text, also when
the value was a bind: C<Incorrect integer value: 'x' for column 'i'>,
C<Duplicate entry 'x' for key 'users.email'>. Both DBDs put the bound values
into the statement text themselves, so a syntax error quotes them in its
C<near '...'> excerpt. The family's rule is that a message names keys, columns
and options, never values; the engine's text is the driver's to keep to it,
and this is where the driver does.

Every value in the sentences of the engine that quote one is replaced by
C<***>, and what the caller needs to find the cause stays: the type, the
column, the constraint, the key, the position.

  Incorrect integer value: '***' for column 'i' at row 1
  Incorrect string value: '***' for column `db`.`t`.`c` at row 1
  Truncated incorrect DOUBLE value: '***'
  Duplicate entry '***' for key 't.PRIMARY'
  Invalid utf8mb4 character string: '***'
  Unknown or incorrect time zone: '***'
  Variable 'sql_mode' can't be set to the value of '***'

The value is all that lies between the quotes of the sentence, up to the last
quote that ends it, so a value with quotes, commas, newlines or the words of
the sentence in it is masked whole. The key of C<Duplicate entry> is one text:
the values of a composite key cannot be told apart in it, and all of it is
masked. A text that has the start of such a sentence but not its end loses
all that follows the start.

A syntax error names the part of the statement it stopped at:

  You have an error in your SQL syntax; ... use near 'fw_t where s = '***'' at line 1

The excerpt is the statement with the values written into it, and nothing in
it tells a bound value from a literal of the statement. So each quoted literal
(single or double quotes, backslash escapes and doubled quotes included) is
replaced by C<***>, also the literal that the server cut off at the edge of the
excerpt, and each bare number is, which is how a value of a numeric type is
written. The rest of the excerpt stays: the words of the statement, quoted
names, C<NULL>.

  ... use near 'fw_t where s = *** and i = ***' at line 1

C<\@binds> is optional: the values bound to the statement. Each one of four
characters or more that is found elsewhere in the message (a name taken from a
bind) is replaced as well, as it is, as DBD writes it into a literal (C<\'>,
C<\n>, ...) and as UTF-8 bytes. Shorter values, C<undef> and references are not
looked for, since a letter or a number is part of any text; the sentences above
hold those.

C<$statement> is the statement that was run. The excerpt of a syntax error is
masked without it, so it is accepted for the signature of the hook that calls
this function and is not consulted.

C<$code> is the error code of the server (C<< $dbh->err >>: 1062, 1366, ...) and
is optional. The server writes its messages in the language of the session
(C<lc_messages>), and the sentences above are the English ones. With a code of
an error that quotes a value, the text is masked by the code and not by the
wording, in every language of the session: the value is what the server puts
between single quotes, and the structure of the text is told by the code.

  Duplicata du champ 'ab' pour la clef 'users.name'      (1062)
  Duplicata du champ '***' pour la clef 'users.name'

  Unbekannte oder falsche Zeitzone: 'Nowhere/Xy'         (1298)
  Unbekannte oder falsche Zeitzone: '***'

The codes are 1062, 1366 and 1411 (the value, then a quoted key, column or
function), 1292 (either form), 1231 (the name of a variable, then the value),
1300, 3854, 1298, 1115, 1273 and 1525 (the value is the last quoted text) and
1064 and 1690 (the excerpt of the statement: the syntax error's near '...', the
expression of "value is out of range in '(`a` - 5)'"). The value is all that lies between the
first quote that opens and the last quote that belongs to it, so quotes, commas
and line breaks in the value are masked with it; the key or the column behind
it stays; so does a quote in front of a column that the server leaves without its
partner (MariaDB in German). A text of such a code that does not have the structure of its code
(no pair of quotes, for one) is not masked but replaced: only the code stays.

  Server error 1062: the text quotes a value and is withheld

The masking by the code runs first; the sentences above and the bound values
follow, and the result masked again is the same. Without a code, or with a code
of an error that quotes no value, nothing changes.

A message the sentences do not know is returned as it is, and so is one
without a value: C<Data truncated for column 'e' at row 1>, C<Data too long>,
C<Out of range value>, C<Column 'i' cannot be null>, a check or foreign key
violation. The result of the function gives the same result when it is
masked again.

=head1 SEE ALSO

=over 4

=item * L<DBIO::MySQL::Storage> - the storage whose refused statements these texts come from

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
