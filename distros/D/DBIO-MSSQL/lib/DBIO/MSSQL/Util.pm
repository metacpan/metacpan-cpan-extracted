package DBIO::MSSQL::Util;
# ABSTRACT: Shared MSSQL-specific helper functions for DBIO

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

# A value in single quotes, an apostrophe inside written twice. Possessive, so
# a text without the closing quote costs one pass and no backtracking.
my $QUOTED = qr/'(?:[^']++|'')*+'/;

# What stands for the text of a message whose value cannot be told from its
# words (see _mask_by_number).
my $WITHHELD = '(text withheld: the server may quote a value in it)';

# The server's message numbers whose text quotes a value, and how. The numbers
# do not depend on the language the session reports in; the words around the
# value do.
my %QUOTED_VALUE = map { $_ => 1 } (
  244, 248,                   # The conversion of the varchar value 'x' overflowed ...
  245,                        # Conversion failed when converting the varchar value 'x' ...
  102,                        # Incorrect syntax near 'x'  (the keyword form is 156)
  13607, 13609,               # JSON path / text: Unexpected character 'g' ...
);
my %PAREN_VALUE   = map { $_ => 1 } (2627, 2601, 1505);   # The duplicate key value is (x).
my %TRUNCATED     = (2628 => 1);                          # ... column 's'. Truncated value: 'x'.

# The ODBC SQLSTATE of the forms, where the driver gave no server number.
my %STATE_NUMBER = ('22018' => 245, 'HY019' => 248, '23000' => 2627);

# Pairs of quote marks the server's translations use: ' ' " " << >> and the
# typographic ones of de, cs, hu, pl, zh ...
my %CLOSER = (
  "'"      => qr/['\x{2019}]/,
  '"'      => qr/"/,
  "\x{AB}" => qr/\x{BB}/,
  "\x{201E}" => qr/["\x{201C}\x{201D}]/,
  "\x{201C}" => qr/\x{201D}/,
  "\x{201D}" => qr/\x{201D}/,
  "\x{2018}" => qr/\x{2019}/,
);
my $OPENER = qr/(?<![A-Za-z])(['"\x{AB}\x{201E}\x{201C}\x{201D}\x{2018}])/;

# The server's messages that carry their own English text are the business of
# _mask_sentences, which also knows the cut ones.
my $ENGLISH = qr/Conversion failed when converting the|The conversion of the \w+ value|Incorrect syntax near|The duplicate key value is|Truncated value:|JSON (?:text|path) is not properly formatted/;

# Texts of a message that the Sybase class of this driver builds itself.
my $GUARD = 'DBIO::MSSQL TEXTSIZE guard: column';

# Some text -> the same with the value of one quoted group masked, or undef:
# the group is the first quoted one up to the last closing mark of its kind
# (the words after the value hold no quote mark, an apostrophe inside the
# value is no problem); a message cut by the server has no closing mark and
# is masked to its end.
sub _mask_quoted {
  my ($body) = @_;
  return undef unless $body =~ $OPENER;
  my ($open, $at) = ($1, $-[1]);
  my $closer = $CLOSER{$open};
  my $end = length $body;
  if (length $body < 1500) {
    my $last;
    while ($body =~ /$closer/g) { $last = $-[0] if $-[0] > $at }
    $end = $last if defined $last;
  }
  return substr($body, 0, $at + 1) . $MASK . substr($body, $end);
}

# (x) in the message: from the first parenthesis to the last one.
sub _mask_paren {
  my ($body) = @_;
  my $at = index $body, '(';
  return undef if $at < 0;
  my $last = rindex $body, ')';
  $last = length $body if $last < $at || length $body >= 1500;
  return substr($body, 0, $at + 1) . $MASK . substr($body, $last);
}

# The names of table and column come first, quoted; what follows them is the
# value, in whatever words.
sub _mask_truncated {
  my ($body) = @_;
  my ($names, $upto) = (0, 0);
  while ($names < 2 && $body =~ /$OPENER([^'"\x{AB}\x{BB}\x{201E}\x{201C}\x{201D}\x{2018}\x{2019}]*)(['"\x{BB}\x{201C}\x{201D}\x{2019}])/g) {
    $names++;
    $upto = pos $body;
  }
  return undef unless $names == 2;
  return substr($body, 0, $upto) . " $MASK";
}

# Masks the values in the messages of any language, by the number the server
# gave the message: DBD::Sybase puts "Server message number=N" in front of
# the text; DBD::ODBC gives no number in the text, so the storage hands the
# numbers the driver reported ($diag: [ [ number, text ], ... ]), and the
# SQLSTATE behind the text is the fallback. A message of such a number is
# masked at the marks the server quotes with, or -- when no mark is there to
# take hold of -- loses its text. A message that carries English words of
# its own is left to _mask_sentences.
sub _mask_by_number {
  my ($text, $diag) = @_;

  my @marks;
  while ($text =~ /(?:Server message number=(\d+)\b[^\n]*?\btext=|(?:\[[^\]\n]+\])*\[SQL Server\])/g) {
    push @marks, [ $-[0], $+[0], $1 ];
  }
  return $text unless @marks;

  my $out = substr $text, 0, $marks[0][0];
  for my $i (0 .. $#marks) {
    my ($from, $to, $number) = @{ $marks[$i] };
    my $next = $i < $#marks ? $marks[$i + 1][0] : length $text;
    my $body = substr $text, $to, $next - $to;
    $out .= substr $text, $from, $to - $from;

    my ($core, $tail, $state) = ($body, '', undef);
    if (not defined $number
        and $body =~ /\A(.*)(\s*\(SQL-(\w{5})\)(?:(?!\(SQL-\w{5}\)).)*)\z/s) {
      ($core, $tail, $state) = ($1, $2, $3);
    }

    my $cmp = $core;
    $cmp =~ s/\s+\z//;
    if (not defined $number) {
      for my $d (@{ $diag // [] }) {
        (my $dt = $d->[1]) =~ s/\A(?:\[[^\]\n]+\])*\[SQL Server\]//;
        $dt =~ s/\s+\z//;
        if ($dt eq $cmp) { $number = $d->[0]; last }
      }
    }
    $number = $STATE_NUMBER{$state} if not defined $number and defined $state;

    if (defined $number
        and ($QUOTED_VALUE{$number} or $PAREN_VALUE{$number} or $TRUNCATED{$number})
        and $core !~ $ENGLISH and index($core, $GUARD) < 0) {
      my $masked = $QUOTED_VALUE{$number} ? _mask_quoted($core)
                 : $PAREN_VALUE{$number}  ? _mask_paren($core)
                 :                          _mask_truncated($core);
      # the blank before the text, if there was one, stays
      if (defined $masked) { $core = $masked }
      else {
        my ($lead) = $core =~ /\A(\s*)/;
        $core = "$lead$WITHHELD" . ($core =~ /(\s*)\z/ ? $1 : '');
      }
    }
    $out .= $core . $tail;
  }
  return $out;
}

# The DBDs hand the text over as the bytes of its UTF-8 form or as characters;
# the marks of the translations are characters.
sub _mask_by_number_in_characters {
  my ($text, $diag) = @_;

  my $bytes = 0;
  if (not utf8::is_utf8($text) and $text =~ /[^\x00-\x7F]/) {
    my $chars = $text;
    if (utf8::decode($chars)) { $bytes = 1; $text = $chars }
  }

  my @diag = map {
    my $t = $_->[1];
    if (defined $t and not utf8::is_utf8($t) and $t =~ /[^\x00-\x7F]/) {
      my $chars = $t;
      $t = $chars if utf8::decode($chars);
    }
    [ $_->[0], $t // '' ];
  } @{ $diag // [] };

  $text = _mask_by_number($text, \@diag);
  utf8::encode($text) if $bytes;
  return $text;
}


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
  my ($message, $binds, $statement, $diag) = @_;
  return $message unless defined $message && length $message;

  $message = _mask_by_number_in_characters($message, $diag);
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

version 0.900007

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
  my $message = mask_error_details($message, \@binds, $statement, \@diag);

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

B<The language of the session does not matter.> SQL Server reports in the
language of the session (C<SET LANGUAGE>, the login's or the server's
default), and the words around a quoted value change with it (German
C<Fehler beim Konvertieren des varchar-Werts "xy" in den int-Datentyp.>,
French C<Échec de la conversion de la valeur varchar 'xy' en type de données
int.>). So the message is looked at by its B<number>, which is the same in
every language: 244, 245, 248 (conversion, overflow), 102, 13607 and 13609
(syntax, JSON) quote one value, in whatever marks the language uses
(C<'x'>, C<"x">, C<« x »>, C<„x“>, C<“x”>); 2627, 2601 and 1505 (duplicate
key) put it in parentheses; 2628 (truncated) puts it after the quoted names
of the table and the column. The value is replaced by C<***>, the words and
the names stay. Where the server uses no mark (Czech, Finnish, Swedish,
Dutch ... write the value as a bare word) the value cannot be told from the
words: B<the text of that message falls away>, C<(text withheld: the server
may quote a value in it)>, and the number stays. A message of a number that
quotes no value (the keyword form 156, 8114, a foreign key violation) is not
touched in any language. The number is the C<Server message number=N> of
DBD::Sybase; DBD::ODBC has none in the text, so C<$diag> -- the diagnostic
records of the failing handle as C<[ [ $number, $text ], ... ]>, which
L<DBIO::MSSQL::Storage::ODBC> hands over -- supplies it, and the SQLSTATE
behind the text (22018, HY019, 23000) is the fallback where there are no
records. A message that carries the English words of a rule above is left to
that rule. Measured with SQL Server 2022 in 25 languages, over both DBDs
(F<t/131-error-values-language-live.t>, F<t/132-error-mask-languages.t>).

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

C<$diag> is optional (see above). C<$statement> is accepted for the family's signature and not used: SQL Server
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
