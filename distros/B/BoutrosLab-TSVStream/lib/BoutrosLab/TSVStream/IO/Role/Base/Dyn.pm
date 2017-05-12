=head1 NAME

    BoutrosLab::TSVStream::IO::Role::Base::Dyn

=head1 SYNOPSIS

This is a collection of base attributes and methods used internally
by dynamic TSVStream reader and writer role modules.  It augments
BoutrosLab::IO::Role::Base::Fixed.

=cut

package BoutrosLab::TSVStream::IO::Role::Base::Dyn;

# safe Perl
use warnings;
use strict;
use Carp;

use Moose::Role;
use BoutrosLab::TSVStream::IO::Role::Base::Fixed;
use namespace::autoclean;

with 'BoutrosLab::TSVStream::IO::Role::Base::Fixed';

# Base role for all Dynamic reader/writer variants

has dyn_fields => (
	is      => 'ro',
	isa       => 'ArrayRef[Str]',
	predicate => '_has_dyn_fields',
	writer => '_set_dyn_fields',
	trigger => \&_dyn_fields_set
	);

has _dyn_fields_initialized => (
	is => 'rw',
	isa => 'Bool',
	default => 0
	);

for my $name ( qw( _fixed_start _fixed_end _dyn_start _dyn_end) ) {
	has $name => ( is => 'ro', isa => 'Int', writer => "_set$name" );
	}

sub _dyn_fields_set {
	my( $self, $dyn ) = @_;
	my $fixed_size = scalar(@{$self->fields});
	my $dyn_size = scalar(@$dyn);
	$self->_set_fixed_start(0);
	$self->_set_fixed_end($fixed_size-1);
	$self->_set_dyn_start($fixed_size);
	$self->_set_dyn_end($fixed_size+$dyn_size-1);
	$self->_num_fields($fixed_size+$dyn_size);
	}

sub _extra_names {
	my $self = shift;
	my $cnt  = shift;
	return map { "extra$_" } 1 .. $cnt;
	}

around '_to_fields' => sub {
	my $orig = shift;
	my $self = shift;
	my $obj  = shift;
	unless ($self->_dyn_fields_initialized) {
		$self->_set_dyn_fields( $obj->dyn_fields );
		$self->_dyn_fields_initialized(1);
		}
	return( ($self->$orig($obj), @{ $obj->dyn_values } ) );
	};

around '_read_config' => sub {
	my $orig = shift;
	my $self = shift;
	return ($self->$orig, dyn_fields => $self->dyn_fields);
	};


=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

