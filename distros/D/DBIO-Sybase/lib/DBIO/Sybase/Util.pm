package DBIO::Sybase::Util;
# ABSTRACT: Shared Sybase ASE-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';

# The shortest bound value that is looked for verbatim in an error text. A
# shorter one is a letter or a number, which is part of any text; the sentences
# known below catch those.
my $MIN_BOUND_LENGTH = 4;


# The sentences of the server and of its client library that hold a value, one
# rule each. A rule keeps the words around the value -- the type, the column,
# the constraint -- and replaces the value. Every rule gives the same text
# again when it is applied to its own result.
sub _mask_sentences {
  my ($text, $binds) = @_;

  # ... during implicit conversion of CHAR value 'x' to a DATE field .
  # The value is quoted but not escaped: it ends at the last "' to a".
  my $conversion = qr/\bconversion of [A-Z][A-Z0-9_ ()]*? value /;
  $text =~ s/($conversion)'.*' to a ([A-Z][A-Z0-9_ ()]* field)/$1'$MASK' to a $2/s
    or $text =~ s/($conversion)'(?!\Q$MASK\E'(?: to a |\z)).*\z/$1'$MASK'/s;

  # Syntax error converting the varchar value 'x' to a column of data type int
  $text =~ s/(\bconverting the \w+ value )'.*'( to a column of data type )/$1'$MASK'$2/s;

  # ... to_numeric() failed for '99999.9'  (the end of the text)
  $text =~ s/(\bfailed for )'.*'/$1'$MASK'/s;

  # cs_convert failed (to_money(x))
  $text =~ s/(\bcs_convert failed \(to_\w+\().*(\)\))/$1$MASK$2/s;

  # Create unique index aborted on duplicate key.  Primary key is '"x"'
  # The key is quoted as '"x"' and may hold line breaks: it ends at the first
  # "' that closes a line.
  $text =~ s/(\bPrimary key is )'".*?"'(?=\n|\z)/$1'$MASK'/sg;
  # Any other form of the key goes to the end of its line; a bound value with a
  # line break carries the key over its line: all that follows goes.
  my $multiline = grep { defined && !ref && /[\r\n]/ } @{ $binds // [] };
  if ($multiline) {
    $text =~ s/(\bPrimary key is )(?=').*\z/$1'$MASK'/s;
  }
  else {
    $text =~ s/(\bPrimary key is )(?=').*$/$1'$MASK'/mg;
  }

  return $text;
}


sub mask_error_details {
  my ($message, $binds) = @_;
  return $message unless defined $message && length $message;

  $message = _mask_sentences($message, $binds);

  my @bound = sort { length $b <=> length $a }
    grep { defined && !ref && length >= $MIN_BOUND_LENGTH } @{ $binds // [] };
  for my $bound (@bound) {
    $message =~ s/\Q$bound\E/$MASK/g;
  }

  return $message;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Util - Shared Sybase ASE-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Sybase::Util qw(mask_error_details);

  my $message = mask_error_details(
    q{Syntax error during implicit conversion of CHAR value 'abc' to a DATE field.}
  );
  # Syntax error during implicit conversion of CHAR value '***' to a DATE field.

=head1 DESCRIPTION

Helpers of the Sybase ASE driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);
  my $message = mask_error_details($message, \@binds);

ASE writes the offending value into the text of some of its errors, also when
the value was a bind, and so does its client library. The family's rule is that
a message names keys, columns and options, never values; the text of the engine
is the driver's to keep to it, and this is where the driver does.

Every value in the sentences that quote one is replaced by C<***>; the message
number, the type, the column, the constraint and the table stay.

  Syntax error during implicit conversion of CHAR value '***' to a DATE field.
  cs_convert: ... common library error: ... to_numeric() failed for '***'
  cs_convert failed (to_money(***))
  Create unique index aborted on duplicate key.  Primary key is '***'
  Syntax error converting the varchar value '***' to a column of data type int

A value is not escaped in these texts and may hold quotes, commas, colons or
line breaks; each rule ends the value at the last place its sentence can end,
and where that is not certain it masks more, not less.

C<\@binds> is optional: the values bound to the statement. Each one of four
characters or more that is found elsewhere in the message is replaced as well.
Shorter values, C<undef> and references are not looked for, since a letter or a
number is part of any text; the sentences above hold those. A bound value with
a line break makes the key of the duplicate-key message run to the end of the
text.

A message the sentences do not know is returned as it is, and so is one without
a value: C<Attempt to insert NULL value into column 'id', table 't'; column
does not allow nulls.>, C<Attempt to insert duplicate key row in object 't' with
unique index 'x'>, C<Implicit conversion from datatype 'VARCHAR' to 'INT' is not
allowed.>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
