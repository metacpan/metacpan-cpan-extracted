# NAME
    DBIx::Result::Convert::JSONSchema - Convert DBIx result schema to JSON schema

<div>
        <a href='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://travis-ci.org/Humanstate/p5-dbix-result-convert-jsonschema.svg?branch=master' alt='Build Status' /></a>
        <a href='https://coveralls.io/github/Humanstate/p5-dbix-result-convert-jsonschema?branch=master'><img src='https://coveralls.io/repos/github/Humanstate/p5-dbix-result-convert-jsonschema/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

    0.03

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

## get\_json\_schema

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

Optional arguments to change how JSON schema is generated:

- decimals\_to\_pattern

    1/0 - value to indicate if 'number' type field should be converted to 'string' type with
    RegExp pattern based on decimal place definition in database.

    **Default**: 0

- has\_schema\_property\_description

    Generates very basic schema description fields e.g. 'Optional numeric type value for field context e.g. 1'.

    **Default**: 0

- allow\_additional\_properties

    Define if the schema accepts additional keys in given payload.

    **Default**: 0

- overwrite\_schema\_property\_keys

    HashRef representing mapping between old property name and new property name to overwrite existing schema keys,
    Properties from old key will be assigned to the new property.

    **Note** The key conversion is executed last, every other option e.g. `exclude_properties` will work only on original
    database column names.

- overwrite\_schema\_properties

    HashRef of property name and new attributes which can be either overwritten or merged based on given **\_action** key.

- exclude\_required

    ArrayRef of database column names which should always be EXCLUDED from REQUIRED schema properties.

- include\_required

    ArrayRef of database column names which should always be INCLUDED in REQUIRED schema properties

- exclude\_properties

    ArrayRef of database column names which should be excluded from JSON schema AT ALL

- schema\_overwrite

    HashRef of top level schema properties e.g. 'required', 'properties' etc. to overwrite

# SEE ALSO

[DBIx::Class::ResultSource](https://metacpan.org/pod/DBIx::Class::ResultSource) - Result source object

# AUTHOR

malishew - `malishew@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

    https://github.com/Humanstate/p5-dbix-result-convert-jsonschema
