package DBIO::Firebird::Util;
# ABSTRACT: Shared Firebird-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';


# ("A" = 1, "B" = 'x') without the outer parentheses: the column names, kept,
# with the values replaced -- or undef when the text is not one reading.
sub _mask_key {
  my ($inner, $binds) = @_;

  for my $bound (@{ $binds // [] }) {
    return undef if defined $bound && !ref $bound && $bound =~ /, "|\)/;
  }

  # The server does not escape a quote in a value, so a value holding
  # `" = ` would be read as one column more. The number of `" = ` must be the
  # number of columns found.
  my $equals = () = $inner =~ /" = /g;

  my @names;
  my $rest = $inner;
  while (length $rest) {
    $rest =~ s/\A"((?:[^"]|"")+)" = //
      or return undef;
    push @names, $1;
    # The value reaches to the next `, "NAME" = ` or to the end (lazy).
    $rest =~ s/\A.*?(?=, "(?:[^"]|"")+" = |\z)//s
      or return undef;
    $rest =~ s/\A, // or last;
  }
  return undef unless @names && @names == $equals && !length $rest;

  return join ', ', map { qq{"$_" = $MASK} } @names;
}

sub mask_error_details {
  my ($text, $binds) = @_;

  return $text unless defined $text && !ref $text;

  # -Problematic key value is ("ID" = 1, "EMAIL" = 'x')
  $text =~ s{(Problematic key value is )(.*)\z}{
    my ($head, $tail) = ($1, $2);
    my $masked;
    if ($tail =~ /\A\((.*)\)\s*\z/s) {
      my $keys = _mask_key($1, $binds);
      $masked = "($keys)" if defined $keys;
    }
    $head . (defined $masked ? $masked : $MASK)
  }se;

  # -conversion error from string "geheimdate"
  $text =~ s/(conversion error from string )".*"/$1"$MASK"/s;

  # validation error for column "T"."C", value "x"
  $text =~ s/(validation error for column [^\n]*?, value )"(.*)"/
    $2 eq '*** null ***' ? qq{$1"$2"} : qq{$1"$MASK"}/se;

  return $text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Util - Shared Firebird-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Firebird::Util qw(mask_error_details);

  my $message = mask_error_details(
    qq{-violation of PRIMARY or UNIQUE KEY constraint "INTEG_2" on table "t"\n}
    . q{-Problematic key value is ("ID" = 7, "EMAIL" = 'a@b.c')}
  );
  # ... -Problematic key value is ("ID" = ***, "EMAIL" = ***)

=head1 DESCRIPTION

Helpers of the Firebird driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $text = mask_error_details($text, \@bound_values);

Replaces the values the Firebird server writes into an error text with
C<***>. The type, the column, the constraint, the table and the error code
stay. The optional second argument is the list of values bound to the
statement; it only makes the reading of a key stricter (see below).

The sentences that hold a value:

=over 4

=item C<Problematic key value is ("A" = 1, "B" = 'x')>

(duplicate PRIMARY KEY or UNIQUE KEY, FOREIGN KEY) Every value becomes
C<***>, the quoted column names stay: C<Problematic key value is ("A" = ***,
"B" = ***)>. The server does not double a C<'> inside a value, so the text
cannot always be taken apart. It is read column by column only when that is
the one reading: the number of C<" = > in the text is the number of columns
found, and no bound value holds C<, "> or C<)>. Otherwise everything behind
C<is > becomes C<***>. A value of a statement without bound values that
itself holds C<, "NAME" = > cannot be told from a second column; the storage
always passes the bound values, so only a literal in the statement can be read
that way.

=item C<conversion error from string "...">

Becomes C<conversion error from string "***">. The value may hold C<">; the
mask reaches to the last C<"> of the text.

=item C<validation error for column "T"."C", value "...">

The value becomes C<***>. The server's own marker for NULL
(C<*** null ***>) says nothing about data and stays.

=back

A text without one of these sentences is returned as it is. Applying the
function to its own result gives the same text. The values bound to the
statement are not looked for here; that is the base storage's job
(L<DBIO::Firebird::Storage::Common/_mask_error_values>).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
