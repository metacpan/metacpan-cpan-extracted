use 5.006;    # our
use strict;
use warnings;

package DBIx::Class::InflateColumn::Serializer::Sereal;

our $VERSION = '0.001002';

# ABSTRACT: Sereal based Serialization for DBIx Class Columns

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Sereal::Encoder 2.070000 qw( sereal_encode_with_object );
use Sereal::Decoder 2.070000 qw( sereal_decode_with_object );
use Carp qw( croak );

sub get_freezer {
  my ( undef, undef, $col_info, undef ) = @_;
  my $encoder = Sereal::Encoder->new();
  if ( defined $col_info->{'size'} ) {
    return sub {
      my $v = sereal_encode_with_object( $encoder, $_[0] );
      croak('Value Serialization is too big')
        if length($v) > $col_info->{'size'};
      return $v;
    };
  }
  return sub {
    return sereal_encode_with_object( $encoder, $_[0] );
  };
}

sub get_unfreezer {
  my $decoder = Sereal::Decoder->new();
  return sub {
    return sereal_decode_with_object( $decoder, $_[0] );
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::Serializer::Sereal - Sereal based Serialization for DBIx Class Columns

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

Standard DBIx::Class definition:

  package Some::Result::Item;
  use parent 'DBIx::Class::Core';

  # Add Inflate::Column::Serializer to component loading.
  __PACKAGE__->load_components( 'InflateColumn::Serializer', 'Core' );
  __PACKAGE__->table('item');
  __PACKAGE__->add_column( itemid => { data_type => 'integer' }, );
  __PACKAGE__->set_primary_key('itemid');
  __PACKAGE__->add_column(
    data => {
      data_type        => 'text',
      size             => 1024,
      serializer_class => 'Sereal', # This line tells InflateColumn::Serializer what class to use.
    }
  );
  __PACKAGE__->source_name('Item');

=head1 METHODS

=head2 get_freezer

This is an implementation detail for the C<InflateColumn::Serializer> module.

   my $freezer = ::Sereal->get_freezer( $column, $info, $column_args );
   my $string = $freezer->( $object );
   # $data isa string

=head2 get_unfreezer

This is an implementation detail for the C<InflateColumn::Serializer> module.

    my $unfreezer = ::Sereal>get_unfreezer( $column, $info, $args );
    my $object = $unfreezer->( $string );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
