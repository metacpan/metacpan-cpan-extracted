package DBIO::Storage::DBI::DataTypeClassifier;
# ABSTRACT: Native data type and LOB classification helpers for DBI storage

use strict;
use warnings;

use base 'DBIO::Storage';
use mro 'c3';
use namespace::clean;



sub _native_data_type {
  #my ($self, $data_type) = @_;
  return undef
}

# The size in bytes to use for DBI's ->bind_param_inout, this is the generic
# version and it may be necessary to amend or override it for a specific storage
# if such binds are necessary.
sub _max_column_bytesize {
  my ($self, $attr) = @_;

  my $max_size;

  if ($attr->{sqlt_datatype}) {
    my $data_type = lc($attr->{sqlt_datatype});

    if ($attr->{sqlt_size}) {

      # String/sized-binary types
      if ($data_type =~ /^(?:
          l? (?:var)? char(?:acter)? (?:\s*varying)?
            |
          (?:var)? binary (?:\s*varying)?
            |
          raw
        )\b/x
      ) {
        $max_size = $attr->{sqlt_size};
      }
      # Other charset/unicode types, assume scale of 4
      elsif ($data_type =~ /^(?:
          national \s* character (?:\s*varying)?
            |
          nchar
            |
          univarchar
            |
          nvarchar
        )\b/x
      ) {
        $max_size = $attr->{sqlt_size} * 4;
      }
    }

    if (!$max_size and !$self->_is_lob_type($data_type)) {
      $max_size = 100 # for all other (numeric?) datatypes
    }
  }

  $max_size || $self->_dbio_connect_attributes->{LongReadLen} || $self->_get_dbh->{LongReadLen} || 8000;
}

# Determine if a data_type is some type of BLOB
sub _is_lob_type {
  my ($self, $data_type) = @_;
  $data_type && ($data_type =~ /lob|bfile|text|image|bytea|memo/i
    || $data_type =~ /^long(?:\s+(?:raw|bit\s*varying|varbit|binary
                                  |varchar|character\s*varying|nvarchar
                                  |national\s*character\s*varying))?\z/xi);
}

sub _is_binary_lob_type {
  my ($self, $data_type) = @_;
  $data_type && ($data_type =~ /blob|bfile|image|bytea/i
    || $data_type =~ /^long(?:\s+(?:raw|bit\s*varying|varbit|binary))?\z/xi);
}

sub _is_text_lob_type {
  my ($self, $data_type) = @_;
  $data_type && ($data_type =~ /^(?:clob|memo)\z/i
    || $data_type =~ /^long(?:\s+(?:varchar|character\s*varying|nvarchar
                        |national\s*character\s*varying))\z/xi);
}

# Determine if a data_type is some type of a binary type
sub _is_binary_type {
  my ($self, $data_type) = @_;
  $data_type && ($self->_is_binary_lob_type($data_type)
    || $data_type =~ /(?:var)?(?:binary|bit|graphic)(?:\s*varying)?/i);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::DataTypeClassifier - Native data type and LOB classification helpers for DBI storage

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Data type and LOB classification helpers for L<DBIO::Storage::DBI>.

Provides pure regex/classification utilities for determining whether a given
SQL data type is a LOB, binary LOB, text LOB, binary type, or native type
alias.  Also provides C<_max_column_bytesize> which calculates the byte size
hint used for C<< $dbh->bind_param_inout >> calls.

Drivers override C<_native_data_type> to map foreign type names to their
native equivalents.  The LOB predicates may be overridden for RDBMS-specific
type hierarchies.

=head2 _native_data_type

=over 4

=item Arguments: $type_name

=back

This API is B<EXPERIMENTAL>, will almost definitely change in the future, and
currently only used by L<::AutoCast|DBIO::Storage::DBI::AutoCast> and
L<::Sybase::ASE|DBIO::Sybase::Storage::ASE>.

The default implementation returns C<undef>, implement in your Storage driver if
you need this functionality.

Should map types from other databases to the native RDBMS type, for example
C<VARCHAR2> to C<VARCHAR>.

Types with modifiers should map to the underlying data type. For example,
C<INTEGER AUTO_INCREMENT> should become C<INTEGER>.

Composite types should map to the container type, for example
C<ENUM(foo,bar,baz)> becomes C<ENUM>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
