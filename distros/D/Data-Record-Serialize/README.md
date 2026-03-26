# NAME

Data::Record::Serialize - Flexible serialization of a record

# VERSION

version 2.03

# SYNOPSIS

    use Data::Record::Serialize;

    # simple output to json
    $s = Data::Record::Serialize->new( encode => 'json', \%attr );
    $s->send( \%record );

    # cleanup record before sending
    $s = Data::Record::Serialize->new( encode => 'json',
        fields => [ qw( obsid chip_id phi theta ) ],
        format => 1,
        format_types => { N => '%0.4f' },
        format_fields => { obsid => '%05d' },
        rename_fields => { chip_id => 'CHIP' },
        types => { obsid => 'I', chip_id => 'S',
                   phi => 'N', theta => 'N' },
    );
    $s->send( \%record );


    # send to an SQLite database
    $s = Data::Record::Serialize->new(
        encode => 'dbi',
        dsn => [ 'SQLite', [ dbname => $dbname ] ],
        table => 'stuff',
        format => 1,
        fields => [ qw( obsid chip_id phi theta ) ],
        format_types => { N => '%0.4f' },
        format_fields => { obsid => '%05d' },
        rename_fields => { chip_id => 'CHIP' },
        types => { obsid => 'I', chip_id => 'S',
                   phi => 'N', theta => 'N' },
    );
    $s->send( \%record );

# DESCRIPTION

**Data::Record::Serialize** encodes data records and sends them
somewhere. This module is primarily useful for output of sets of
uniformly structured data records.  It provides a uniform, thin,
interface to various serializers and output sinks.  Its _raison
d'etre_ is its ability to manipulate the records prior to encoding
and output.

- A record is a collection of fields, i.e. keys and _scalar_
values.
- All records are assumed to have the same structure.
- Fields may have simple types.
- Fields may be renamed upon output.
- A subset of the fields may be selected for output.
- Field values may be transformed prior to output.

## Types

Some output encoders care about the type of a
field. **Data::Record::Serialize** recognizes these types:

- `N` - Number (any number)
- `I` - Integer
- `S` - String
- `B` - Boolean

Not all encoders support separate integer or Boolean types. Where not supported,
integers are encoded as numbers and Booleans as integers.

Types may be specified for fields, or may be automatically determined
from the first record which is output.  It is not possible to
deterministically determine if a field is Boolean, so such fields
must be explicitly specified.  Boolean fields should be "truthy",
e.g., when used in a conditional, they evaluate to true or false.

## Field transformation

Transformations can be applied to fields prior to output, and may be
specified globally for data types as well as for specifically for
fields. The latter take precedence.

Transformations are specified via the ["format\_fields"](#format_fields) and
["format\_types"](#format_types) parameters.  They can either be a `sprintf`
compatible format string,

       format_types => { N => '%0.4f' },
       format_fields => { obsid => '%05d' },

    or a code reference:

       format_types => { B => sub { Lingua::Boolean::Tiny::boolean( $_[0] ) } }

## Encoders

The available encoders and their respective documentation are:

- `dbi` - [Data::Record::Serialize::Encode::dbi](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AEncode%3A%3Adbi)

    Write to a database via **DBI**. This is a combined
    encoder and sink.

- `ddump` - [Data::Record::Serialize::Encode::ddump](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AEncode%3A%3Addump)

    encode via [Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)

- `json` - [Data::Record::Serialize::Encode::json](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AEncode%3A%3Ajson)
- `null` - [Data::Record::Serialize::Sink::null](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ASink%3A%3Anull)

    This is a combined encoder and sink.

- `rdb`  - [Data::Record::Serialize::Encode::rdb](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AEncode%3A%3Ardb)
- `yaml` - [Data::Record::Serialize::Encode::yaml](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AEncode%3A%3Ayaml)

## Sinks

Sinks are where encoded data are sent.

The available sinks and their documentation are:

- `stream` - [Data::Record::Serialize::Sink::stream](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ASink%3A%3Astream)

    write to a stream

- `null` - [Data::Record::Serialize::Sink::null](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ASink%3A%3Anull)

    send the encoded data to the bit bucket.

- `array` - [Data::Record::Serialize::Sink::array](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ASink%3A%3Aarray)

    append the encoded data to an array.

Refer to the documentation for additional constructor options, and
object and class methods and attributes;

## Fields and their types

Which fields are output and how their types are determined depends
upon the ["fields"](#fields), ["types"](#types), and ["default\_type"](#default_type) attributes.

This seems a bit complicated, but the idea is to provide a DWIM
interface requiring minimal specification.

In the following table:

    N   => not specified
    Y   => specified
    X   => doesn't matter
    all => the string 'all'

Automatic type determination is done by examining the first
record sent to the output stream.

Automatic output field determination is done by examining the first
record sent to the output stream. Only those fields will be
output for subsequent records.

    fields types default_type  Result
    ------ ----- ------------  ------

    N/all   N        N         Output fields are automatically determined.
                               Types are automatically determined.

    N/all   N        Y         Output fields are automatically determined.
                               Types are set to <default_type>.

      Y     N        N         Fields in <fields> are output.
                               Types are automatically determined.

      Y     Y        N         Fields in <fields> are output.
                               Fields in <types> get the specified type.
                               Types for other fields are automatically determined.

      Y     Y        Y         Fields in <fields> are output.
                               Fields in <types> get the specified type.
                               Types for other fields are set to <default_type>.

     all    Y        N         Output fields are automatically determined.
                               Fields in <types> get the specified type.
                               Types for other fields are automatically determined.

     all    Y        Y         Output fields are automatically determined.
                               Fields in <types> get the specified type.
                               Types for other fields are set to <default_type>.

      N     Y        X         Fields in <types> are output.
                               Types are specified by <types>.

## Errors

Most errors result in exception objects being thrown, typically in the
[Data::Record::Serialize::Error](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3AError) hierarchy.

# CLASS METHODS

## **new**

    $s = Data::Record::Serialize->new( %args );
    $s = Data::Record::Serialize->new( \%args );

Construct a new object. In addition to any arguments required or provided
by the specified encoders and sinks, the following arguments are recognized:

- `types` => _hashref_|_arrayref_

    This specifies types (`N`, `I`, `S`, `B` ) for fields.

    If an array, the fields will be output in the specified order,
    provided the encoder permits it (see below, however).  For example,

        # use order if possible
        types => [ c => 'N', a => 'N', b => 'N' ]

        # order doesn't matter
        types => { c => 'N', a => 'N', b => 'N' }

    If ["fields"](#fields) is specified, then its order will override that specified
    here.

    To understand how this attribute works in concert with ["fields"](#fields) and
    ["default\_type"](#default_type), please see ["Fields and their types"](#fields-and-their-types).

- `default_type` => `S`|`N`|`I`|`B`

    The default input type for fields whose types were not specified via
    the ["types"](#types).

    To understand how this attribute works in concert with ["fields"](#fields) and
    ["types"](#types), please see ["Fields and their types"](#fields-and-their-types).

- `fields` => _arrayref_|`all`

    The fields to output.  If it is the string `all`,
    all input fields will be output. If it is an arrayref, the
    fields will be output in the specified order, provided the encoder
    permits it.

    To understand how this attribute works in concert with ["types"](#types) and
    ["default\_type"](#default_type), please see ["Fields and their types"](#fields-and-their-types).

- `encode` => _encoder_

    _Required_. The module which will encode the data.

    With no prefix, it is assumed to be in the
    `Data::Record::Serialize::Encode` namespace.  With a prefix of `+`
    it is a fully qualified module name.

    Specific encoders may provide additional, or require specific,
    attributes. See ["Encoders"](#encoders) for more information.

- `sink` => _sink_

    The module which writes the encoded data.

    With no prefix, it is assumed to be in the
    `Data::Record::Serialize::Sink` namespace.  With a prefix of `+`
    it is a fully qualified module name.

    Specific sinks may provide additional, or require specific
    attributes. See ["Sinks"](#sinks) for more information.

    The value is `stream` (corresponding to
    [Data::Record::Serialize::Sink::stream](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ASink%3A%3Astream)), unless the encoder is also
    a sink.

    It is an error to specify a sink if the encoder already acts as one.

- `nullify` => _arrayref_|_coderef_|Boolean

    Fields that should be set to `undef` if they are
    empty. Sinks should encode `undef` as the `null` value.

    **nullify** may be passed:

    - an arrayref of input field names
    - a coderef

        The coderef is called as

            @input_field_names = $code->( $serializer_object )

    - a Boolean

        If true, all field names are added to the list. When false, the list
        is emptied.

    Names are verified against the input fields after the first record is
    sent. A `Data::Record::Serialize::Error::Role::Base::fields` error is thrown
    if non-existent fields are specified.

- `numify` => _arrayref_|_coderef_|Boolean

    Specify fields that should be explicitly transformed into a number. It
    defaults to `false`, unless a particular encoder requires it
    (e.g. `json`).  To avoid unnecessary conversion overhead, set this to
    `false` if you are sure that your data are appropriately numified, or
    if only a few fields need to be transformed and can be done via the
    ["format\_fields"](#format_fields) option.

    **numify** may be passed:

    - an arrayref of input field names
    - a coderef

        The coderef is called as

            @input_field_names = $code->( $serializer_object )

    - a Boolean

        If true, all numeric fields are added to the list. When false, the list
        is emptied.

    Names are verified against the input fields after the first record is
    sent. A `Data::Record::Serialize::Error::Role::Base::fields` error is thrown
    if non-existent fields are specified.

- `stringify` => _arrayref_|_coderef_|Boolean

    Specify fields that should be explicitly transformed into a string. It
    defaults to `false`, unless a particular encoder requires it
    (e.g. `json`).  To avoid unnecessary conversion overhead, set this to
    `false` if you are sure that your data are appropriately stringified, or
    if only a few fields need to be transformed and can be done via the
    ["format\_fields"](#format_fields) option.

    **stringify** may be passed:

    - an arrayref of input field names
    - a coderef

        The coderef is called as

            @input_field_names = $code->( $serializer_object )

    - a Boolean

        If true, all string fields are added to the list. When false, the list
        is emptied.

    Names are verified against the input fields after the first record is
    sent. A `Data::Record::Serialize::Error::Role::Base::fields` error is thrown
    if non-existent fields are specified.

- `format` => _Boolean_

    If true, format the output fields using the formats specified in the
    ["format\_fields"](#format_fields) and/or ["format\_types"](#format_types) options.  The default is true.

- `format_fields` => _hashref_

    Specify transforms specific to fields.  The hash keys are input field names;
    each value is either a `sprintf` style format or a coderef. The
    transformations will be applied prior to encoding the record, but only
    if the ["format"](#format) attribute is also set.  Formats specified here
    override those specified in ["format\_types"](#format_types).

    The coderef will be called with the value to format as its first
    argument, and should return the formatted value.

- `format_types` => _hashref_

    Specify transforms specific to types. The hash keys are field types
    (`N`, `I`, `S`, `B`); each value is either a `sprintf` style format or a coderef.
     The transformations will be applied prior to encoding the record, but
    only if the ["format"](#format) attribute is also set.  Formats specified here
    may be overridden for specific fields using the ["format\_fields"](#format_fields)
    attribute.

    The coderef will be called with the value to format as its first
    argument, and should return the formatted value.

- `rename_fields` => _hashref_

    A hash mapping input to output field names.  By default the input
    field names are used unaltered.

# METHODS

For additional methods, see the following modules

- ["Data::Serialize::Record::Role::Base"](#data-serialize-record-role-base)
- ["Data::Serialize::Record::Role::Default"](#data-serialize-record-role-default)
- ["Data::Serialize::Record::Encode"](#data-serialize-record-encode)
- ["Data::Serialize::Record::Sink"](#data-serialize-record-sink),

## **send**

    $s->send( \%record );

Encode and send the record to the associated sink.

**WARNING**: the passed hash is modified.  If you need the original
contents, pass in a copy.

# ATTRIBUTES

Object attributes are provided by the following modules

- ["Data::Serialize::Record::Role::Base"](#data-serialize-record-role-base)
- ["Data::Serialize::Record::Role::Default"](#data-serialize-record-role-default)
- ["Data::Serialize::Record::Encode"](#data-serialize-record-encode)
- ["Data::Serialize::Record::Sink"](#data-serialize-record-sink),

# EXAMPLES

## Generate a JSON stream to the standard output stream

    $s = Data::Record::Serialize->new( encode => 'json' );

## Only output select fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
     );

## Format numeric fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format => 1,
      format_types => { N => '%0.4f' },
     );

## Override formats for specific fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
     );

## Rename fields

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
      rename_fields => { chip_id => 'CHIP' },
     );

## Specify field types

    $s = Data::Record::Serialize->new(
      encode => 'json',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
      rename_fields => { chip_id => 'CHIP' },
      types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
     );

## Switch to an SQLite database in `$dbname`

    $s = Data::Record::Serialize->new(
      encode => 'dbi',
      dsn => [ 'SQLite', [ dbname => $dbname ] ],
      table => 'stuff',
      fields => [ qw( obsid chip_id phi theta ) ],
      format_types => { N => '%0.4f' },
      format_fields => { obsid => '%05d' },
      rename_fields => { chip_id => 'CHIP' },
      types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
     );

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize](https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize)

## Source

Source is available at

    https://gitlab.com/djerius/data-record-serialize

and may be cloned from

    https://gitlab.com/djerius/data-record-serialize.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Data::Serializer](https://metacpan.org/pod/Data%3A%3ASerializer)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
