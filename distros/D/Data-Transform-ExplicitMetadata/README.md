[![Build Status](https://travis-ci.org/brummett/Data-Transform-ExplicitMetadata.png?branch=master)](https://travis-ci.org/brummett/Data-Transform-ExplicitMetadata)
## Data::Transform::ExplicitMetadata

Transform a Perl data structure into one with basic data types and
explicit metadata.  This data structure can be safely JSON encoded.

## Description

The JSON module can only encode Perl data structures directly representable
as JSON strings: simple scalars, arrayrefs and hashrefs.

This module transforms a perl data structure into one which may safely
be JSON encoded, while maintaining Perl-specific metadata that isn't directly
expressable in JSON such as blessed and tied references, self-referential
data, typeglobs, reference addresses, etc.

When destrializing, it recreates the original data as closely as possible.

It also includes a Javascript library to manipulate the data structure
created from the JSON string.

## Usage

    use Data::Transform::ExplicitMetadata;
    use JSON;
    
    my $encoded = Data::Transform::ExplicitMetadata::encode($perl_data);
    my $json_string = JSON::encode_json($encoded);

    my $perl_copy = Data::Transform::ExplicitMetadata::decode($encoded);
