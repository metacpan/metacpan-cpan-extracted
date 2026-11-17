package DBIO::DB2::Storage::Cursor;
# ABSTRACT: Reads the character columns of a Db2 result as characters and its decimals with a point

use strict;
use warnings;

our $VERSION = '0.900007';

use base 'DBIO::Storage::DBI::Cursor';

use List::Util ();
use DBIO::Util qw(shuffle_unordered_resultsets);


# the TYPE the DBD reports for a numeric column with a fraction: SQL_NUMERIC,
# SQL_DECIMAL, SQL_FLOAT, SQL_REAL, SQL_DOUBLE and the CLI code of DECFLOAT
my %FRACTIONAL_TYPE = map { $_ => 1 } (2, 3, 6, 7, 8, -360);

# the TYPE the DBD reports for a character column: SQL_CHAR, SQL_VARCHAR,
# SQL_LONGVARCHAR, the wide forms, and the CLI codes of CLOB and DBCLOB
my %CHARACTER_TYPE = map { $_ => 1 } (1, 12, -1, -8, -9, -10, -99, -350, 40);


sub decode_rows {
  my ($class, $storage, $sth, @rows) = @_;
  return unless $sth;

  my $types = $sth->{TYPE} || [];
  my @numbers = grep { $FRACTIONAL_TYPE{ $types->[$_] // '' } } 0 .. $#$types;
  my @chars   = $storage->_utf8_database
    ? grep { $CHARACTER_TYPE{ $types->[$_] // '' } } 0 .. $#$types
    : ();
  return unless @numbers || @chars;

  for my $row (@rows) {
    for my $i (@numbers) {
      # exactly one comma, no grouping: the form the CLI writes under a
      # locale with a decimal comma
      $row->[$i] =~ tr/,/./
        if defined $row->[$i] && $row->[$i] =~ /\A[-+]?\d*,\d*(?:[Ee][-+]?\d+)?\z/;
    }
    for my $i (@chars) {
      utf8::decode($row->[$i]) if defined $row->[$i];
    }
  }
  return;
}


sub next {
  my $self = shift;
  my @row = $self->next::method(@_);
  return @row unless @row;
  $self->decode_rows($self->storage, $self->sth, \@row);
  return @row;
}


sub all {
  my $self = shift;

  # with a software limit core's all goes through next
  return $self->next::method(@_)
    if $self->{attrs}{software_limit}
      && ($self->{attrs}{offset} || $self->{attrs}{rows});

  my $sth;
  if ($sth = $self->sth) {
    $sth->finish if ( ! $self->{_done} and $sth->FETCH('Active') );
    $self->sth(undef);
  }

  (undef, $sth) = $self->storage->_select( @{$self->{args}} );

  my @rows = @{ $sth->fetchall_arrayref };
  $self->decode_rows($self->storage, $sth, @rows);
  return (shuffle_unordered_resultsets and ! $self->{attrs}{order_by})
    ? List::Util::shuffle(@rows)
    : @rows;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Storage::Cursor - Reads the character columns of a Db2 result as characters and its decimals with a point

=head1 VERSION

version 0.900007

=head1 DESCRIPTION

L<DBD::DB2> returns the text of a result as the UTF-8 bytes the server holds,
without the UTF-8 flag, and has no attribute to change that. This
cursor decodes them: every column of a character type (C<CHAR>, C<VARCHAR>,
C<LONG VARCHAR>, C<CLOB>, C<DBCLOB>, the wide forms) of a database whose
code set is UTF-8 (L<DBIO::DB2::Storage/_utf8_database>). A binary column
(C<BLOB>, C<BINARY>, C<VARBINARY>) is left as it comes, a C<NULL> stays C<NULL>,
and a database that is not UTF-8 is read as the DBD hands it over.

A numeric column with a fraction (C<DECIMAL>, C<NUMERIC>, C<REAL>, C<DOUBLE>,
C<DECFLOAT>) is delivered with a decimal point whatever the locale of the
process is. The CLI formats such a value by the C<LC_CTYPE> the process had
when it connected, so under a German locale it hands over C<1234567890,12>,
which Perl reads as C<1234567890>. Nothing a client can set steers that (not
C<LANGUAGE>, C<DB2CODEPAGE>, C<DB2TERRITORY>, a DSN key), and the process
locale is not DBIO's to change, so the cursor repairs the text: a value of
such a column with exactly one comma, optionally an exponent, and no grouping
gets a point in its place. Every other value is left as it comes. DBIO sets
no environment and no session setting for this, and does not touch the locale
of the process. This holds with or without a UTF-8 database.

Used by L<DBIO::DB2::Storage> as its C<cursor_class>. Rows that do not come
through a cursor (L<DBIO::Storage::DBI/select_single>, the plan rows of
C<explain>) go through L</decode_rows> as well.

=head1 METHODS

=head2 decode_rows

    DBIO::DB2::Storage::Cursor->decode_rows($storage, $sth, \@row, ...);

Repairs, in place, the given rows (array references) of the result of C<$sth>:
the character columns are decoded when the database is UTF-8, and a numeric
column with a fraction gets a decimal point for a comma, whether the database
is UTF-8 or not. The one place that does it, for the cursor and for
L<DBIO::DB2::Storage/select_single>.

=head2 next

L<DBIO::Storage::DBI::Cursor/next>, the columns repaired by L</decode_rows>.

=head2 all

L<DBIO::Storage::DBI::Cursor/all>, the columns repaired by L</decode_rows>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
