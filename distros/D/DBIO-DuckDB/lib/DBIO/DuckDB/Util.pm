package DBIO::DuckDB::Util;
# ABSTRACT: Shared DuckDB-specific helper functions for DBIO

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


# "key "a: 1, b: x"": the columns and the values of a key. Read as
# column: value pairs where that is the only reading, else all of it is masked.
# The text does not escape anything, so a value holding ", " or ": " could be
# read as one more column (and show part of the value as its name): such a
# text is masked whole, also when a bound value has either in it.
sub _mask_key {
  my ($key, $binds) = @_;

  for my $bound (@{ $binds // [] }) {
    return $MASK if defined $bound && !ref $bound && $bound =~ /, |: /;
  }

  my (@names, %seen);
  for my $pair (split /, /, $key, -1) {
    my ($name, $value) = $pair =~ /\A([^:,"'\s][^:,"']*): (.*)\z/s
      or return $MASK;
    return $MASK if $value =~ /: / or $seen{$name}++;
    push @names, $name;
  }
  return $MASK unless @names;

  return join ', ', map { "$_: $MASK" } @names;
}

# The sentences of the engine that hold a value, one rule each. A rule keeps
# the words around the value -- the type, the column, the constraint -- and
# replaces the value, wherever the engine puts quotes, so a rule never leaves
# a part of it. Every rule gives the same text again when it is applied to its
# own result.
sub _mask_sentences {
  my ($text, $binds) = @_;

  # Could not convert string 'x' to INT32 / string "x" to DECIMAL(3,1)
  $text =~ s/(Could not convert string )(['"]).*\2( to \S+)/$1$2$MASK$2$3/s;

  # Type DOUBLE with value 3000000000.0 can't be cast ...
  $text =~ s/(\bwith value ).*( can't be cast)/$1$MASK$2/s;

  # Duplicate key "id: 1" violates ... / because key "id: 1" does not exist ...
  $text =~ s{(\bkey )"(.*)"(?= (?:violates|does not exist|is still referenced))}
            {$1 . '"' . _mask_key($2, $binds) . '"'}se;

  # Malformed JSON at byte 1 of input: unexpected character.  Input: "{x"
  $text =~ s/(Malformed JSON at byte \d+ of input: .*?\bInput: ).*\z/$1"$MASK"/s;

  # date field value out of range: "x" / invalid timestamp field format: "x", expected ...
  $text =~ s/(\bfield [^:\n]*: )"[^\n]*"((?:, expected format is [^"\n]*)?)$/$1"$MASK"$2/mg;

  # Could not cast value 99999.900000 to DECIMAL(4,1)
  $text =~ s/(Could not cast value )[^\n]*( to \S+)$/$1$MASK$2/mg;

  # ... in string -> blob conversion of string "\xZZ": \xZZ
  $text =~ s/(blob conversion of string )"[^\n]*"[^\n]*$/$1"$MASK": $MASK/mg;

  # Could not parse string "x" according to format specifier "%Y"\nx\n^
  $text =~ s/(Could not parse string )"[^\n]*"( according to format specifier )/$1"$MASK"$2/g;
  $text =~ s/(according to format specifier [^\n]*\n)[^\n]*(\n\^)/$1$MASK$2/g;

  # Overflow in multiplication of INT32 (5000 * 1000000)!
  $text =~ s/(\bOverflow in \w+ of \w+ )\([^\n]*\)!/$1($MASK)!/g;

  # Unknown TimeZone 'x'! / extract specifier "x" not recognized / JSON path error near 'x'
  $text =~ s/(Unknown TimeZone )'[^\n]*'!/$1'$MASK'!/g;
  $text =~ s/(extract specifier )"[^\n]*"( not recognized)/$1"$MASK"$2/g;
  $text =~ s/(JSON path error near )'[^\n]*'/$1'$MASK'/g;
  $text =~ s/(Cannot create a string of size: )'[^'\n]*'/$1'$MASK'/g;

  # Invalid character encountered in string -> bit conversion: 'g'
  $text =~ s/(\bbit conversion: )'[^\n]*'/$1'$MASK'/g;

  # Invalid Input Error: <what>: <the fragment of the input> (regex, hex, ...)
  $text =~ s/(Invalid Input Error: [^:\n]*: )[^\n]*$/$1$MASK/mg;

  return $text;
}


# The excerpt DuckDB appends to the message of a statement it refuses, if the
# text ends with one: "\n\nLINE n: <a piece of line n of the statement>\n<spaces>^".
# The piece is cut with ... at the start and the end where the line is long.
# Returns ($message, $excerpt); the excerpt is empty unless it is DuckDB's.
sub _split_excerpt {
  my ($message, $statement) = @_;

  return ($message, '') unless defined $statement && !ref $statement && length $statement;
  $message =~ /\A(.*)(\n\nLINE (\d+): ([^\n]*)\n[ \t]*\^)\z/s
    or return ($message, '');
  my ($head, $excerpt, $line, $piece) = ($1, $2, $3, $4);

  my @lines = split /\r?\n/, $statement, -1;
  return ($message, '') unless $line >= 1 && $line <= @lines;

  $piece =~ s/\r\z//;
  $piece =~ s/\A\.\.\.//;
  $piece =~ s/\.\.\.\z//;
  return ($message, '') unless length $piece && index($lines[$line - 1], $piece) >= 0;

  return ($head, $excerpt);
}

sub mask_error_details {
  my ($message, $binds, $statement) = @_;
  return $message unless defined $message && length $message;

  my $tail;
  ($message, $tail) = _split_excerpt($message, $statement);

  $message = _mask_sentences($message, $binds);

  my @bound = sort { length $b <=> length $a }
    grep { defined && !ref && length >= $MIN_BOUND_LENGTH } @{ $binds // [] };
  for my $bound (@bound) {
    $message =~ s/\Q$bound\E/$MASK/g;
  }

  return $message . $tail;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Util - Shared DuckDB-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::DuckDB::Util qw(mask_error_details);

  my $message = mask_error_details(
    q{Constraint Error: Duplicate key "email: a@b.c" violates unique constraint.}
  );
  # Constraint Error: Duplicate key "email: ***" violates unique constraint.

=head1 DESCRIPTION

Helpers of the DuckDB driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);
  my $message = mask_error_details($message, \@binds);
  my $message = mask_error_details($message, \@binds, $statement);

DuckDB writes the offending value into its error text, also when the value was
a bind: C<Could not convert string 'x' to INT32>, C<Duplicate key "email: x"
violates unique constraint.>. The family's rule is that a message names keys,
columns and options, never values; the engine's text is the driver's to keep
to it, and this is where the driver does.

Every value in the sentences of the engine that quote one is replaced by
C<***>, and what the caller needs to find the cause stays: the type, the
column, the constraint, the table.

  Conversion Error: Could not convert string '***' to INT32
  Conversion Error: Type DOUBLE with value *** can't be cast because the value is out of range for the destination type INT16
  Constraint Error: Duplicate key "id: ***" violates primary key constraint.
  Constraint Error: Violates foreign key constraint because key "a: ***, b: ***" does not exist in the referenced table
  Conversion Error: Malformed JSON at byte 1 of input: unexpected character.  Input: "***"
  Conversion Error: date field value out of range: "***"
  Conversion Error: Could not cast value *** to DECIMAL(4,1)
  Invalid Input Error: missing ): ***

A key is written C<column: value> for each column of the key. The columns stay
where that text can be read in one way only; a value that holds C<, > or C<: >
could be taken for one more column, so a key text with such a part, a column
twice, or a bound value (C<\@binds>) with C<, > or C<: > in it is masked whole
(C<"***">).

C<\@binds> is optional: the values bound to the statement. Each one of
four characters or more that is found elsewhere in the message (the name of a
sequence taken from a bind, a file path) is replaced as well. Shorter values,
C<undef> and references are not looked for, since a letter or a number is part
of any text; the sentences above hold those.

C<$statement> is the text of the statement that was run. The excerpt DuckDB
appends to it (C<\n\nLINE 1: ...> and the caret line) is the caller's own
statement text and stays as it is -- but only when it is DuckDB's: it must end
the message, hold one line of C<$statement> (cut with C<...> at either end,
the line number being the one of the excerpt) and be followed by the caret
line. Anything else that looks like it is part of the message, and so is a
value that imitates it: all of the text is masked, the search for the bound
values included. Without C<$statement> there is no excerpt. Core's
C<[for Statement "..." with N bind values]> is appended after the masking and
never reaches the masker; a text that holds it is plain text here. The storage
calls this function from its C<_mask_error_values> with the values core gives
it, and core's own masking of the bound values follows; the search for the
bound values above overlaps with that one and stays for the callers of this
function.

A message the sentences do not know is returned as it is, and so is one
without a value, C<CHECK constraint failed on table p with expression
CHECK((c E<gt> 0))> or C<NOT NULL constraint failed: p.nn>.

=head1 SEE ALSO

=over 4

=item * L<DBIO::DuckDB::Storage/_mask_error_values> - masks the text of every refused statement, through core's hook

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
