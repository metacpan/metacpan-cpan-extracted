package Dancer2::Plugin::Redis::Serialization::Sereal;
use strictures 1;
# ABSTRACT: Dancer2::Plugin::Redis serialization broker for Sereal.
#
# This file is part of Dancer2-Plugin-Redis
#
# This software is Copyright (c) 2016 by BURNERSK <burnersk@cpan.org>.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#

BEGIN {
  our $VERSION = '0.001';  # fixed version - NOT handled via DZP::OurPkgVersion.
}

use Types::Standard qw( Bool InstanceOf );
use Moo;
use Sereal::Decoder qw( looks_like_sereal );
use Sereal::Encoder qw( SRL_UNCOMPRESSED SRL_SNAPPY );

with 'Dancer2::Plugin::Redis::SerializationRole';


############################################################################

has snappy => (
  is      => 'ro',
  isa     => Bool,
  default => 1,
);

has _decoder => (
  is      => 'lazy',
  isa     => InstanceOf ['Sereal::Decoder'],
  builder => sub { Sereal::Decoder->new },
);

has _encoder => (
  is      => 'lazy',
  isa     => InstanceOf ['Sereal::Encoder'],
  builder => sub {
    my ($self) = @_;
    my $snappy = $self->snappy ? SRL_SNAPPY : SRL_UNCOMPRESSED;
    return Sereal::Encoder->new( {
      compress           => $snappy,  # use Google Snappy compression algorithm if wanted.
      compress_threshold => 1024,     # compress when content is 1 kbyte or bigger.
      croak_on_bless     => 0,        # do not croak on blessed objects.
      undef_unknown      => 0,        # do not undef unknown objects.
      stringify_unknown  => 0,        # do not stringify unknown objects.
      warn_unknown       => 1,        # carp on unknown objects.
      sort_keys          => 0,        # do not sort keys. we do not care abount sorting but performance.
    } );
  },
);

############################################################################

sub decode {
  my ( $self, $serialized_object ) = @_;
  # deserealize stuff only if Sereal thinks it can do it.
  return $serialized_object unless looks_like_sereal $serialized_object;
  return $self->_decoder->decode($serialized_object);
}


sub encode {
  my ( $self, $raw_object ) = @_;
  return $raw_object if defined $raw_object && !ref $raw_object;  # do not serialize simple scalars (strings).
  return $self->_encoder->encode($raw_object);
}


############################################################################


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Redis::Serialization::Sereal - Dancer2::Plugin::Redis serialization broker for Sereal.

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your I<config.yml>:

    plugins:
      Redis:
        # ...
        # Use serialization for storing values other than simple scalars with Redis:
        serialization:
          # Use Sereal as serialization module:
          module: "Dancer2::Plugin::Redis::Serialization::Sereal"
          # Serialization module configuration:
          # (optional) Enable Google Snappy compression (default):
          snappy: 1

=head1 DESCRIPTION

This module is a serialization broker for Dancer2::Plugin::Redis. It will
provide Dancer2::Plugin::Redis the ability to (de)serialize Redis values with
Sereal.

=head1 METHODS

=head2 decode

Deserialize a serialized object. Returns the (not really) serealized object without doing
anything to it if Sereal thinks it is not serealized.

=head2 encode

Serialize a raw object if it is a reference or undef.

=head1 SEE ALSO

=over

=item L<Dancer2::Plugin::Redis>

=item L<Sereal>

=back

=head1 AUTHOR

BURNERSK <burnersk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by BURNERSK <burnersk@cpan.org>.

This is free software, licensed under:

  The MIT (X11) License

=cut
