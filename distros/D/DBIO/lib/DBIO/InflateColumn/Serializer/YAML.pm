package DBIO::InflateColumn::Serializer::YAML;
# ABSTRACT: YAML Inflator

use strict;
use warnings;
use YAML;
use Carp;
use namespace::clean;


sub get_freezer {
  my ($class, $column, $info, $args) = @_;

  if (defined $info->{'size'}){
      my $size = $info->{'size'};
      return sub {
        my $s = YAML::Dump(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return YAML::Dump(shift);
      };
  }
}


sub get_unfreezer {
  return sub {
    return YAML::Load(shift);
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::InflateColumn::Serializer::YAML - YAML Inflator

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::Serializer');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'YAML'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to C<data_column> are saved in YAML format.

=head1 DESCRIPTION

YAML backend for L<DBIO::InflateColumn::Serializer>. Loaded
automatically when a column declares
C<< serializer_class => 'YAML' >>.

=head1 METHODS

=head2 get_freezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that serializes
the data passed to it. Returns a coderef.

=head2 get_unfreezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that deserializes
the data stored in the column. Returns a coderef.

=head1 COLUMN INFO

=over 4

=item C<< serializer_class => 'YAML' >>

Selects this backend.

=item C<< size => $n >>

Optional. Serialised payload is checked against C<size> on deflate;
over-long payloads throw.

=back

=head1 DEPENDENCIES

L<YAML>. Not a hard dependency of DBIO; install separately.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
