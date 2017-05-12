package Dancer2::Session::DBIC::Serializer::JSON;

=head1 NAME

Dancer2::Session::DBIC::Serializer::JSON

=head1 DESCRIPTION

Use L<JSON::MaybeXS> serialization for session storage.

=cut

use JSON::MaybeXS;
use Moo;
with 'Dancer2::Session::DBIC::Role::Serializer';
use namespace::clean;

=head1 ATTRIBUTES

See L<Dancer2::Session::DBIC::Role::Serializer> for inherited attributes.

=head2 serialize_options

Override default with the following options:

=over

=item pretty => 0

=item convert_blessed => 1

=back

=cut

has '+serialize_options' => (
    default => sub {
        { pretty => 0, convert_blessed => 1 };
    },
);

=head1 METHODS

=head2 serialize $perl_objects

Serialize C<$perl_objects> to JSON.

=cut

sub serialize {
    shift->serializer->encode(shift);
}

sub _build_serializer {
    JSON::MaybeXS->new( shift->serialize_options );
}

=head2 deserialize $json

Deserialize C<$json> to Perl objects.

=cut

sub deserialize {
    shift->deserializer->decode(shift);
}

sub _build_deserializer {
    JSON::MaybeXS->new( shift->deserialize_options );
}

1;
