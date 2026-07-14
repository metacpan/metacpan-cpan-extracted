package DBIO::InflateColumn::Serializer::MessagePack;
# ABSTRACT: MessagePack Inflator

use strict;
use warnings;
use Data::MessagePack;
use Carp;
use namespace::clean;


sub get_freezer {
  my ($class, $column, $info, $args) = @_;

  my $mp = Data::MessagePack->new->utf8;

  if (defined $info->{'size'}){
      my $size = $info->{'size'};
      return sub {
        my $s = $mp->pack(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return $mp->pack(shift);
      };
  }
}


sub get_unfreezer {
  my ($class, $column, $info, $args) = @_;

  my $mp = Data::MessagePack->new->utf8;
  return sub {
    $mp->unpack(shift);
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::InflateColumn::Serializer::MessagePack - MessagePack Inflator

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::Serializer');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'BLOB',
      'serializer_class'   => 'MessagePack'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database
in MessagePack format. MessagePack is a compact binary serialization format,
ideal for columns where space efficiency matters.

See F<t/serialize/01-inflatecolumn.t> for a runnable example.

=head1 DESCRIPTION

MessagePack backend for L<DBIO::InflateColumn::Serializer>. Loaded
automatically when a column declares
C<< serializer_class => 'MessagePack' >>.

=head1 METHODS

=head2 get_freezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that serializes
the data passed to it. Returns a coderef.

=head2 get_unfreezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that deserializes
the data stored in the column. Returns a coderef.

=head1 COLUMN INFO

=over 4

=item C<< serializer_class => 'MessagePack' >>

Selects this backend.

=item C<< size => $n >>

Optional. Serialised payload is checked against C<size> on deflate;
over-long payloads throw.

=back

=head1 DEPENDENCIES

L<Data::MessagePack>. Not a hard dependency of DBIO; install separately.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
