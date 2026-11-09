package DBIO::MySQL::Util;
# ABSTRACT: Shared MySQL/MariaDB-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

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


sub mask_error_details {
  my ($message, $binds, $statement) = @_;
  return $message unless defined $message && length $message;

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

version 0.900004

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
