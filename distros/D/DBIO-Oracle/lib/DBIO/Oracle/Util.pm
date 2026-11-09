package DBIO::Oracle::Util;
# ABSTRACT: Shared Oracle-specific helper functions for DBIO

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

# What may follow the last value of a message: the stack lines of a PL/SQL
# call, the Help line of 23ai, the DBD's tag without a statement (also the bare
# SUCCESS_WITH_INFO of an array execution) and the
# count of the array execution. A value is masked up to the first place from
# where the text is nothing but this; a value that holds a line of this kind
# in its middle is thereby masked as a whole. A text that does not end this way
# is masked to its end.
my $END = qr{
  (?:\nORA-06512:\ at\ [^\n]*)*
  (?:\nHelp:\ https://docs\.oracle\.com/error-help/\S*)?
  (?:[ \t]*\(DBD\ [A-Z_]+(?::\ OCI\w+)?\))?
  (?:\nexecuting\ \d+\ generated\ \d+\ errors)?
  \s*\z
}x;

# A value that runs up to $END (or, if there is none, to the end of the text).
my $VALUE = qr/(?:.*?(?=$END)|.*)/s;


# The statement the DBD appends to a message ("(DBD ERROR: error possibly near
# <*> indicator at char 39 in 'SELECT ...')") is the caller's own text, with
# the placeholders written :p1, :p2 and the marker <*> put in. It is split off
# only when it is that: the statement inside, without the marker and with the
# placeholders as ?, is $statement the same way, and the marker stands where
# the char number says. Returns ($message, $appendix); the appendix is empty
# unless it is the DBD's own.
sub _split_appendix {
  my ($message, $statement) = @_;

  return ($message, '') unless defined $statement && !ref $statement && length $statement;
  $message =~ /\A(.*)\s*\(DBD\ [A-Z_]+:\ error\ possibly\ near\ <\*>\ indicator\ at\ char\ (\d+)\ in\ '(.*)'\)(?:\nexecuting\ \d+\ generated\ \d+\ errors)?\z/xs
    or return ($message, '');
  my ($head, $at, $inner) = ($1, $2, $3);

  return ($message, '') unless substr($inner, $at, 3) eq '<*>';
  substr($inner, $at, 3, '');

  my $given = $statement;
  s/:p\d+/?/g for $inner, $given;
  return ($message, '') unless $inner eq $given;

  return ($head, substr($message, length $head));
}

# "A:1, B:'x'": the columns and the values of a key (the text between the
# brackets of ORA-03301). Oracle escapes nothing, so a value may hold ", " or
# ":" or a quote. The columns are known from the line of ORA-00001 before
# (@names), and the text is read as a pair list only where that is the one
# reading: it starts with the first column, and every following ", NAME:" is in
# it exactly once, in order. Anything else is masked whole.
sub _mask_key_values {
  my ($names, $content) = @_;

  return $MASK unless @$names && !grep { !length } @$names;
  return $MASK unless index($content, "$names->[0]:") == 0;

  my $pos = length($names->[0]) + 1;
  for my $n (@{$names}[1 .. $#$names]) {
    my $delimiter = ", $n:";
    my $first = index($content, $delimiter, $pos);
    return $MASK if $first < 0 || index($content, $delimiter, $first + 1) >= 0;
    $pos = $first + length $delimiter;
  }

  return join ', ', map { "$_:$MASK" } @$names;
}

# The sentences of the server that hold a value, one rule each. A rule keeps
# the words around the value -- the type, the column, the constraint -- and
# replaces the value, wherever the server puts quotes, so a rule never leaves
# a part of it. Every rule gives the same text again when it is applied to its
# own result.
sub _mask_sentences {
  my ($text) = @_;

  # ORA-01722: unable to convert string value containing 'g' to a number:
  # the first character that is not a digit: 'g', ' ', UNISTR('\FFFD')
  $text =~ s/(unable to convert string value containing ).*?( to a number: )/$1'$MASK'$2/s;

  # ORA-03302: (ORA-01722 details) invalid string value: geheim42
  $text =~ s/(\(ORA-\d+ details\) invalid string value: )$VALUE/$1$MASK/s;

  # ORA-61800: invalid boolean literal: geheim42
  $text =~ s/(\binvalid boolean literal: )$VALUE/$1$MASK/s;

  # ORA-01438: value 99999.9 greater than specified precision (4, 1) for column
  $text =~ s/(\bvalue )\S+( greater than specified precision )/$1$MASK$2/g;

  # ORA-01428: Argument -4 is out of range.
  $text =~ s/(\bArgument )\S+( is out of range\.)/$1$MASK$2/g;

  # ORA-00001 with the key of the row, 23ai:
  #   violated on table APP.USERS columns (A, B)
  #   ORA-03301: (ORA-00001 details) row with column values (A:1, B:'x') already exists
  $text =~ s{((?:\bcolumns \(([^\n]*?)\)\n)?ORA-03301: \(ORA-\d+ details\) row with column values \()($VALUE)(\) already exists)(?=$END)}
            {$1 . (defined $2 ? _mask_key_values([ split /, /, $2, -1 ], $3) : $MASK) . $4}se;

  return $text;
}


sub mask_error_details {
  my ($message, $binds, $statement) = @_;
  return $message unless defined $message && length $message;

  my $tail;
  ($message, $tail) = _split_appendix($message, $statement);

  $message = _mask_sentences($message);

  my %seen;
  my @bound = sort { length $b <=> length $a }
    grep { !$seen{$_}++ }
    map  { my $v = $_; (index($v, "'") >= 0 ? ($v, $v =~ s/'/''/gr) : ($v)) }
    grep { defined && !ref && length >= $MIN_BOUND_LENGTH }
    map  { ref($_) eq 'ARRAY' && @$_ == 2 ? $_->[1] : $_ } @{ $binds // [] };
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

DBIO::Oracle::Util - Shared Oracle-specific helper functions for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  use DBIO::Oracle::Util qw(mask_error_details);

  my $message = mask_error_details(
    "ORA-00001: unique constraint (APP.UQ_EMAIL) violated on table APP.USERS columns (EMAIL)\n"
    . "ORA-03301: (ORA-00001 details) row with column values (EMAIL:'a\@b.c') already exists"
  );
  # ... columns (EMAIL)
  # ORA-03301: (ORA-00001 details) row with column values (EMAIL:***) already exists

=head1 DESCRIPTION

Helpers of the Oracle driver that do not belong to one class.

=head1 METHODS

=head2 mask_error_details

  my $message = mask_error_details($message);
  my $message = mask_error_details($message, \@binds);
  my $message = mask_error_details($message, \@binds, $statement);

Oracle 23ai writes the offending value into its error text, also when the
value was a bind: C<ORA-03302: (ORA-01722 details) invalid string value: x>,
C<row with column values (EMAIL:'x') already exists>. The family's rule is that
a message names keys, columns and options, never values; the server's text is
the driver's to keep to it, and this is where the driver does.

Every value in the sentences of the server that quote one is replaced by
C<***>, and what the caller needs to find the cause stays: the error code, the
type, the column, the constraint, the table.

  ORA-01722: unable to convert string value containing '***' to a number:
  ORA-03302: (ORA-01722 details) invalid string value: ***
  ORA-00001: unique constraint (APP.UQ) violated on table APP.USERS columns (A, B)
  ORA-03301: (ORA-00001 details) row with column values (A:***, B:***) already exists
  ORA-01438: value *** greater than specified precision (4, 1) for column
  ORA-61800: invalid boolean literal: ***
  ORA-01428: Argument *** is out of range.

The key of ORA-03301 is written C<COLUMN:value> per column of the key. Oracle
escapes nothing in it, so a value may hold C<, >, C<:>, a quote or a line
break. The columns stay where the line of ORA-00001 before names them and the
text reads as that list in one way only; any other key text is masked whole
(C<(***)>). A value of ORA-03302, ORA-61800 or ORA-03301 may span lines: it is
masked up to the lines Oracle itself puts after it (the C<ORA-06512> stack,
the C<Help:> line, the DBD's tag), and, when the text ends otherwise, to its
end.

C<\@binds> is optional: the values bound to the statement (a bind may be
given as the pair C<[ \%attrs, $value ]>). Each one of four characters or
more that is found elsewhere in the message, in the form it was bound and in
the form C<< $dbh->quote >> gives it (a quote doubled), is replaced as well.
Shorter values, C<undef> and references are not looked for, since a letter or
a number is part of any text; the sentences above hold those. A bound value
that equals the name of a column or constraint is replaced there too.

C<$statement> is the text of the statement that was run. The DBD appends it to
a message (C<(DBD ERROR: error possibly near E<lt>*E<gt> indicator at char N in
'...')>) with its placeholders written C<:p1>; it is the caller's own text and
stays as it is, literals in it included -- but only when it is the DBD's: it
must end the message and be the statement given (the marker taken out and the
placeholders read as C<?>). Anything else that looks like it is part of the
message, and so is a value that imitates it: all of the text is masked, the
search for the bound values included. Without C<$statement> there is no
appendix.

A message the sentences do not know is returned as it is, and so is one
without a value: C<ORA-12899: value too large for column "APP"."T"."S"
(actual: 10, maximum: 5)>, C<ORA-02290: check constraint (APP.CK) violated>,
C<ORA-01400: cannot insert NULL into ("APP"."T"."NN")>, a foreign key, a date
or a JSON error of Oracle. Texts an application raises itself
(C<ORA-20001>) are the application's and are not touched.

=head1 SEE ALSO

=over 4

=item * L<DBIO::Oracle::Storage> - the storage whose refused statements are masked

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
