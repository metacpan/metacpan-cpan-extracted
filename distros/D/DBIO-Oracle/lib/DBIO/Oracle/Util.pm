package DBIO::Oracle::Util;
# ABSTRACT: Shared Oracle-specific helper functions for DBIO

use strict;
use warnings;

our $VERSION = '0.900007';

use Exporter 'import';

our @EXPORT_OK = qw(mask_error_details);

# What stands in for a value in an error text.
my $MASK = '***';

# The shortest bound value that is looked for verbatim in an error text. A
# shorter one is a letter or a number, which is part of any text; the server's
# sentences that quote a value are known below and catch those.
my $MIN_BOUND_LENGTH = 4;

# What may follow the last value of a message: the stack lines of a PL/SQL
# call (ORA-06512; what stands after the code is the session language's), the
# line with the link to the error help of 23ai (its label is the language of
# the client, not of the session -- "Help:", "Hilfe:", "Aide :" with a blank
# before the colon in French, and a session set to another language does not
# change it -- the link is what is recognised), the
# DBD's tag without a statement (also the bare SUCCESS_WITH_INFO of an array
# execution) and the count of the array execution. A value is masked up to the
# first place from where the text is nothing but this; a value that holds a
# line of this kind in its middle is thereby masked as a whole. A text that
# does not end this way is masked to its end.
my $END = qr{
  (?:\nORA-06512:[^\n]*)*
  (?:\n[^\n:]*:\s*https://docs\.oracle\.com/error-help/\S*)?
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

  # ORA-01722, the first character of the value in quotes, the line before
  # the ORA-03302 line. English: "unable to convert string value containing
  # 'g' to a number: ", German: "Zeichenfolgenwert mit 'g' kann nicht in eine
  # Zahl konvertiert werden: ". The character may be a quote, a blank or a
  # line break, so the text between the first and the last quote of the line
  # goes; a line with no quotes is of a form not known and loses its text.
  $text =~ s{(\bORA-01722:\ )((?:(?!\nORA-).)*?)(\s*\nORA-03302:\ )}
            {$1 . _mask_quoted($2) . $3}se;
  # the same line in English, when no ORA-03302 line follows
  $text =~ s/(unable to convert string value containing ).*?( to a number: )/$1'$MASK'$2/s;

  # ORA-03302 and ORA-61800: "<label>: <value>". English: "(ORA-01722
  # details) invalid string value: x", "invalid boolean literal: x"; German:
  # "(ORA-01722-Details) Ungültiger Zeichenfolgenwert: x", "Ungültiges
  # boolesches Literal: x". The label holds no colon; the value is what stands
  # after the first one and may hold anything. A label with no colon in it is
  # of a form not known: the whole text after the code goes.
  $text =~ s{(\bORA-(?:03302|61800):\ )(?:((?:(?!\(DBD\ )[^:\n])*?:\ )$VALUE|$VALUE)}
            {$1 . (defined $2 ? $2 : '') . $MASK}se;

  # ORA-01438, the value in front of the precision. English: "value 99999.9
  # greater than specified precision (4, 1) for column", German: "Wert 99999,9
  # ist größer als die angegebene Dezimalstellenanzahl (4, 1) für Spalte".
  $text =~ s{(\bORA-01438:\ )([^\n]*)}{$1 . _mask_numbers($2, 1)}ge;

  # ORA-01428, the argument. English: "Argument -4 is out of range.", German:
  # "Argument -4 befindet sich außerhalb des zulässigen Wertebereichs."
  $text =~ s{(\bORA-01428:\ )([^\n]*)}{$1 . _mask_numbers($2)}ge;

  # ORA-00001 with the key of the row, 23ai:
  #   ... violated on table APP.USERS columns (A, B)
  #   ORA-03301: (ORA-00001 details) row with column values (A:1, B:'x') already exists
  # German:
  #   ... für Tabelle APP.USERS mit Spalten (A, B) verletzt
  #   ORA-03301: (ORA-00001-Details) Zeile mit Spaltenwerten (A:1, B:'x') ist bereits vorhanden
  # The key is the parenthesis after the label, up to the last bracket that is
  # followed by words (not the one of the DBD's tag) before what Oracle puts
  # after the message; the words before and after it are the session
  # language's. The columns are those in the last parenthesis of the
  # ORA-00001 line before, and the key is only read as a pair list when they
  # fit it (_mask_key_values). A text of another build -- no such label, a
  # tail the end does not follow -- loses all of it after the code.
  $text =~ s{
      (?<pre>(?:ORA-00001:[^\n]*\((?<names>[^\n]*?)\)[^()\n]*\n)?ORA-03301:\ )
      (?:
        (?<head>\([^()\n]*\bORA-\d+[^()\n]*\)\ [^()\n]*?\()(?<key>$VALUE)(?<tail>\)\ [^()\n]*[^()\s])(?=$END)
      | $VALUE
      )
    }{_mask_key_text(\%+)}xse;

  return $text;
}

# ORA-03301 as the match of the rule above gives it: with a label and a key
# the key is masked, without them the text after the code is.
sub _mask_key_text {
  my ($m) = @_;
  my %m = %$m;

  return $m{pre} . $MASK unless defined $m{head};
  return $m{pre} . $m{head}
    . (defined $m{names} ? _mask_key_values([ split /, /, $m{names}, -1 ], $m{key}) : $MASK)
    . $m{tail};
}

# "unable to convert string value containing 'g' to a number:" -- what is
# between the first and the last quote becomes the mask; no quote, no reading.
sub _mask_quoted {
  my ($line) = @_;

  return "$1$MASK$2" if $line =~ /\A([^'\n]*')(?:.*)('[^'\n]*)\z/s;
  return $MASK;
}

# A number as the server prints it in a message -- sign, digits, "." or ","
# among them, an exponent, all that without a blank -- is taken as the word
# that holds a digit.
my $NUMBER = qr/\S*\d\S*/;

# The numbers of the line of ORA-01438 and ORA-01428 are the value. With a
# true $until_precision they are those before the precision "(4, 1)", which
# the line must have. A line with no number (a value of letters, "Inf"), or
# with no precision when one is asked for, is not of a form known and loses
# its text. A line that holds the mask is the line already masked.
sub _mask_numbers {
  my ($line, $until_precision) = @_;

  my ($head, $rest) = ($line, '');
  if ($until_precision) {
    $line =~ /\A(.*?)(\s\(\d+,\s*-?\d+\).*)\z/s or return $MASK;
    ($head, $rest) = ($1, $2);
  }

  return $line if index($head, $MASK) >= 0;
  return $MASK unless $head =~ s/$NUMBER/$MASK/g;
  return $head . $rest;
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

version 0.900007

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

B<The language of the session.> Oracle writes its messages in the language of the session (C<NLS_LANGUAGE>,
taken from C<NLS_LANG> or the environment), and the rules above are not tied
to the English sentence. A message that quotes a value is recognised by its
code (C<ORA-03302>, C<ORA-03301>, C<ORA-01722>, C<ORA-01438>, C<ORA-61800>,
C<ORA-01428>) and read by its structure: the label of C<ORA-03302> and
C<ORA-61800> ends at the first colon and the value follows; the key of
C<ORA-03301> stands in the first brackets after the label, up to the last
bracket that is followed by words (the columns are taken from the last
brackets of the C<ORA-00001> line before it); the value of C<ORA-01722> stands
between the first and the last quote of its line; the value of C<ORA-01438>
and C<ORA-01428> is the number in the line (before the precision, for
C<ORA-01438>). The line with the link to the error help (C<Help:>, C<Hilfe:>,
C<Aide :>) and the C<ORA-06512> stack (C<at line 1>, C<in Zeile 1>, C<à la ligne 1>)
are recognised by the link and the code; the label of the link line is the
language of the client (C<NLS_LANG>), not of the session, so an English session
under a French client has C<Aide :> after English sentences. The brackets of the
details (C<ORA-01722 details>, C<ORA-01722-Details>, C<Détails ORA-01722>) are
read as a parenthesis that holds an C<ORA-> code. German, measured on Oracle 23ai Free:

  ORA-01722: Zeichenfolgenwert mit 'g' kann nicht in eine Zahl konvertiert werden:
  ORA-03302: (ORA-01722-Details) Ungültiger Zeichenfolgenwert: ***
  ORA-00001: Unique Constraint (APP.UQ) für Tabelle APP.USERS mit Spalten (A, B) verletzt
  ORA-03301: (ORA-00001-Details) Zeile mit Spaltenwerten (A:***, B:***) ist bereits vorhanden
  ORA-01438: Wert *** ist größer als die angegebene Dezimalstellenanzahl (4, 1) für Spalte
  ORA-61800: Ungültiges boolesches Literal: ***
  ORA-01428: Argument *** befindet sich außerhalb des zulässigen Wertebereichs.

French, measured the same way:

  ORA-01722: impossible de convertir une valeur de chaîne contenant '***' en un nombre :
  ORA-03302: (Détails ORA-01722) valeur de chaîne non valide : ***
  ORA-00001: violation de contrainte unique (APP.UQ) sur la table APP.USERS colonnes (A, B)
  ORA-03301: (Détails ORA-00001) la ligne avec les valeurs de colonne (A:***, B:***) existe déjà
  ORA-01438: valeur *** supérieure à la précision indiquée (4, 1) pour la colonne
  ORA-61800: valeur littérale booléenne non valide : ***
  ORA-01428: L'argument *** est hors limites.

Where the structure is not there -- a label with no colon, a key without
brackets or without the details, a line of C<ORA-01438> or C<ORA-01428> with no
number (and, for C<ORA-01438>, no precision) -- the form is of a language or a
build nobody has measured, and the text after the code is replaced by C<***>
altogether (C<ORA-03302: ***>). The code and, for C<ORA-03301>, the line of
C<ORA-00001> with the columns stay; nothing of the value does. A masked text
is masked again to itself.

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

A message of a code that quotes no value is returned as it is, and so is one
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
