# NAME

Data::Serializer::JSON::MaybeXS - Serialize data using JSON::MaybeXS.

# SYNOPSIS

    my $serializer = Data::Serializer->new(
        serializer => 'JSON::MaybeXS',
    );
    
    my $json = $serializer->serialize( { foo=>'bar' } );
    my $data = $serializer->deserialize( $json );

# DESCRIPTION

This [Data::Serializer](https://metacpan.org/pod/Data::Serializer) driver uses [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS) to serialize and
deserialize data.

# OPTIONS

You may pass an options hash ref to [Data::Serializer](https://metacpan.org/pod/Data::Serializer) and those
options will be used when instantiating the [JSON::MaybeXS](https://metacpan.org/pod/JSON::MaybeXS) object:

    my $serializer = Data::Serializer->new(
        serializer => 'JSON::MaybeXS',
        options => {
            utf8         => 1,
            allow_nonref => 1,
        },
    );

# SUPPORT

Please submit bugs and feature requests to the
Data-Serializer-JSON-MaybeXS GitHub issue tracker:

[https://github.com/bluefeet/Data-Serializer-JSON-MaybeXS/issues](https://github.com/bluefeet/Data-Serializer-JSON-MaybeXS/issues)

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
