package BoutrosLab::TSVStream::IO::Role::Fixed;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose::Role;
use namespace::autoclean;

use Moose::Util qw(find_meta);

use BoutrosLab::TSVStream::IO::Reader::Fixed;
use BoutrosLab::TSVStream::IO::Writer::Fixed;

=head1 NAME

    BoutrosLab::TSVStream::IO::Role::Fixed

=head1 SYNOPSIS

	# in a Moose class definition...
	use MooseX::ClassAttribute

	class_has '_fields' => (
		is => 'ro',
		isa => 'ArrayRef',
		default => sub { [qw(foo bar)] }
		);

	# # or, without using MooseX::ClassAttribute
	# my $_fields = [ qw(foo bar) ];
	# sub _fields { return $_fields }

	with 'BoutrosLab::TSVStream::IO::Role::Fixed';

	has 'foo' => ( ... );
	has 'bar' => ( ... );
	...

=head1 DESCRIPTION

This role provides methods to create a file/iostream reader/writer
for a class, using a stream of lines with tab separated fields for
each record, converting to/from an object of the class.  Usually,
the stream will start with an initial line that has the field names
as a tab separated record.

This role is also provided a BUILDARGS wrapper that alows the
constructor to be given one element pair in the parameter list:
(field_values=>[val1,val2,...]) instead of providing each field
explicitly by name as (fld1=>val1, fld2=>val2, ...).  In such a
case, the values in the B<field_values> array must be in the same
order as they are listed in the B<_fields> class attribute.

=cut

has [qw(_tsvinternal_pre_header _tsvinternal_pre_comments _tsvinternal_post_comments)] => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [] }
	);

sub _reader_class {
	return  'BoutrosLab::TSVStream::IO::Reader::Fixed';
	}

sub _writer_class {
	return  'BoutrosLab::TSVStream::IO::Writer::Fixed';
	}

sub _hashlist_opt_attr {
	my $self = shift;
	my $attr = shift;
	my $can = $self->can($attr);
	return $can ? %{ $self->$attr } : ();
	}

sub reader {
	my $self = shift;
	my $class = ref($self) || $self;
	return $self->_reader_class()
		->new( { $self->_hashlist_opt_attr('_reader_args'), @_, class => $class } );
	}

sub writer {
	my $self = shift;
	my $class = ref($self) || $self;
	return $self->_writer_class()
		->new( { $self->_hashlist_opt_attr('_writer_args'), @_, class => $class } );
	}

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my $arg = ref($_[0]) ? $_[0] : { @_ };

	if (my $field_values = delete $arg->{field_values}) {
		my @v = @$field_values;
		$arg->{$_} = shift @v for @{ $class->_fields };
		$arg->{dyn_values} = \@v if scalar(@v);
		}
	$class->$orig( $arg );
	};

sub BUILD {
	my $self = shift;
	$self->_check_dups( @{ $self->_fields } );
	}

sub _check_dups {
	my $self = shift;
	my %seen;
	my @dups;
	for my $hdr (@_) {
		push @dups, $hdr if $seen{$hdr}++;
		}
	if (@dups) {
		my $s = (@dups == 1) ? '' : 's';
		croak "field name$s ("
			. join( ', ', @dups)
			. ") seen multiple times in headers ("
			. join( ', ', @_)
			. ")";
		}
	}


=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

