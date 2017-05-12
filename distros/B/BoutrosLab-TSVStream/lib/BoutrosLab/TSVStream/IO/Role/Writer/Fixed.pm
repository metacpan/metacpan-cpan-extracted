package BoutrosLab::TSVStream::IO::Role::Writer::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;

use BoutrosLab::TSVStream::IO::Role::Base::Fixed;

=head1 NAME

    BoutrosLab::TSVStream:Writer

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use List::MoreUtils qw(all zip);
use Try::Tiny;

with 'BoutrosLab::TSVStream::IO::Role::Base::Fixed';

has append => ( is => 'ro', lazy => 1, isa => 'Bool', default => '0' );

enum 'WriteHeaderType', [qw(write skip)];

has header => (
	is      => 'ro',
	lazy    => 1,
	isa     => 'WriteHeaderType',
	default => sub { my $self = shift; $self->append ? 'skip' : 'write' }
	);

has pre_headers => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [] }
	);

has extra_class_params => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [] }
	);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg   = ref($_[0]) ? $_[0] : { @_ };

	my %valid_arg = (
		file               => 1,
		handle             => 1,
		header             => 1,
		class              => 1,
		comment            => 1,
		pre_comment        => 1,
		pre_header         => 1,
		header_fix         => 1,
		extra_class_params => 1,

		pre_headers        => 1,
		append             => 1,
		dyn_fields         => 1
		);
	$arg->{_valid_arg} = \%valid_arg;
	$arg->{_open_mode} = $arg->{append} ? '>>' : '>';
	$class->$orig( $arg );
	};

sub _list_headers {
	my $self = shift;
	return ( $self->fields );
	}

sub BUILD {
	my $self = shift;
	$self->_write_lines( $self->pre_headers ) if $self->pre_header;
	if ($self->header eq 'write') {
		$self->_write_fields( @{ $self->header_fix->( $self->_list_headers ) } );
		}
	}

sub _build_object {
	my $self = shift;
	my $obj  = ref($_[0]) ? shift : [ @_ ];
	if (ref($obj) eq 'ARRAY') {
		$obj = $self->class->new(
			field_values => $obj,
			@{ $self->extra_class_params },
			$self->_read_config
			);
		}
	elsif (ref($obj) ne $self->class) {
		my @altlist;
		# assume that we got some class of object that is compatible
		# with our own class.  Get its contents and create our own
		# class object from those contents.  This will usually be
		# done to coerce format conversions.
		try {
			@altlist = ( $self->_to_fields($obj) );
			$obj = $self->class->new(
				field_values => \@altlist,
				@{ $self->extra_class_params },
				$self->_read_config
				);
			}
		catch {
			my $error = $_;
			$self->_croak(
				"Arg to write must be a "
				. $self->class
				. " object, another object that has the same set of "
				. "fixed and dynamic fields with compatible contents, "
				. "or an array of strings, found: "
				. ref($obj)
				. " and when trying to convert by field access got error: $error"
				);
			}
		}
	return $obj;
}

sub write_comments {
	my $self = shift;
	$self->_write_lines(@_) if $self->comment;
	}

sub write {
	my $self = shift;
	my $obj  = $self->_build_object( @_ );
	# $self->_write_lines( $obj->read_comments ) if $self->comment;
	my @list;
	@list = ( $self->_to_fields($obj) );
	$self->_croak( 'Wrong number of fields', @list )
		unless scalar(@list) == $self->_num_fields;
	$self->_write_fields( @list );
	}

sub filter {
	my ( $self, $filtersub ) = @_;
	return BoutrosLab::TSVStream::IO::Role::Writer::Filter->new(
		writer    => $self,
		filtersub => $filtersub
		);
	}

package BoutrosLab::TSVStream::IO::Role::Writer::Filter;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;

has writer => (
	is       => 'ro',
	isa      => 'Object',
	required => 1
	);

has filtersub => (
	is       => 'ro',
	isa      => 'CodeRef',
	required => 1
	);

sub write {
	my $self = shift;
	my $obj  = $self->writer->_build_object( @_ );
	$self->writer->write( $obj ) if $self->filtersub->($obj);
	}

sub filter {
	my ( $self, $filtersub ) = @_;
	return BoutrosLab::TSVStream::IO::Role::Writer::Filter->new(
		writer    => $self,
		filtersub => $filtersub
		);
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

