# NAME

Data::Record::Serialize::Encode::table - encode records as a formatted table and output it

# VERSION

version 0.01

# SYNOPSIS

    use Data::Record::Serialize;
    my $s = Data::Record::Serialize->new( encode => 'table', ... );
    $s->send( \%record );

# DESCRIPTION

**Data::Record::Serialize::Encode::table** encodes records into table form
using [Term::Table](https://metacpan.org/pod/Term%3A%3ATable).

It performs both the [Data::Record::Serialize::Role::Encode](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ARole%3A%3AEncode) and
[Data::Record::Serialize::Role::Sink](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize%3A%3ARole%3A%3ASink) roles.

Do not construct this directly; use ["new" in Data::Record::Serialize](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize#new).
The following named parameters may be passed to it:

- output

    This parameter is required. One of the following:

    - The name of an output file (which will be created).  If it is the
    string `-`, output will be written to the standard output stream.
    Must not be the empty string.
    - a reference to a scalar to which the records will be written.
    - a GLOB (i.e. `\*STDOUT`), or a reference to an object which derives
    from [IO::Handle](https://metacpan.org/pod/IO%3A%3AHandle) (e.g. [IO::File](https://metacpan.org/pod/IO%3A%3AFile), [FileHandle](https://metacpan.org/pod/FileHandle), etc.).  These
    will _not_ be closed upon destruction of the serializer or when the
    ["close"](#close) method is called.

- create\_output\_dir => _Boolean_

    If _true_, the directory which will contain the output file is created.
    Defaults to _false_.

The following parameters are passed as-is to ["new" in Term::Table](https://metacpan.org/pod/Term%3A%3ATable#new).

- allow\_overflow
- auto\_columns
- collapse
- mark\_tail
- max\_width
- no\_collapse
- pad
- sanitize
- show\_header

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-data-record-serialize-encode-table@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-table](https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize-Encode-table)

## Source

Source is available at

    https://codeberg.com/djerius/data-record-serialize-encode-table

and may be cloned from

    https://codeberg.com/djerius/data-record-serialize-encode-table.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [Data::Record::Serialize](https://metacpan.org/pod/Data%3A%3ARecord%3A%3ASerialize)
- [Term::Table](https://metacpan.org/pod/Term%3A%3ATable)

# AUTHOR

Diab Jerius <djerius@cfa.harvard.edu>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
