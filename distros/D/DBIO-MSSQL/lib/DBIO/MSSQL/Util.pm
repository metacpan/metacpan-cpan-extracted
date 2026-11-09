package DBIO::MSSQL::Util;
# ABSTRACT: Shared MSSQL-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';

# The shortest bound value that is looked for verbatim in an error text. A
# shorter one is a letter or a number, which is part of any text; the server's
# sentences that quote a value are known below and catch those.
my $MIN_BOUND_LENGTH = 4;

# A value in single quotes, an apostrophe inside written twice. Possessive, so
# a text without the closing quote costs one pass and no backtracking.
my $QUOTED = qr/'(?:[^']++|'')*+'/;


# The sentences of the server that hold a value, one rule each. A rule keeps
# the words around the value -- the type, the table, the column, the
# constraint -- and replaces the value. The rules work on the text of a
# server message, so the frame the DBD puts around it (DBD::Sybase: "Server
# message number=245 ... text=", DBD::ODBC: "[FreeTDS][SQL Server]" before and
# "(SQL-22018)" after) and further messages after it do not matter. Every rule
# gives the same text again when it is applied to its own result.
sub _mask_sentences {
  my ($text) = @_;

  # Where a message ends: the end of the text, the "(SQL-nnnnn)" of DBD::ODBC,
  # the next message.
  my $END = qr/(?=\s*(?:\(SQL-\d+\)|Server message number=|\[FreeTDS\]|\z))/;

  # The server writes most values as they are, an apostrophe in them too
  # (value 'a'b' to data type int; near 'it's'); only "Truncated value" doubles
  # it. So the value is what stands between the opening quote and the words
  # that close the sentence at the end of the message. A message is cut at about
  # 2000 characters, so the value is looked for within that. The failing
  # conversion of the TEXTSIZE guard of the Sybase class (its text names a
  # column, no value) is left to that class.
  $text =~ s/(\bConversion failed when converting the \w+ value )'(?!DBIO::MSSQL TEXTSIZE guard: column ).{0,2100}?'( to data type [\w ]+(?:\(\d+(?:\s*,\s*\d+)?\))?\.)$END/$1'$MASK'$2/gs;
  $text =~ s/(\bThe conversion of the \w+ value )'.{0,2100}?'( overflowed an \w+ column\.(?: Use a larger integer column\.)?)$END/$1'$MASK'$2/gs;
  $text =~ s/(\bIncorrect syntax near )'.{0,2100}?'(\.)$END/$1'$MASK'$2/gs;

  # Conversion failed when converting the varchar value 'x' to data type int.
  $text =~ s/(\bConversion failed when converting the \w+ value )$QUOTED( to data type )/$1'$MASK'$2/g;

  # The conversion of the varchar value '3000000000' overflowed an INT2 column.
  $text =~ s/(\bThe conversion of the \w+ value )$QUOTED( overflowed an )/$1'$MASK'$2/g;

  # ... The duplicate key value is (11, 22).  The text has no column names and
  # a value may hold ", " and ")", so all up to the last ")." is the value.
  $text =~ s/(\bThe duplicate key value is \().*(\)\.)/$1$MASK$2/s;

  # String or binary data would be truncated in table 't', column 's'. Truncated value: 'x'.
  $text =~ s/(\bTruncated value: )$QUOTED/$1'$MASK'/g;

  # Incorrect syntax near 'GARBAGE'.  (the form with a keyword has no quotes
  # right after "near" and is not touched)
  $text =~ s/(\bIncorrect syntax near )$QUOTED/$1'$MASK'/g;

  # JSON text is not properly formatted. Unexpected character 'g' is found at position 1.
  # The character may be a quote itself, so it is not read as a quoted value.
  $text =~ s/(\bUnexpected character )'.{1,8}?'( is found at position )/$1'$MASK'$2/gs;

  # The server cuts a message at about 2000 characters. A long value then runs
  # to the end of the message, without the closing quote and without the words
  # behind it, and the rules above do not match. The value is what is left of
  # the message up to its end.
  $text =~ s/(\bConversion failed when converting the \w+ value )'(?:[^']|'')*?$END/$1'$MASK'/g;
  $text =~ s/(\bThe conversion of the \w+ value )'(?:[^']|'')*?$END/$1'$MASK'/g;
  $text =~ s/(\bTruncated value: )'(?:[^']|'')*?$END/$1'$MASK'/g;
  $text =~ s/(\bThe duplicate key value is \()(?!\Q$MASK\E\)\.)(?:(?!\)\.).)*?$END/$1$MASK/gs;

  return $text;
}


sub mask_error_details {
  my ($message, $binds, $statement) = @_;
  return $message unless defined $message && length $message;

  $message = _mask_sentences($message);

  my %bound;
  for my $value (grep { defined && !ref && length >= $MIN_BOUND_LENGTH } @{ $binds // [] }) {
    $bound{$value} = 1;
    (my $literal = $value) =~ s/'/''/g;
    $bound{$literal} = 1;
  }
  for my $value (sort { length $b <=> length $a || $a cmp $b } keys %bound) {
    $message =~ s/\Q$value\E/$MASK/g;
  }

  return $message;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Util - Shared MSSQL-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::MSSQL::Util qw(mask_error_details);

  my $message = mask_error_details(
    q{Conversion failed when converting the varchar value 'x@y.z' to data type int.}
  );
  # Conversion failed when converting the varchar value '***' to data type int.

=head1 DESCRIPTION

Helpers of the MSSQL driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);
  my $message = mask_error_details($message, \@binds);
  my $message = mask_error_details($message, \@binds, $statement);

SQL Server writes the offending value into its error text, also when the
value was a bind: C<Conversion failed when converting the varchar value 'x' to
data type int.>, C<The duplicate key value is (x).>. The family's rule is that
a message names keys, columns and options, never values; the server's text is
the driver's to keep to it, and this is where the driver does.

Every value in the sentences of the server that quote one is replaced by
C<***>, and what the caller needs to find the cause stays: the type, the
table, the column, the constraint.

  Conversion failed when converting the varchar value '***' to data type int.
  The conversion of the varchar value '***' overflowed an INT2 column. Use a larger integer column.
  Violation of PRIMARY KEY constraint 'pk_x'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***).
  String or binary data would be truncated in table 'tempdb.dbo.t', column 's'. Truncated value: '***'.
  Incorrect syntax near '***'.
  JSON text is not properly formatted. Unexpected character '***' is found at position 1.

An apostrophe in a value is written twice in the server's text and is read
that way. The duplicate key value has no column names and may hold C<, > and
C<)>, so all of it up to the last C<).> of the text is masked (the text after
it, if there is any, is not).

The server cuts a message at about 2000 characters; a long value then runs to
the end of the message and has no closing quote. Such a value is masked to the
end of the message (the end of the text, the C<(SQL-nnnnn)> of DBD::ODBC, the
next message of DBD::Sybase), and the cut text gets the closing quote.

The rules look at the text of a server message wherever it stands: after
the C<Server message number=... text=> of DBD::Sybase, between the
C<[FreeTDS][SQL Server]> and the C<(SQL-22018)> of DBD::ODBC, in the second of
several messages.

C<\@binds> is optional: the values bound to the statement. Each one of four
characters or more (as it is, and written for a string literal, with an
apostrophe doubled) that is found elsewhere in the message is replaced as
well, longest first. Shorter values, C<undef> and references are not looked
for, since a letter or a number is part of any text; the sentences above hold
those.

C<$statement> is accepted for the family's signature and not used: SQL Server
does not append an excerpt of the statement to its messages.

The limit is deliberate. A message the rules do not know is returned as it is,
and so is one without a value (C<Violation of FOREIGN KEY constraint ... The
conflict occurred in database "d", table "dbo.p".>, C<Cannot insert the value
NULL into column 'b', ...>, C<Incorrect syntax near the keyword 'FROM'.>, the
conversion errors that name no value). Names of tables, columns and
constraints are never masked. The text of a C<RAISERROR> or C<THROW> the
application's own SQL raises is the application's and is not looked at beyond
the bound values; and C<< $dbh->errstr >> stays as the DBD has it.

=head1 SEE ALSO

=over 4

=item * L<DBIO::MSSQL::Storage> - the storage whose refused statements these texts belong to

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
