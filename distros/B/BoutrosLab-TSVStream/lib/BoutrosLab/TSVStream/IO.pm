package BoutrosLab::TSVStream::IO;

=head1 NAME

    BoutrosLab::TSVStream::IO

=head1 SYNOPSIS

This namespace hierarchy contains roles that allow an object
the ability to create a reader (or writer) object that can load
(or store) instances of the consuming object class from (or to)
a file or stream.

    package MyObject;

	use Moose;
	use MooseX::ClassAttribute;

	# the definition of _fields must precede the 'with' statement
	class_has '_fields' => (
		is => 'ro',
		isa => 'ArrayRef',
		default => sub { [qw(my_field1 my_field2)] }
	);

	# one of:
	with 'BoutrosLab::TSVStream::IO::Role::Fixed';

	# or:
	with 'BoutrosLab::TSVStream::IO::Role::Dyn';

	has my_field1 => ( isa => 'Int', ... );
	has my_field2 => ( isa => 'Str', ... );

	package UserCode;

	use MyObject;

	my $reader = MyObject->reader( file => 'lib/myfobjectfile' );
	my $writer = MyObject->writer( file => 'lib/myfobjectfile.over10' );
	while (my $obj = $reader->read) {
		# $obj is a MyObject
		$writer->write($obj) if $obj->my_field1 > 10;
	}


=head1 DESCRIPTION

Consuming classes can acquire the ability to generate reader and
writer objects by consuming one of the Roles:

=over

=item BoutrosLab::TSVStream::IO::Role::Fixed

=item BoutrosLab::TSVStream::IO::Role::Dyn

=back

Consuming classes must provide a set of useful attributes, etc. as
any normal class.  But they also consume one of the roles:

A class that consumes ...::IO::Role::Fixed deals with streams which
contain only the fixed defined fields for this class (as specified
by the class attribute _class).

A class that consumes ...::IO::Role::Dyn deals with streams which
contain the fixed defined fields for this class (as specified
by the class attribute _class), but on each line the fixed attributes
are followed by a number of dynamic fields.

The stream format is a series of lines.

=over

=item .

Each line consists of a number of fields, separated by a tab
character.

=item .

If comments are enabled, then lines with the first non-space
character being a comment symbol (#) will be discarded on input
and not returned by a reader.

=item .

All non-comment lines must contain the same number of fields.

=item .

The first line is (usually) a header line that has the field names
as the text contents of each field.  (The field names are validated
on reading to verify match the definition of the object.  The header
line is not returned by the reader as an object.)  A writer will
write out a header line unless it was configured not to.

=item .

The remaining lines of the stream consist of fields that contain
data.

=item .

The first fields contain data for each of the attributes defined
by the object (in the order defined by the object).  Each field is
validated using the type specification for those attributes.

=item .

For IO::Role::Fixed consuming objects, that must be all of the
fields in the stream.

=item .

For IO::Role::Dyn objects, remaining fields contain text data for
additional contents.  The number and content of these dynamic fields
are determined at run-time - there must be a consistant number of
fields throughout an entire stream, but the validity of the content
cannot be determined automatically (because each stream can have a
different set of dynamic fields, so there is no way for the code to
know in advance how to validate them).  When reading, if the reader
definition did not provide field names for the dynamic fields and if
header processing is enabled, then the field names for the dynamic
fields will be determined from the input.

=back

=head1 Requirements for Comsuning class

The consuming class must satify a number of requirements.

=over

=item .

class_attribute B<_fields>: must provide a ref to an array of strings
that specify the fixed field names.

=item .

attribute I<FIELD>: each field listed in the _fields class attribute
must be defined as an attribute of the consuming object.

=back

=head1 Methods Provided to the Consuming class (by either Fixed or Dyn)

=head2 B<reader>

The reader method returns an object that reads a stream
and produces objects of the consuming class.  See
BoutrosLab::TSVStream::IO::Reader for details.

=head2 B<writer>

The writer method returns an object that writes a stream,
from objects of the consuming class (or equivalent values).
See BoutrosLab::TSVStream::IO::Writer for details.

=head1 Attributes Provided to the Consuming class (only by Dyn)

=head2 B<dyn_fields>

the names of the dynamic fields.  If they are not provided by
the calling code, or by a header (in an input stream), they
are set to 'extra1', 'extra2', ...

=head2 B<dyn_values>

the values of the dynamic fields (in the same order as dyn_field,
and as in a stream).

=head2 B<extra_class_params>

List of string values to be passed to the B<new> method for the
target object.  This can be of value to specific target objects.

The only such attribute defined by this package is
B<install_methods>, which is a Boolean attribute that can be provided
to a B<Dyn> B<reader> to cause all new objects created by that
reader to be provided with accessor methods for the dynamic fields.
Generally, this is not needed:

=over

=item . the whole point of dynamic
fields is that the code doesn't know what the fields will be called

=item . it is potentially dangerous since if a dynamic field has
the same name as a fixed field or as another dynamic field there
would be an attempt to create multiple methods with the same name -
this is treated as an error when the dynamic fields are determined

=item .  it is time-costly both for the cost of installing the
methods for each created object dynamically, and also because the
target class may not use the Moose make_immuable to pre-compile
the object-oriented internal code, since that would prevent adding
these attributes

=back

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO::Reader

=item BoutrosLab::TSVStream::IO::Writer

These are the classes of reader and writer objects that are returned
by this role.  See them for the creation parameters you can provide
to the reader and writer methods described here as well as for the
methods that reader and writer objects provide.

=item BoutrosLab::TSVStream::Format

Describes the hierarchy of provided modules that define a
set of attributes that are useful to move to/from a text
stream.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

