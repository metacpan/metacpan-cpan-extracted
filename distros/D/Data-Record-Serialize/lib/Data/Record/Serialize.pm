package Data::Record::Serialize;

# ABSTRACT: Flexible serialization of a record

use 5.010000;

use strict;
use warnings;
use Carp;

our $VERSION = '0.12';

use Package::Variant
  importing => ['Moo'],
  subs      => [qw( with has )];

use namespace::clean;

#pod =begin pod_coverage
#pod
#pod =head3 make_variant
#pod
#pod =end pod_coverage
#pod
#pod =cut

sub make_variant {
    my ( $class, $target, %attr ) = @_;

    croak( "must specify 'encode' attribute\n" )
      unless defined $attr{encode};

    with 'Data::Record::Serialize::Role::Base';

    my $encoder = 'Data::Record::Serialize::Encode::' . lc $attr{encode};

    with $encoder;

    if ( $target->does( 'Data::Record::Serialize::Role::Sink' ) ) {

        croak(
            "encoder ($attr{encode}) is already a sink; don't specify a sink attribute\n"
        ) if defined $attr{sink};
    }

    else {

	# default sink
        my $sink = 'Data::Record::Serialize::Sink::'
          . ( $attr{sink} ? lc $attr{sink} : 'stream' );

        with $sink;
    }

    with 'Data::Record::Serialize::Role::Default';
}


sub new {

    my $class = shift;
    my $attr = 'HASH' eq ref $_[0] ? shift : {@_};

    my %class_attr = (
        encode => $attr->{encode},
        sink   => $attr->{sink},
    );

    $class = Package::Variant->build_variant_of( __PACKAGE__, %class_attr );

    return $class->new( $attr );
}

1;


#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

Data::Record::Serialize - Flexible serialization of a record

=head1 VERSION

version 0.12

=head1 SYNOPSIS

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

=head1 DESCRIPTION

B<Data::Record::Serialize> encodes data records and sends them
somewhere. This module is primarily useful for output of sets of
uniformly structured data records.  It provides a uniform, thin,
interface to various serializers and output sinks.  Its I<raison
d'etre> is its ability to manipulate the records prior to encoding
and output.

=over

=item *

A record is a collection of fields, i.e. keys and I<scalar>
values.

=item *

All records are assumed to have the same structure.

=item *

Fields may have simple types which may be determined automatically.
Some encoders use this information during encoding.

=item *

Fields may be renamed upon output

=item *

A subset of the fields may be selected for output.

=item *

Fields may be formatted via C<sprintf> prior to output

=back

=head2 Encoders

The available encoders and their respective documentation are:

=over

=item *

C<dbi> - L<B<Data::Record::Serialize::Encode::dbi>>

Write to a database via B<DBI>. This is a combined
encoder and sink.

=item *

C<ddump> - L<B<Data::Record::Serialize::Encode::ddump>>

encode via L<B<Data::Dumper>>

=item *

C<json> - L<B<Data::Record::Serialize::Encode::json>>

=item *

C<null> - send the data to the bit bucket.  This is a combined
encoder and sink.

=item *

C<rdb>  - L<B<Data::Record::Serialize::Encode::rdb>>

=item *

C<yaml> - L<B<Data::Record::Serialize::Encode::yaml>>

=back

=head2 Sinks

Sinks are where encoded data are sent.

The available sinks and their documentation are:

=over

=item *

C<stream> - L<B<Data::Record::Serialize::Sink::stream>>

=item *

C<null> - send the encoded data to the bit bucket.

=back

=head2 Types

Some output encoders care about the type of a
field. B<Data::Record::Serialize> recognizes three types:

=over

=item *

C<N> - Numeric

=item *

C<I> - Integral

=item *

C<S> - String

=back

Not all encoders support a separate integral type; in those cases
integer fields are treated as general numeric fields.

=head2 Output field and type determination

The selection of output fields and determination of their types
depends upon the C<fields>, C<types>, and C<default_type> attributes.

=over

=item *

C<fields> specified, C<types> I<not> specified

The fields in C<fields> are output. Types are derived from the values
in the first record.

=item *

C<fields> I<not> specified, C<types> specified

The fields by C<types> are output and are given the specified types.

=item *

C<fields> specified, C<types> specified

The fields specified by the C<fields> array are output with the types
specified by C<types>.  For fields not specified in C<types>, the
C<default_type> attribute value is used.

=item *

C<fields> I<not> specified, C<types> I<not> specified

The first record determines the fields and types (by examination).

=back

=begin pod_coverage

=head3 make_variant

=end pod_coverage

=head1 INTERFACE

=head2 B<new>

  $s = Data::Record::Serialize->new( <attributes> );

Construct a new object. I<attributes> may either be a hashref or a
list of key-value pairs.

The available attributes are:

=over

=item C<encode>

I<Required>. The encoding format.  Specific encoders may provide
additional, or require specific, attributes. See L</Encoders>
for more information.

=item C<sink>

Where the encoded data will be sent.  Specific sinks may provide
additional, or require specific attributes. See L</Sinks> for more
information.

The default output sink is C<stream>, unless the encoder is also a
sink.

It is an error to specify a sink if the encoder already acts as one.

=item C<default_type>=I<type>

If the C<types> attribute was specified, this type is assigned to
fields given in the C<fields> attributes which were not specified via
the C<types> attribute.

=item C<types>

A hash or array mapping input field names to types (C<N>, C<I>,
C<S>).  If an array, the fields will be output in the specified
order, provided the encoder permits it (see below, however).  For example,

  # use order if possible
  types => [ c => 'N', a => 'N', b => 'N' ]

  # order doesn't matter
  types => { c => 'N', a => 'N', b => 'N' }

If C<fields> is specified, then its order will override that specified
here.  If no type is specified for elements in C<fields>, they will
default to having the type specified by the C<default_type> attribute.
For example,

  types => [ c => 'N', a => 'N' ],
  fields => [ qw( a b c ) ],
  default_type => 'I',

will result in fields being output in the order

   a b c

with types

   a => 'N',
   b => 'I',
   c => 'N',

=item C<fields>

An array containing the input names of the fields to be output. The
fields will be output in the specified order, provided the encoder
permits it.

If this attribute is not specified, the fields specified by the
C<types> attribute will be output.  If that is not specified, the
fields as found in the first data record will be output.

If a field name is specifed in C<fields> but no type is defined in
C<types>, it defaults to what is specified via C<default_type>.

=item C<rename_fields>

A hash mapping input to output field names.  By default the input
field names are used unaltered.

=item C<format_fields>

A hash mapping the input field names to a C<sprintf> style
format. This will be applied prior to encoding the record, but only if
the C<format> attribute is also set.  Formats specified here override
those specified in C<format_types>.

=item C<format_types>

A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
format.  This will be applied prior to encoding the record, but only
if the C<format> attribute is also set.  Formats specified here may be
overriden for specific fields using the C<format_fields> attribute.

=item C<format>

If true, format the output fields using the formats specified in the
C<format_fields> and/or C<format_types> options.  The default is false.

=back

=head2 B<send>

  $s->send( \%record );

Encode and send the record to the associated sink.

B<WARNING>: the passed hash is modified.  If you need the original
contents, pass in a copy.

=head2 B<close>

  $s->close;

Flush any data written to the sink and close it.  While this will be
performed automatically when the object is destroyed, if the object is
not destroyed prior to global destruction at the end of the program,
it is quite possible that it will not be possible to perform this
cleanly.  In other words, make sure that sinks are closed prior to
global destruction.

=head2 B<output_fields>

  $array_ref = $s->fields;

The names of the transformed output fields, in order of output (not
obeyed by all encoders);

=head2 B<output_types>

  $hash_ref = $s->output_types;

The mapping between output field name and output field type.  If the
encoder has specified a type map, the output types are the result of
that mapping.

=head2 B<numeric_fields>

  $array_ref = $s->numeric_fields;

The input field names for those fields deemed to be numeric.

=head1 EXAMPLES

=head2 Generate a JSON stream to the standard output stream

  $s = Data::Record::Serialize->new( encode => 'json' );

=head2 Only output select fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
   );

=head2 Format numeric fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format => 1,
    format_types => { N => '%0.4f' },
   );

=head2 Override formats for specific fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
   );

=head2 Rename fields

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
    rename_fields => { chip_id => 'CHIP' },
   );

=head2 Specify field types

  $s = Data::Record::Serialize->new(
    encode => 'json',
    fields => [ qw( obsid chip_id phi theta ) ],
    format_types => { N => '%0.4f' },
    format_fields => { obsid => '%05d' },
    rename_fields => { chip_id => 'CHIP' },
    types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
   );

=head2 Switch to an SQLite database in C<$dbname>

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

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Other modules:|Other modules:>

=item *

L<B<Data::Serializer>>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod     use Data::Record::Serialize;
#pod
#pod     # simple output to json
#pod     $s = Data::Record::Serialize->new( encode => 'json', \%attr );
#pod     $s->send( \%record );
#pod
#pod     # cleanup record before sending
#pod     $s = Data::Record::Serialize->new( encode => 'json',
#pod 	fields => [ qw( obsid chip_id phi theta ) ],
#pod         format => 1,
#pod 	format_types => { N => '%0.4f' },
#pod 	format_fields => { obsid => '%05d' },
#pod 	rename_fields => { chip_id => 'CHIP' },
#pod 	types => { obsid => 'I', chip_id => 'S',
#pod                    phi => 'N', theta => 'N' },
#pod     );
#pod     $s->send( \%record );
#pod
#pod
#pod     # send to an SQLite database
#pod     $s = Data::Record::Serialize->new(
#pod 	encode => 'dbi',
#pod 	dsn => [ 'SQLite', [ dbname => $dbname ] ],
#pod 	table => 'stuff',
#pod         format => 1,
#pod 	fields => [ qw( obsid chip_id phi theta ) ],
#pod 	format_types => { N => '%0.4f' },
#pod 	format_fields => { obsid => '%05d' },
#pod 	rename_fields => { chip_id => 'CHIP' },
#pod 	types => { obsid => 'I', chip_id => 'S',
#pod                    phi => 'N', theta => 'N' },
#pod     );
#pod     $s->send( \%record );
#pod
#pod =head1 DESCRIPTION
#pod
#pod B<Data::Record::Serialize> encodes data records and sends them
#pod somewhere. This module is primarily useful for output of sets of
#pod uniformly structured data records.  It provides a uniform, thin,
#pod interface to various serializers and output sinks.  Its I<raison
#pod d'etre> is its ability to manipulate the records prior to encoding
#pod and output.
#pod
#pod =over
#pod
#pod =item *
#pod
#pod A record is a collection of fields, i.e. keys and I<scalar>
#pod values.
#pod
#pod =item *
#pod
#pod All records are assumed to have the same structure.
#pod
#pod =item *
#pod
#pod Fields may have simple types which may be determined automatically.
#pod Some encoders use this information during encoding.
#pod
#pod =item *
#pod
#pod Fields may be renamed upon output
#pod
#pod =item *
#pod
#pod A subset of the fields may be selected for output.
#pod
#pod =item *
#pod
#pod Fields may be formatted via C<sprintf> prior to output
#pod
#pod =back
#pod
#pod =head2 Encoders
#pod
#pod The available encoders and their respective documentation are:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<dbi> - L<B<Data::Record::Serialize::Encode::dbi>>
#pod
#pod Write to a database via B<DBI>. This is a combined
#pod encoder and sink.
#pod
#pod =item *
#pod
#pod C<ddump> - L<B<Data::Record::Serialize::Encode::ddump>>
#pod
#pod encode via L<B<Data::Dumper>>
#pod
#pod =item *
#pod
#pod C<json> - L<B<Data::Record::Serialize::Encode::json>>
#pod
#pod =item *
#pod
#pod C<null> - send the data to the bit bucket.  This is a combined
#pod encoder and sink.
#pod
#pod =item *
#pod
#pod C<rdb>  - L<B<Data::Record::Serialize::Encode::rdb>>
#pod
#pod =item *
#pod
#pod C<yaml> - L<B<Data::Record::Serialize::Encode::yaml>>
#pod
#pod =back
#pod
#pod
#pod =head2 Sinks
#pod
#pod Sinks are where encoded data are sent.
#pod
#pod The available sinks and their documentation are:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<stream> - L<B<Data::Record::Serialize::Sink::stream>>
#pod
#pod =item *
#pod
#pod C<null> - send the encoded data to the bit bucket.
#pod
#pod =back
#pod
#pod
#pod =head2 Types
#pod
#pod Some output encoders care about the type of a
#pod field. B<Data::Record::Serialize> recognizes three types:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<N> - Numeric
#pod
#pod =item *
#pod
#pod C<I> - Integral
#pod
#pod =item *
#pod
#pod C<S> - String
#pod
#pod =back
#pod
#pod Not all encoders support a separate integral type; in those cases
#pod integer fields are treated as general numeric fields.
#pod
#pod =head2 Output field and type determination
#pod
#pod The selection of output fields and determination of their types
#pod depends upon the C<fields>, C<types>, and C<default_type> attributes.
#pod
#pod =over
#pod
#pod =item *
#pod
#pod C<fields> specified, C<types> I<not> specified
#pod
#pod The fields in C<fields> are output. Types are derived from the values
#pod in the first record.
#pod
#pod =item *
#pod
#pod C<fields> I<not> specified, C<types> specified
#pod
#pod The fields by C<types> are output and are given the specified types.
#pod
#pod =item *
#pod
#pod C<fields> specified, C<types> specified
#pod
#pod The fields specified by the C<fields> array are output with the types
#pod specified by C<types>.  For fields not specified in C<types>, the
#pod C<default_type> attribute value is used.
#pod
#pod =item *
#pod
#pod C<fields> I<not> specified, C<types> I<not> specified
#pod
#pod The first record determines the fields and types (by examination).
#pod
#pod
#pod =back
#pod
#pod
#pod =head1 INTERFACE
#pod
#pod =head2 B<new>
#pod
#pod   $s = Data::Record::Serialize->new( <attributes> );
#pod
#pod Construct a new object. I<attributes> may either be a hashref or a
#pod list of key-value pairs.
#pod
#pod The available attributes are:
#pod
#pod =over
#pod
#pod =item C<encode>
#pod
#pod I<Required>. The encoding format.  Specific encoders may provide
#pod additional, or require specific, attributes. See L</Encoders>
#pod for more information.
#pod
#pod =item C<sink>
#pod
#pod Where the encoded data will be sent.  Specific sinks may provide
#pod additional, or require specific attributes. See L</Sinks> for more
#pod information.
#pod
#pod The default output sink is C<stream>, unless the encoder is also a
#pod sink.
#pod
#pod It is an error to specify a sink if the encoder already acts as one.
#pod
#pod =item C<default_type>=I<type>
#pod
#pod If the C<types> attribute was specified, this type is assigned to
#pod fields given in the C<fields> attributes which were not specified via
#pod the C<types> attribute.
#pod
#pod =item C<types>
#pod
#pod A hash or array mapping input field names to types (C<N>, C<I>,
#pod C<S>).  If an array, the fields will be output in the specified
#pod order, provided the encoder permits it (see below, however).  For example,
#pod
#pod   # use order if possible
#pod   types => [ c => 'N', a => 'N', b => 'N' ]
#pod
#pod   # order doesn't matter
#pod   types => { c => 'N', a => 'N', b => 'N' }
#pod
#pod If C<fields> is specified, then its order will override that specified
#pod here.  If no type is specified for elements in C<fields>, they will
#pod default to having the type specified by the C<default_type> attribute.
#pod For example,
#pod
#pod   types => [ c => 'N', a => 'N' ],
#pod   fields => [ qw( a b c ) ],
#pod   default_type => 'I',
#pod
#pod will result in fields being output in the order
#pod
#pod    a b c
#pod
#pod with types
#pod
#pod    a => 'N',
#pod    b => 'I',
#pod    c => 'N',
#pod
#pod =item C<fields>
#pod
#pod An array containing the input names of the fields to be output. The
#pod fields will be output in the specified order, provided the encoder
#pod permits it.
#pod
#pod If this attribute is not specified, the fields specified by the
#pod C<types> attribute will be output.  If that is not specified, the
#pod fields as found in the first data record will be output.
#pod
#pod If a field name is specifed in C<fields> but no type is defined in
#pod C<types>, it defaults to what is specified via C<default_type>.
#pod
#pod =item C<rename_fields>
#pod
#pod A hash mapping input to output field names.  By default the input
#pod field names are used unaltered.
#pod
#pod =item C<format_fields>
#pod
#pod A hash mapping the input field names to a C<sprintf> style
#pod format. This will be applied prior to encoding the record, but only if
#pod the C<format> attribute is also set.  Formats specified here override
#pod those specified in C<format_types>.
#pod
#pod =item C<format_types>
#pod
#pod A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
#pod format.  This will be applied prior to encoding the record, but only
#pod if the C<format> attribute is also set.  Formats specified here may be
#pod overriden for specific fields using the C<format_fields> attribute.
#pod
#pod =item C<format>
#pod
#pod If true, format the output fields using the formats specified in the
#pod C<format_fields> and/or C<format_types> options.  The default is false.
#pod
#pod =back
#pod
#pod =head2 B<send>
#pod
#pod   $s->send( \%record );
#pod
#pod Encode and send the record to the associated sink.
#pod
#pod B<WARNING>: the passed hash is modified.  If you need the original
#pod contents, pass in a copy.
#pod
#pod
#pod =head2 B<close>
#pod
#pod   $s->close;
#pod
#pod Flush any data written to the sink and close it.  While this will be
#pod performed automatically when the object is destroyed, if the object is
#pod not destroyed prior to global destruction at the end of the program,
#pod it is quite possible that it will not be possible to perform this
#pod cleanly.  In other words, make sure that sinks are closed prior to
#pod global destruction.
#pod
#pod =head2 B<output_fields>
#pod
#pod   $array_ref = $s->fields;
#pod
#pod The names of the transformed output fields, in order of output (not
#pod obeyed by all encoders);
#pod
#pod =head2 B<output_types>
#pod
#pod   $hash_ref = $s->output_types;
#pod
#pod The mapping between output field name and output field type.  If the
#pod encoder has specified a type map, the output types are the result of
#pod that mapping.
#pod
#pod =head2 B<numeric_fields>
#pod
#pod   $array_ref = $s->numeric_fields;
#pod
#pod The input field names for those fields deemed to be numeric.
#pod
#pod =head1 EXAMPLES
#pod
#pod =head2 Generate a JSON stream to the standard output stream
#pod
#pod   $s = Data::Record::Serialize->new( encode => 'json' );
#pod
#pod =head2 Only output select fields
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'json',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod    );
#pod
#pod =head2 Format numeric fields
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'json',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod     format => 1,
#pod     format_types => { N => '%0.4f' },
#pod    );
#pod
#pod =head2 Override formats for specific fields
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'json',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod     format_types => { N => '%0.4f' },
#pod     format_fields => { obsid => '%05d' },
#pod    );
#pod
#pod =head2 Rename fields
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'json',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod     format_types => { N => '%0.4f' },
#pod     format_fields => { obsid => '%05d' },
#pod     rename_fields => { chip_id => 'CHIP' },
#pod    );
#pod
#pod =head2 Specify field types
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'json',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod     format_types => { N => '%0.4f' },
#pod     format_fields => { obsid => '%05d' },
#pod     rename_fields => { chip_id => 'CHIP' },
#pod     types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
#pod    );
#pod
#pod =head2 Switch to an SQLite database in C<$dbname>
#pod
#pod   $s = Data::Record::Serialize->new(
#pod     encode => 'dbi',
#pod     dsn => [ 'SQLite', [ dbname => $dbname ] ],
#pod     table => 'stuff',
#pod     fields => [ qw( obsid chip_id phi theta ) ],
#pod     format_types => { N => '%0.4f' },
#pod     format_fields => { obsid => '%05d' },
#pod     rename_fields => { chip_id => 'CHIP' },
#pod     types => { obsid => 'N', chip_id => 'S', phi => 'N', theta => 'N' }'
#pod    );
#pod
#pod
#pod
#pod =head1 SEE ALSO
#pod
#pod Other modules:
#pod
#pod L<B<Data::Serializer>>
#pod
#pod
#pod
#pod
