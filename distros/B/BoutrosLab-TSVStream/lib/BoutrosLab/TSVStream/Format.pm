package BoutrosLab::TSVStream::Format;

=head1 NAME

    BoutrosLab::TSVStream::Format

=cut

=head1 SYNOPSIS

	This namespace hierarchy contains classes that define a useful
	object that also embeds the ability to create a reader or
	writer.

=head1 DESCRIPTION

Classes in this namespace provide a set of useful attributes, etc. as
any normal class.  But they also consume one of the roles:

	BoutrosLab::TSVStream::IO::Role::Fixed
	BoutrosLab::TSVStream::IO::Role::Dyn

which allows them to create a reader (or writer) object that can read
from (or write to) a stream or file, converting the text of the stream
to (or from) an object of this class.

A class that consumes ...::IO::Role::Fixed deals with streams which
contain only the fixed defined fields for this class (as specified
by the class attribute _class).

A class that consumes ...::IO::Role::Dyn deals with streams which
contain the fixed defined fields for this class (as specified
by the class attribute _class), but on each line the fixed attributes
are followed by a number of dynamic fields.

The stream format is a series of lines.  Each line consists of a
number of fields, separated by a tab character.  The first line is
(usually) a text line that has the field names as the contents of
each field.  (The field names are validated on reading to verify
match the definition of the object.)  The remaining lines of the
stream consist of fields that contain data.  The first fields
contain data for each of the attributes defined by the object (in
the order defined by the object).  This data is validated using
the type specification for those attributes.  For Dyn objects,
remaining fields contain text data for additional contents.
The number and content of these dynamic fields are determined at
run-time - there must be a consistant number of fields throughout
an entire stream, but the validity of the content cannot be
determined automatically (because each stream can have a different
set of dynamic fields, so there is no way for the code to know in
advance how to validate them).

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::Format::AnnovarInput::Human::Fixed

=item BoutrosLab::TSVStream::Format::AnnovarInput::Human::Dyn

=item BoutrosLab::TSVStream::Format::AnnovarInput::HumanNoChr::Fixed

=item BoutrosLab::TSVStream::Format::AnnovarInput::HumanNoChr::Dyn

These modules provide an example of how to write a module
able to read/write TSV stream text.  You can use them as
templates either for adding a new module under this
hierarchy, or for writing your own TSV capable objects that
are not added to this namespace.

They provide objects that use AnnovarInput file format for the text
form, and restrict the chrosome values to ones appropriate
to humans.

=item BoutrosLab::TSVStream::Format::None::Dyn

A class with no fixed fields, but only dynamic fields.
This is useful for dealing with dynamic TSV streams where
you don't know the stream contents, or for fixed field
formats where you don't want to have to create an object
to define the fields - and you are able to simply treat
the field contents as unconstrained text.

There is no point in defining the corresponding
...::None::Fixed module since that would only deal with
objects having no attributes, converting them to/from
streams containing only empty lines.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

