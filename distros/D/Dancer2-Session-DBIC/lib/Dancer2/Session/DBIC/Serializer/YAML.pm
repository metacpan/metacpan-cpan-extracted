package Dancer2::Session::DBIC::Serializer::YAML;

=head1 NAME

Dancer2::Session::DBIC::Serializer::YAML

=head1 DESCRIPTION

Use YAML serialization for session storage.

B<NOTE:> you must install L<YAML> version >= 1.15 to use this serializer.

=cut

use YAML 1.15 ();
use YAML::Dumper;
use YAML::Loader;
use Moo;
with 'Dancer2::Session::DBIC::Role::Serializer';
use namespace::clean;

=head1 ATTRIBUTES

See L<Dancer2::Session::DBIC::Role::Serializer> for inherited attributes.

=head2 serialize_options

Override default with the following options:

=over

=item indent_width => 1

=back

=cut

has '+serialize_options' => (
    default => sub {
        { indent_width => 1 };
    },
);

=head1 METHODS

=head2 serialize $perl_objects

Serialize C<$perl_objects> to YAML using L<YAML::Dumper>.

=cut

sub serialize {
    shift->serializer->dump(shift);
}

sub _build_serializer {
    YAML::Dumper->new( %{ shift->serialize_options } );
}

=head2 deserialize $yaml

Deserialize C<$yaml> to Perl objects using L<YAML::Loader>.

=cut

sub deserialize {
    shift->deserializer->load(shift);
}

sub _build_deserializer {
    YAML::Loader->new( %{ shift->deserialize_options } );
}

1;
