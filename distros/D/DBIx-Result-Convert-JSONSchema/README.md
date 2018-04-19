# NAME
    DBIx::Result::Convert::JSONSchema - Convert DBIx result schema to JSON schema

<div>

</div>

    <a href='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/github/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/p5-dbix-result-convert-jsonschema/badge.svg?branch=master' alt='Coverage Status' /></a>

# VERSION

    0.02

# SYNOPSIS

    use DBIx::Result::Convert::JSONSchema;

    my $SchemaConvert = DBIx::Result::Convert::JSONSchema->new(
        schema => _DBIx::Class::Schema_
    );
    my $json_schema = $SchemaConvert->get_json_schema( _DBIx::Class::ResultSource_ );

# DESCRIPTION

This module attempts basic conversion of [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource) to equivalent
of [http://json-schema.org/](http://json-schema.org/).
By default the conversion assumes that the [DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource) originated
from MySQL database. Thus all the types and defaults are set based on MySQL
field definitions.
It is, however, possible to overwrite field type map and length map to support
[DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource) from other database solutions.

Note, relations between tables are not taken in account!

## `get_json_schema`

Returns somewhat equivalent JSON schema based on DBIx result source name.

    my $json_schema = $converted->get_json_schema( 'TableSource', {
        decimals_to_pattern             => 1,
        has_schema_property_description => 1,
        allow_additional_properties     => 0,
        overwrite_schema_property_keys  => {
            name    => 'cat',
            address => 'dog',
        },
        overwrite_schema_properties     => {
            name => {
                _action  => 'merge', # one of - merge/overwrite
                minimum  => 10,
                maximum  => 20,
                type     => 'number',
            },
        },
        exclude_required   => [ qw/ name address / ],
        exclude_properties => [ qw/ mouse house / ],
    });

    ARGS:
        Required ARGS[0]:
            - Source name e.g. 'Address'
        Optional ARGS[1]:
            decimals_to_pattern:
                True/false value to indicate if 'number' type field should be converted to 'string' type with
                RegExp pattern based on decimal place definition in database
            has_schema_property_description:
                True/false value to indicate if basic JSON schema properties should include 'description' key
                containing basic information about field
            allow_additional_properties:
                1/0 to indicate if JSON schema should accept properties which are not defined by default
            overwrite_schema_property_keys:
                HashRef containing { OLD_PROPERTY => NEW_PROPERTY } to overwrite default column names, default
                property attributes from old key will be assigned to new key
                (!) The key conversion is executed last, every other option e.g. exclude_properties will work
                only on original database column names
            overwrite_schema_properties:
                HashRef of { PROPERTY_NAME => { ... JSON SCHEMA ATTRIBUTES ... } } which will replace default generated
                schema properties.
            exclude_required:
                ArrayRef of database column names which should always be EXCLUDED from required schema properties
            include_required:
                ArrayRef of database column names which should always be INCLUDED in required schema properties
            exclude_properties:
                ArrayRef of database column names which should be excluded from JSON schema

# SEE ALSO

[DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource) - Result source object

# AUTHOR

malishew - `malishew@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema
