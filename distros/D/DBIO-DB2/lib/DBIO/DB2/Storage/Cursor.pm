package DBIO::DB2::Storage::Cursor;
# ABSTRACT: Reads the character columns of a Db2 result as characters

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::DBI::Cursor';

use List::Util ();
use DBIO::Util qw(shuffle_unordered_resultsets);


# the TYPE the DBD reports for a character column: SQL_CHAR, SQL_VARCHAR,
# SQL_LONGVARCHAR, the wide forms, and the CLI codes of CLOB and DBCLOB
my %CHARACTER_TYPE = map { $_ => 1 } (1, 12, -1, -8, -9, -10, -99, -350, 40);


sub decode_rows {
  my ($class, $storage, $sth, @rows) = @_;
  return unless $sth && $storage->_utf8_database;

  my $types = $sth->{TYPE} || [];
  my @chars = grep { $CHARACTER_TYPE{ $types->[$_] // '' } } 0 .. $#$types;
  return unless @chars;

  for my $row (@rows) {
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

DBIO::DB2::Storage::Cursor - Reads the character columns of a Db2 result as characters

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

L<DBD::DB2> returns the text of a result as the UTF-8 bytes the server holds,
without the UTF-8 flag, and has no attribute to change that. This
cursor decodes them: every column of a character type (C<CHAR>, C<VARCHAR>,
C<LONG VARCHAR>, C<CLOB>, C<DBCLOB>, the wide forms) of a database whose
code set is UTF-8 (L<DBIO::DB2::Storage/_utf8_database>). A binary column
(C<BLOB>, C<BINARY>, C<VARBINARY>) is left as it comes, a C<NULL> stays C<NULL>,
and a database that is not UTF-8 is read as the DBD hands it over.

Used by L<DBIO::DB2::Storage> as its C<cursor_class>. Rows that do not come
through a cursor (L<DBIO::Storage::DBI/select_single>, which reads numbers and
the like) are not decoded.

=head1 METHODS

=head2 decode_rows

    DBIO::DB2::Storage::Cursor->decode_rows($storage, $sth, \@row, ...);

Decodes, in place, the character columns of the given rows (array references)
of the result of C<$sth>. Nothing happens when the database is not UTF-8 or the
result has no character column. The one place that does it, for the cursor and
for L<DBIO::DB2::Storage/select_single>.

=head2 next

L<DBIO::Storage::DBI::Cursor/next>, the character columns decoded.

=head2 all

L<DBIO::Storage::DBI::Cursor/all>, the character columns decoded.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
