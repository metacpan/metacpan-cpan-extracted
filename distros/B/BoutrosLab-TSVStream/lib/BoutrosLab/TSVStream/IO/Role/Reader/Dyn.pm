package BoutrosLab::TSVStream::IO::Role::Reader::Dyn;

# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream:IO::Role::Reader::Dyn

=cut

use Moose::Role;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::IO::Role::Reader::Fixed';

sub _read_no_header {
	my $self = shift;
	my $none = $self->header eq 'none';
	( $none, ($none && $self->_has_dyn_fields) );
	}

sub _fill_dyn_fields {
	my ($self, $none, $is_head, $stream_fields ) = @_;
    my $num_fixed_fields = $#{ $self->fields };

	if (!$self->_has_dyn_fields) {
		$self->_set_dyn_fields( [
			(!$none && $is_head)
				? @{$stream_fields}[ $num_fixed_fields+1 .. $#$stream_fields ]
				: $self->_extra_names( $#$stream_fields - $num_fixed_fields )
			] );
		}
	}

=head1 SYNOPSIS

	$class->reader( ... );

	# ($class will use the role BoutrosLab::TSVStream which will provide
	# the reader method, that method will return a Reader object with:
	# ...
	# return BoutrosLab::TSVStream::Reader->new(
		# handle => $fd,	# (required)
		# class  => $class,	# (required) class
		# file   => $file,	# (optional) used (as filename) in error messages
		# header => $str,	# (optional) one of: check none (default 'check')
		# );

	while (my $record = $reader->read) {
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

The C<$class> class will have a class attribute named
C<_fields>.  Usually, this will be a read-only method that
returns a list of fieldnames that will be used to validate
the first line in the data stream (which should contain the
field names as the column vlues).

A class C<$class> object will be created for each line.
The object will be initialized with a list of names and values
matching the fields and the contents .of the line.

If C<header> is provided, it can be 'check', or 'none'.
This controls what is done to the handle initially.

If 'check' is specified, the first line of the stream is read
and it is checked to ensure that it matches the C<fields> both
in name and order.  The fields list must be complete.  However,
it is permitted for the field names to mismatch by having
different capitalization - the comparison is not case sensitive.

If 'none' is specified, the stream is not checked for a header
line.  (You would use this option either if the file does not
have a header line, or if you are scanning from the middle of
a file handle that is no longer at the start of the file.)

=cut

=head1 ATTRIBUTES

=head2 handle - the filehandle to be read

=head2 file - the name of the stream, usually a filename, for diagnostic purposes

=head2 class - the class that records transformed into

=head2 fields - list of field names, usually provided by class

handle, file, class and fields are provided by the ...::Base role

=head2 header - 'auto', 'check', or 'none' (default 'auto')

The C<'check'> setting causes the first line of the stream to
be read and validated against the C<fields> list.  The field
names are accepted if they match (but differences in upper/lower
case are ignored).  If they do not match, an exception is thrown.

If the C<'none'> setting is provided, the stream should already be
positioned at a data value (i.e. the stream was previously opened and
is no longer positioned at the start, or else the stream was originally
created without a leading header line).

The default C<'auto'> setting causes the first line to be read and
validated as for the C<'check'> setting, but if the line does not
match the list of fields it is assumed to instead be the first data
line of a stream that has no headers, and processing continues as
if the C<'none'> setting were specified instead.

=head1 BUILDARGS

The BUILDARGS opens a handle if only a file name was provided.

=head1 BUILD

The BUILD method handles any requirements for reading and processing a
header line.

=head1 METHODS

=head2 read - read a line from the stream end turn it into a class element

=cut

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

