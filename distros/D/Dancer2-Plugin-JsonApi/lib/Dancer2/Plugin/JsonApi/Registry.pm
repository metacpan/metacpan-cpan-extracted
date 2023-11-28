package Dancer2::Plugin::JsonApi::Registry;
our $AUTHORITY = 'cpan:YANICK';
$Dancer2::Plugin::JsonApi::Registry::VERSION = '0.0.1';
use 5.32.0;
use Dancer2::Plugin::JsonApi::Schema;

use Carp;

use Moo;

use experimental qw/ signatures /;

sub serialize ( $self, $type, $data, $extra_data = {} ) {
    return $self->type($type)->serialize( $data, $extra_data );
}

sub deserialize ( $self, $data, $included = [] ) {

    my $type =
      ref $data->{data} eq 'ARRAY'
      ? $data->{data}[0]->{type}
      : $data->{data}{type};

    return $self->type($type)->deserialize( $data, $included );
}

has types => (
    is      => 'ro',
    default => sub { +{} },
);

has app => ( is => 'ro', );

sub add_type ( $self, $type, $definition = {} ) {
    $self->{types}{$type} = Dancer2::Plugin::JsonApi::Schema->new(
        registry => $self,
        type     => $type,
        %$definition
    );
}

sub type ( $self, $type ) {
    return $self->types->{$type} //=
      Dancer2::Plugin::JsonApi::Schema->new( type => $type );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::JsonApi::Registry

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

The registry for the different types of data managed by the plugin.

=head1 METHODS

=head2 add_type($type, $definition = {})

Adds a data type to the registry.

=head2 type($type)

Returns the type's C<Dancer2::Plugin::JsonApi::Schema>. Throws an
error if the type does not exist.

=head2 serialize($type,$data,$extra_data={})

Returns the serialized form of C<$data>.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
