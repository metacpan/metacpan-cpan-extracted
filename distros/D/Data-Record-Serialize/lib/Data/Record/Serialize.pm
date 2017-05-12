# --8<--8<--8<--8<--
#
# Copyright (C) 2014 Smithsonian Astrophysical Observatory
#
# This file is part of Data::Record::Serialize
#
# Data::Record::Serialize is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Data::Record::Serialize;

use strict;
use warnings;
use Carp;

our $VERSION = '0.07';

use Package::Variant
  importing => ['Moo'],
  subs      => [qw( with has )];

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


1;

__END__

=head1 NAME

Data::Record::Serialize - Flexible serialization of a record


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

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-record-serialize@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

Other modules:

L<B<Data::Serializer>>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 The Smithsonian Astrophysical Observatory

B<Data::Record::Serialize> is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


