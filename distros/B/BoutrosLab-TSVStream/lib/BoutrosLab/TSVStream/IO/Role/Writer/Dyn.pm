package BoutrosLab::TSVStream::IO::Role::Writer::Dyn;

# safe Perl
use warnings;
use strict;
use Carp;

use BoutrosLab::TSVStream::IO::Role::Writer::Fixed;

=head1 NAME

    BoutrosLab::TSVStream:Writer

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::IO::Role::Writer::Fixed' => { -excludes => '_list_headers' };

sub _list_headers {
	my $self = shift;
	return ( [ @{ $self->fields }, @{ $self->dyn_fields } ] );
	}

=head1 SYNOPSIS

	$class->writer( ... );

	# ($class will use the role BoutrosLab::TSVStream which will provide
	# the writer method, that method will return a Writer object with:
	# ...
	# return BoutrosLab::TSVStream::Writer->new(
		# handle => $fd,	# (required)
		# class  => $class,	# (required) class
		# file   => $file,	# (optional) used (as filename) in error messages
		# header => $str,	# (optional) one of: write skip (default 'write' unless append)
		# append => 1,      # (optional) if true:
		#                   #    file is opened for append (if stream not provided)
		#                   #    header defaults to 'skip'
		# );

	while (my $record = $writer->read) {
		# ... $record is a $class object
		# ... use $record->field1, $record->field2, etc. - all of the methods of $class object
		}

=head1 DESCRIPTION

This object provides an iterator to read through the lines
of a data stream (C<$fd>), converting each from a line with
tab separated fields into an object of a class (C<$classs>)
that has attributes for those fields.

Usually, the data stream will start with a line that has the
fieldnames in a tab separated list, and the rest of the stream
has lines that contain the field values in a tab separated list.

Any error diagnostics will refer to the stream using the
C<$file> filename if it is provided.

The C<$class> class will have a class method named C<_fields>
that provides a ref to array of string listing the fields to
.be written and their order.

A class C<$class> object must be provided for each line.
The object will be re-formatted into tab separated format
and written out.

If C<header> is provided, it can be 'write', or 'skip'.
This controls what is done to the handle initially.

If 'write' is specified, a header line is written to the stream
containing the field names in tab separated format before writing
any explicitly provided objects.  This is the default.  If 'skip'
is specified, no header is written.

If 'skip' is specified, the stream is not checked for a header
line.  (You would use this option either if the file does not
have a header line, or if you are scanning from the middle of
a file handle that is no longer at the start of the file.)

=head1 ATTRIBUTES

=head2 handle - the filehandle to be read

=head2 file - the name of the stream, usually a filename, for diagnostic purposes

=head2 class - the class that records transformed into

=head2 fields - list of field names, usually provided by class

handle, file, class and fields are provided by the ...::IO::Role::Base::Fixed role

=head2 append - (optional) boolean to cause writes to append to the stream, causes header to default to 'skip'

=head2 header - 'write', or 'skip' (default 'write' normally, 'skip' if 'append' is enabled)

The C<'write'> setting causes the first line of the stream to be written
with a list of field names.  This is the default unless the append option
is set.

If the C<'skip'> setting is provided, the stream writing will start with
a data value.  Use this either for writing a stream that is not supposed
to have a header line, or else to append additional values to an existing
file (of the same type of course).  This must normally be asked for
explicitly, but it is the default if the append option is set.

=head1 BUILDARGS

The BUILDARGS method opens a handle if only a file is provided.

=head1 BUILD

The BUILD method handles any requirements for reading and processing a
header line.

=head1 METHODS

=head2 write - read a line to the stream from a class element

#####

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

