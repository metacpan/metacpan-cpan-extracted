package BoutrosLab::TSVStream::IO::Role::Reader::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;

=head1 NAME

    BoutrosLab::TSVStream::IO::Role::Reader::Fixed

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use List::MoreUtils qw(all);

enum 'ReadHeaderType', [qw(auto none check)];

has header => (
	is      => 'ro',
	lazy    => 1,
	isa     => 'ReadHeaderType',
	default => 'auto'
	);

has extra_class_params => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [] }
	);

has pre_header_pattern => (
	is      => 'ro',
	isa     => 'Maybe[RegexpRef]',
	default => undef
	);

has _is_pre_header => (
	is       => 'ro',
	isa      => 'CodeRef',
	lazy     => 1,
	builder  => '_init_is_pre_header'
	);

sub _init_is_pre_header {
	my $self = shift;
	if (my $pat = $self->pre_header_pattern) {
		sub { $_[0] =~ /$pat/ }
		}
	else {
		$self->_is_comment
		}
	}

has pre_headers => (
	is       => 'ro',
	isa      => 'ArrayRef[Str]',
	init_arg => undef,
	default  => sub { [] }
	);

has _comments => (
	is       => 'ro',
	isa      => 'ArrayRef[Str]',
	init_arg => undef,
	writer  => '_set_comments',
	default  => sub { [] }
	);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg = ref($_[0]) ? $_[0] : { @_ };

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

		pre_header_pattern => 1,
		comment_pattern    => 1
		);
	$arg->{_valid_arg} = \%valid_arg;
	$arg->{_open_mode} = '<';
	$class->$orig( $arg );
	};

sub _read_no_header {
	my $self = shift;
	my $none = $self->header eq 'none';
	( $none, $none );
	}

sub _fill_dyn_fields {
	return;
	}

sub _header {
	my $self          = shift;
	my $stream_fields = shift;
	my $class_fields  = $self->fields;
	return $#$class_fields <= $#$stream_fields
		&& all { uc( $stream_fields->[$_] ) eq uc( $class_fields->[$_] ) } 0 .. $#$class_fields;
	}

sub BUILD {
	my $self = shift;

	my ( $none, $ret ) = $self->_read_no_header;
	return if $ret;

	my @pre;
	my $stream_fields = [];
	my $is_head       = undef;
	print "Starting pre-header checks\n" if $ENV{HEADER_PROCESS};
	if (!$self->_peek) {
		$self->_fill_dyn_fields( $none, 0, $stream_fields );
	}
	else {
		while (my $line = $self->_read) {
			my $is_pre;
			my $lline = $line->{line};

			sub check1 {
				my( $self, $test, $bool, $check, $line ) = @_;
				if ($self->$bool) {
					print "   ",uc($test),($self->$check->($line) ? ":YES" : ":no "), "\n";
					}
				else {
					print "   ",lc($test), "\n";
					}
			}
			print "Checking line: $lline\n" if $ENV{HEADER_PROCESS};
			check1( $self, 'PH', pre_header => _is_pre_header => $lline ) if $ENV{HEADER_PROCESS};
			check1( $self, 'PC', pre_comment => _is_comment => $lline ) if $ENV{HEADER_PROCESS};
			check1( $self, 'CO', comment => _is_comment => $lline ) if $ENV{HEADER_PROCESS};

			if ($self->pre_header) {
				$is_pre = $self->_is_pre_header->($lline);
				$is_pre ||= $self->_is_comment->($lline) if $self->pre_comment;
				}
			else {
				$is_pre = $self->_is_comment->($lline) if $self->comment;
				}
			if ($is_pre) {
				print "   -> pre\n" if $ENV{HEADER_PROCESS};
				push @pre, $line;
				next;
				}
			$stream_fields = $self->header_fix->($line)->{fields};
			# $stream_fields = $line->{fields};
			$is_head       = $self->_header($stream_fields);
			print "   -> NOT pre, none: $none, is_head: $is_head, header_proc: ",$self->header,"\n" if $ENV{HEADER_PROCESS};
			$self->_fill_dyn_fields( $none, $is_head, $stream_fields );
			if ($none or !$is_head && $self->header eq 'auto') {
				print "   *** put back\n" if $ENV{HEADER_PROCESS};
				$self->_unread( @pre, $line );
				return;
				}
			last;
			}

		print "   *** kept\n" if $ENV{HEADER_PROCESS};
		my $die = $self->_num_fields != scalar(@$stream_fields);

		if ($die || !$is_head) {
			my $error = '';
			$error = 'Headers do not match' if !$is_head;
			$error .= ' and wrong number of fields' if $die;
			$error =~ s/^ and w/W/;
			$self->_croak( $error, $stream_fields );
			}
		push @{ $self->pre_headers }, ( map { $_->{line} } @pre );
		}
	}

sub read_comments {
	my $self     = shift;
	my $comments = $self->_comments;
	$self->_set_comments( [] );
	return $comments;
	}

sub _load_comments {
	my $self = shift;
	return unless $self->comment;
	my $comments = $self->_comments;
	while (my $line = $self->_read)  {
		if (! $self->_is_comment->( $line->{line} )) {
			$self->_unread($line);
			return;
			}
		push @$comments, $line->{line};
		}
	}

sub read {
	my $self = shift;
	$self->_load_comments;
	return unless my $values = $self->_read;
	my $line = $values->{line};
	$values = $values->{fields};
	my $error;
	my $obj;
	$error = 'Wrong number of fields' if scalar(@$values) != $self->_num_fields;

	unless ($error) {
		eval {
			$obj = $self->class->new(
				field_values => $values,
				@{ $self->extra_class_params },
				$self->_read_config
				);
			};
		$error = $@ if $@;
		}

	$self->_croak( $error, $values ) if $error;

	return $obj;
	}

sub filter {
	my ( $self, $filtersub ) = @_;
	return BoutrosLab::TSVStream::IO::Role::Reader::Filter->new(
		reader    => $self,
		filtersub => $filtersub
		);
	}

package BoutrosLab::TSVStream::IO::Role::Reader::Filter;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose;

has reader => (
	is       => 'ro',
	isa      => 'Object',
	required => 1
	);

has filtersub => (
	is       => 'ro',
	isa      => 'CodeRef',
	required => 1
	);

sub read {
	my $self = shift;
	while (my $record = $self->reader->read) {
		return $record if $self->filtersub->($record);
		}
	return;
	}

sub filter {
	my ( $self, $filtersub ) = @_;
	return BoutrosLab::TSVStream::IO::Role::Reader::Filter->new(
		reader    => $self,
		filtersub => $filtersub
		);
	}

=head1 SYNOPSIS

	$class->reader( ... );

	# ($class will use the role BoutrosLab::TSVStream which will provide
	# the reader method, that method will return a Reader object with:
	# ...
	# return BoutrosLab::TSVStream::IO::Role::Reader::Fixed->new(
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
