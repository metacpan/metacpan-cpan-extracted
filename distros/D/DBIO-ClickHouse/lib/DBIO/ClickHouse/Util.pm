package DBIO::ClickHouse::Util;
# ABSTRACT: Shared ClickHouse-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';

# A single-quoted text of the engine. It escapes a quote inside as \' where it
# writes the text itself, but not everywhere (Cannot convert string 'a'b' to
# type ...): the escape-aware reading is tried first, the greedy one is the
# fallback that runs to the last quote the sentence allows.
my $QUOTED = qr/(?s:'(?:[^'\\]|\\.)*'|'.*')/;

# Where a text of the engine that is not quoted ends: the next of its own
# sentences, or the error code that closes the message.
my $UNQUOTED_END = qr/(?=: Cannot parse \w+ from String|: [Ii]n scope |: [Ww]hile |\. \([A-Z][A-Z0-9_]*\)|\z)/;

# The last error code of the message: ". (CANNOT_PARSE_TEXT)"; the engine
# ends every message with it, then its version.
my $CODE = qr/\. \([A-Z][A-Z0-9_]*\)/;


# Every literal of a piece of SQL -- a string, a number -- is replaced.
# Identifiers, keywords and function names stay: a bare word, a `quoted` or
# "quoted" name. A string that is cut off (the engine shortens a long excerpt)
# is masked up to the end of the piece.
sub _mask_literals {
  my ($sql) = @_;

  $sql =~ s{
    (?<keep>
        `(?:[^`\\]|\\.|``)*`
      | "(?:[^"\\]|\\.|"")*"
      | [A-Za-z_]\w*
    )
    |
    (?<lit>
        '(?:[^'\\]|\\.|'')*'
      | '.*\z
      | 0[xXbB][0-9A-Fa-f]+
      | \d+(?:\.\d*)?(?:[eE][+-]?\d+)?
      | \.\d+(?:[eE][+-]?\d+)?
    )
  }{ defined $+{keep} ? $+{keep} : $MASK }gesx;

  return $sql;
}

# "a = 1, b = 'x'": the values of the row that broke a constraint. Read as
# name = value pairs where that is the only reading, else all of it is masked.
sub _mask_column_values {
  my ($values) = @_;

  my (@names, %seen);
  while (1) {
    $values =~ /\G(`(?:[^`\\]|\\.)+`|[A-Za-z_][\w.]*) = /gc or return $MASK;
    return $MASK if $seen{$1}++;
    push @names, $1;

    if ($values =~ /\G'(?:[^'\\]|\\.)*'/gc) {
      # a string, escaped the way the engine writes it
    }
    elsif ($values =~ /\G[\[\(\{]/gc) {
      return $MASK;    # a compound value holds commas and names of its own
    }
    else {
      $values =~ /\G.+?(?=, (?:`[^`]+`|[A-Za-z_][\w.]*) = |\z)/gcs or return $MASK;
    }

    last if pos($values) == length $values;
    $values =~ /\G, /gc or return $MASK;
  }

  return join ', ', map { "$_ = $MASK" } @names;
}

# "Syntax error: failed at position 1 (UPDATE): UPDATE t SET ... . Expected
# one of: ...": the text after the position is the statement as sent, values
# included. The token the parser stopped at stays only where it cannot be a
# value: a word or punctuation, no literal.
sub _mask_syntax_error {
  my ($text) = @_;

  my $sub = sub {
    my ($head, $token, $rest) = @_;
    $token = $MASK
      unless $token =~ /\A(?:[A-Za-z_]\w*(?: \w+)*|[^\w\s'"`\$]{1,3}|`[^`]*`)\z/;
    return $head . $token . '): ' . _mask_literals($rest);
  };

  my $head = qr/(?s:(Syntax error[^\n:]*: failed at position \d+ \()(.*?)\): )/;

  $text =~ s/$head(.*)(?=\. Expected )/$sub->($1, $2, $3)/se
    or $text =~ s/$head(.*)(?=$CODE)/$sub->($1, $2, $3)/se
    or $text =~ s/$head(.*)\z/$sub->($1, $2, $3)/se;

  return $text;
}

# The sentences of the engine that hold a value, one rule each. A rule keeps
# the words around the value -- the type, the column, the constraint -- and
# replaces the value, wherever the engine puts quotes, so a rule never leaves
# a part of it. Every rule gives the same text again when it is applied to its
# own result.
sub _mask_sentences {
  my ($text) = @_;

  # Cannot parse string 'x' as Int32: ... (parsed just 'x')
  $text =~ s/(Cannot parse string )$QUOTED( as )/$1'$MASK'$2/;
  $text =~ s/(\(parsed just )'.*?'(\)(?:\. |: |\z))/$1'$MASK'$2/gs;

  # Cannot convert string 'x' to type Int32 / Unknown element 'x' for enum
  $text =~ s/(Cannot convert string )$QUOTED( to type )/$1'$MASK'$2/;
  $text =~ s/(Unknown element )$QUOTED( for enum)/$1'$MASK'$2/;

  # Cannot parse boolean value here: 'x', should be 'true' or 'false' ...
  $text =~ s/(Cannot parse boolean value here: )$QUOTED(, should be )/$1'$MASK'$2/;

  # Cannot read array from text, expected comma or end of array, found 'g'
  $text =~ s/(Cannot read array from text[^\n]*?, found )'.*?'(?=: [Ii]n scope |: [Ww]hile |\. \(|\z)/$1'$MASK'/gs;

  # Cannot parse date here: x: Cannot parse Date from String
  # Cannot parse uuid x: Cannot parse UUID from String / IPv4 / IPv6
  $text =~ s/(Cannot parse date here: ).*(: Cannot parse \w+ from String)/$1$MASK$2/s;
  $text =~ s/(Cannot parse (?:uuid|IPv4|IPv6) ).*(: Cannot parse \w+ from String)/$1$MASK$2/s;

  # Cannot parse JSON object here: {x / Cannot parse expression of type Int32 here: 'x')
  $text =~ s/(Cannot parse (?!boolean )(?:[\w ]+?) here: ).*?$UNQUOTED_END/$1$MASK/gs;

  # Cannot parse input: expected '{' before: 'x': ... / while converting 'x' to Map(...)
  $text =~ s/(\bbefore: )'.*?'(?=: [Ii]n scope |: [Ww]hile |: ?\(at row|:\s+at row|\. \([A-Z]|\s*\z)/$1'$MASK'/gs;
  $text =~ s/(\bwhile converting )'.*?'(?= to )/$1'$MASK'/gs;

  # while executing 'FUNCTION equals(id : 0, 'x' : 1) -> equals(id, 'x') UInt8 : 2'
  # The plan holds the constants of the statement; nothing in it names a cause.
  $text =~ s/(\bwhile executing )'.*'(?=: While executing |$CODE|\s*\z)/$1'$MASK'/s;

  # While processing _CAST(if(id = 1, _CAST('x', 'Date'), d), 'Date'). (CODE)
  $text =~ s/(\bWhile processing )(.*)(?=$CODE)/$1 . _mask_literals($2)/se
    or $text =~ s/(\bWhile processing )(.*)\z/$1 . _mask_literals($2)/se;

  # ... In scope SELECT CAST('x', 'Int32') FROM t. (CODE) / Unknown ... in scope ...
  $text =~ s/(\b[Ii]n scope )(.*)(?=$CODE)/$1 . _mask_literals($2)/se
    or $text =~ s/(\b[Ii]n scope )(.*)\z/$1 . _mask_literals($2)/se;

  # Syntax error: failed at position N (TOKEN): <statement>. Expected one of: ...
  $text = _mask_syntax_error($text) if $text =~ /Syntax error[^\n:]*: failed at position \d+ \(/;

  # Constraint `c` for table d.t is violated at row 1. Expression: (a > 0). Column values: a = 1, b = 'x'. (CODE)
  $text =~ s/(\bColumn values: )(.*)(?=$CODE)/$1 . _mask_column_values($2)/se
    or $text =~ s/(\bColumn values: )(.*)\z/$1 . _mask_column_values($2)/se;

  # Value 60913 for year must be in the range [1970, 2106]
  $text =~ s/(\bValue )\S+( (?:for [\w ]+? )?(?:must be|cannot be|is out of|out of)\b)/$1$MASK$2/g;

  # OptimizedRegularExpression: cannot compile re2: x, error: missing ): x. Look at ...
  $text =~ s/(cannot compile re2: )(.*?)(, error: .*?: )\2(\. Look at )/$1$MASK$3$MASK$4/s
    or $text =~ s/(cannot compile re2: ).*?(\. Look at )/$1$MASK$2/s;

  return $text;
}


sub mask_error_details {
  my ($message) = @_;
  return $message unless defined $message && !ref $message && length $message;

  return _mask_sentences($message);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Util - Shared ClickHouse-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::ClickHouse::Util qw(mask_error_details);

  my $message = mask_error_details(
    q{Code: 6. DB::Exception: Cannot parse string 'secret' as Int32: syntax error at begin of string. (CANNOT_PARSE_TEXT)}
  );
  # Code: 6. DB::Exception: Cannot parse string '***' as Int32: syntax error at begin of string. (CANNOT_PARSE_TEXT)

=head1 DESCRIPTION

Helpers of the ClickHouse driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);

ClickHouse writes the offending value into its error text, also when the value
was a bind: the MySQL-wire driver puts the bind values into the statement on
the client, and the engine quotes the statement it received. The family's rule
is that a message names keys, columns and options, never values; the engine's
text is the driver's to keep to it, and this is where the driver does.

Every value in the sentences of the engine that quote one is replaced by
C<***>, and what the caller needs to find the cause stays: the error code, the
type, the column, the constraint, the table, the position of a syntax error.

  Code: 6. DB::Exception: Cannot parse string '***' as Int32: syntax error at begin of string. ...
  Code: 53. DB::Exception: Cannot convert string '***' to type Int32 ...
  Code: 38. DB::Exception: Cannot parse date here: ***: Cannot parse Date from String ...
  Code: 6. DB::Exception: Cannot parse string '***' as Int32: ...: In scope SELECT CAST(***, ***) FROM t. (CANNOT_PARSE_TEXT)
  Code: 62. DB::Exception: Syntax error: failed at position 1 (UPDATE): UPDATE t SET id = *** WHERE id = ***. Expected one of: ...
  Code: 469. DB::Exception: Constraint `pos` for table d.t (...) is violated at row 1. Expression: (a > 0). Column values: a = ***. (VIOLATED_CONSTRAINT)

The statement the engine quotes (C<In scope ...>, C<While processing ...>, the
rest of a syntax error) keeps its identifiers, keywords and function names;
every literal in it, string or number, is replaced by C<***> without quotes,
also the type names of a C<CAST>. The plan of a failed function
(C<while executing 'FUNCTION ...'>) carries the constants of the statement and
is replaced as a whole. The token a syntax error stopped at stays when it is a
word or punctuation and is replaced when it is a literal. The values of
C<Column values:> are read as C<name = value> pairs; where the text is not
readable in one way only (a compound value, a column twice) all of it is
masked.

A message the sentences do not know is returned as it is, and so is one
without a value, C<Cannot UPDATE key column `id`.>.

Two limits are known. A value the engine writes without quotes ends where the
next sentence of the engine begins (C<: Cannot parse Date from String>,
C<. (CODE)>); a value that contains such a delimiter is masked up to it and
its rest stays. And a bare word in a quoted statement is kept because it is
indistinguishable from the name of a column; a value the engine writes there
without quotes and without a form of a literal is not recognised. The values
bound to the statement are taken out of the text beforehand by the storage
(L<DBIO::ClickHouse::Storage/_mask_error_values>) wherever they stand, which
covers both for a value of at least four characters.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Storage> - the storage whose errors this masks

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
