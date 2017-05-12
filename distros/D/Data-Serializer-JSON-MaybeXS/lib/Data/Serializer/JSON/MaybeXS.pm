package Data::Serializer::JSON::MaybeXS;
$Data::Serializer::JSON::MaybeXS::VERSION = '0.01';
BEGIN { @Data::Serializer::JSON::MaybeXS::ISA = qw(Data::Serializer) }

# This code was pretty much stolen and modified from:
# Data::Serializer::JSON.

use warnings;
use strict;
use JSON::MaybeXS qw();
use vars qw(@ISA);

sub json {
    my ($self) = @_;

    $self->{json} ||= JSON::MaybeXS->new(
        %{ $self->{options} },
    );

    return $self->{json};
}

sub serialize {
    my ($self, $data) = @_;
    return $self->json->encode( $data );
}

sub deserialize {
    my ($self, $json) = @_;
    return $self->json->decode( $json );
}

1;
__END__

=head1 NAME

Data::Serializer::JSON::MaybeXS - Serialize data using JSON::MaybeXS.

=head1 SYNOPSIS

    my $serializer = Data::Serializer->new(
        serializer => 'JSON::MaybeXS',
    );
    
    my $json = $serializer->serialize( { foo=>'bar' } );
    my $data = $serializer->deserialize( $json );

=head1 DESCRIPTION

This L<Data::Serializer> driver uses L<JSON::MaybeXS> to serialize and
deserialize data.

=head1 OPTIONS

You may pass an options hash ref to L<Data::Serializer> and those
options will be used when instantiating the L<JSON::MaybeXS> object:

    my $serializer = Data::Serializer->new(
        serializer => 'JSON::MaybeXS',
        options => {
            utf8         => 1,
            allow_nonref => 1,
        },
    );

=head1 SUPPORT

Please submit bugs and feature requests to the
Data-Serializer-JSON-MaybeXS GitHub issue tracker:

L<https://github.com/bluefeet/Data-Serializer-JSON-MaybeXS/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

