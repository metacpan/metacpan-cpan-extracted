use 5.38.0;


package Dancer2::Serializer::JsonApi;
our $AUTHORITY = 'cpan:YANICK';
$Dancer2::Serializer::JsonApi::VERSION = '0.0.1';
use Dancer2::Plugin::JsonApi::Registry;
use Dancer2::Serializer::JSON;

use Moo;


has content_type => ( is => 'ro', default => 'application/vnd.api+json' );

with 'Dancer2::Core::Role::Serializer';


has registry => (
    is      => 'rw',
    default => sub { Dancer2::Plugin::JsonApi::Registry->new }
);


has json_serializer => (
    is      => 'ro',
    default => sub { Dancer2::Serializer::JSON->new }
);


sub serialize {
    my ( $self, $data ) = @_;

    return $self->json_serializer->serialize(
        $self->registry->serialize(@$data) );
}


sub deserialize ( $self, $serialized, @ ) {
    $self->registry->deserialize(
        $self->json_serializer->deserialize($serialized) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Serializer::JsonApi

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

As part of a Dancer2 App: 

    # in config.yaml
    
    serializer: JsonApi  

As a standalone module: 

    use Dancer2::Serializer::JsonApi;
    use Dancer2::Plugin::JsonApi::Registry;

    my $registry = Dancer2::Plugin::JsonApi::Registry->new;

    $registry->add_type( 'spaceship' => {
        relationships => {
            crew => { type => 'person' }
        }
    } );

    $registry->add_type( 'person' );

    my $serializer = Dancer2::Serializer::JsonApi->new( 
        registry => $registry 
    );

    my $serialized = $serializer->serialize([ 
        'spaceship', {
            id => 1,
            name => 'Unrequited Retribution',
            crew => [
                { id => 2, name => 'One-eye Flanagan', species => 'human' },
                { id => 3, name => 'Flabgor', species => 'Moisterian' },
            ]
        }
    ]);

=head1 DESCRIPTION

Serializer for JSON:API. Takes in a data structure, munge it to conforms to the JSON:API format (potentially based on a provided registry of JSON:API schemas),
and encode it as JSON.

Note that using Dancer2::Plugin::JsonApi in an app will automatically
set C<Dancer2::Serializer::JsonApi> as its serializer if it's not already defined.

=head1 ATTRIBUTES

=head2 content_type

Returns the content type used by the serializer, which is C<application/vnd.api+json>;

=head2 registry 

The L<Dancer2::Plugin::JsonApi::Registry> to use. 

=head2 json_serializer

The underlying JSON serializer. Defaults to L<Dancer2::Serializer::JSON>.

=head1 METHODS

=head2 $self->serialize( [ $type, $data, $xtra ])

Serializes the C<$data> using the C<$type> from the registry. 
The returned value will be a JSON string.

=head2 $self->deserialize( $json_string )

Takes in the serialized C<$json_string> and recreate data out of it.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
