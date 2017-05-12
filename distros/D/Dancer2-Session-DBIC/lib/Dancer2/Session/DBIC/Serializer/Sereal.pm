package Dancer2::Session::DBIC::Serializer::Sereal;

=head1 NAME

Dancer2::Session::DBIC::Serializer::Sereal

=head1 DESCRIPTION

Use L<Sereal> serialization for session storage.

=cut

use Sereal::Encoder;
use Sereal::Decoder;
use Moo;
with 'Dancer2::Session::DBIC::Role::Serializer';
use namespace::clean;

=head1 ATTRIBUTES

See L<Dancer2::Session::DBIC::Role::Serializer> for inherited attributes.

B<NOTE:> you must install L<Sereal::Encoder> and L<Sereal::Decoder> to use this
serializer.

=head1 METHODS

=head2 serialize $perl_objects

Serialize C<$perl_objects> to Sereal.

=cut

sub serialize {
    shift->serializer->encode(shift);
}

sub _build_serializer {
    Sereal::Encoder->new( shift->serialize_options );
}

=head2 deserialize $sereal

Deserialize C<$sereal> to Perl objects.

=cut

sub deserialize {
    shift->deserializer->decode(shift);
}

sub _build_deserializer {
    Sereal::Decoder->new( shift->deserialize_options );
}

1;
