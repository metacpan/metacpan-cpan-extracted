package BoutrosLab::TSVStream::IO::Role::Dyn;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose::Role;
use namespace::autoclean;

use BoutrosLab::TSVStream::IO::Reader::Dyn;
use BoutrosLab::TSVStream::IO::Writer::Dyn;

with 'BoutrosLab::TSVStream::IO::Role::Fixed';

=head1 NAME

    BoutrosLab::TSVStreamDyn::IO::Role::Dyn

=head1 SYNOPSIS

	# in a Moose class definition...

	my $_fields = [ qw(foo bar) ];
	sub _fields { return $_fields }

	with 'BoutrosLab::TSVStream::IO::Role::Dyn';

	has 'foo' => ( ... );
	has 'bar' => ( ... );
	...

=head1 DESCRIPTION

This role provides methods to create a file/iostream reader/writer
for a class, using a stream of lines with tab separated fields for
each record, converting to/from an object of the class.  Usually,
the stream will start with an initial line that has the field names
as a tab separated record.

This is essentially the same as a TSVStream::IO::Role::Fixed, but for
a TSVStream::IO::Role::Dyn the list of fixed name fields (which may be
empty), is followed by a dynamically determined list of extra fields.
The entire stream must consistently contain the same number of fields
in each record.

This role provides attributes C<dyn_names> and C<dyn_values>,
which are both arrays of strings.  C<dyn_names> contains the names
of the extra fields that follow the ones specified in _fields.
This attribute will have the same list of names for every record
returned from a single reader object, and should contain the same
list of names for every record passed to a single writer object.
C<dyn_values> is the list of values read or to be written for
each record in a stream (and these can be different, of course).

This role also provided a BUILDARGS wrapper that alows the
constructor to be given field_values=>[fld1,fld2,...] instead of
providing each field explicitly by name.  You can either provide
all of the values (both for the _fields and the dyn_fields) in this
one array, or else you can provide field_values=[fid1,fld2,...] and
dyn_values=>[dyn_1,dyn_2,...] as two separate arguments.

=cut

sub _reader_class {
	return  'BoutrosLab::TSVStream::IO::Reader::Dyn';
	}

sub _writer_class {
	return  'BoutrosLab::TSVStream::IO::Writer::Dyn';
	}

has dyn_fields => (
	is => 'ro',
	required => 1,
	isa => 'ArrayRef[Str]'
	);

has dyn_values => (
	is => 'rw',
	required => 1,
	isa => 'ArrayRef[Str]'
	);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg = ref($_[0]) ? $_[0] : { @_ };
	if (my $field_values = delete $arg->{field_values}) {
		my $fldnames = $class->_fields;
		my @v        = @$field_values;
		if (defined $fldnames && ref($fldnames)) {
			$arg->{ $_ } = shift @v for @$fldnames;
			}
		$arg->{dyn_values} = \@v;
		}
	$class->$orig( $arg );
	};

# add a reader/writer access method for each dynamic fieldname
# (these are not attributes - they modify the values array)

has install_methods => (
	is => 'ro',
	isa => 'Bool',
	default => 0
	);

sub BUILD {
	my $self = shift;
	unless ($self->install_methods) {
		$self->_check_dups( $self->_fields );
		return;
		}

	$self->_check_dups( @{ $self->_fields}, @{ $self->dyn_fields } );

	my $meta = $self->meta;
	my $df = $self->dyn_fields;
	while(my($ind, $fld) = each @$df) {
		$meta->add_method( $fld => sub {
			my $self = shift;
			my $seen = $self->install_methods
				&& grep { $_ eq $fld } @{ $self->dyn_fields };
			# print(
				# "        Validating attribute $fld against: (",
				# join( ', ', @{ $self->dyn_fields } ),
				# ") ",
				# ( $seen ? "good\n" : "BAD\n" )
				# );
			croak( "calling dynamic attribute ($fld) not in this stream" )
			    unless $seen;
			my $values = $self->dyn_values;
			$values->[$ind] = shift if @_;
			$values->[$ind];
			} );
		}
	}


=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

