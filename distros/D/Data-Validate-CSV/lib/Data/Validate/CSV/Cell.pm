use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::Cell;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo::Role;
use Data::Validate::CSV::Types -types;
use Types::Common::Numeric qw( PositiveInt );
use namespace::autoclean;

requires '_chunk_for_key_string';

has raw_value       => ( is => 'ro', isa => Str );
has row_number      => ( is => 'ro', isa => Maybe[PositiveInt] );
has col_number      => ( is => 'ro', isa => Maybe[PositiveInt] );
has row             => ( is => 'ro', isa => Object, weaken => !!1 );
has col             => ( is => 'ro', isa => Object, weaken => !!1, handles => ['datatype'] );

has _errors => (
	is        => 'lazy',
	builder   => sub { [] },
);

sub errors { $_[0]->value; $_[0]->_errors }

has value           => ( is => 'lazy' );
has inflated_value  => ( is => 'lazy' );

sub _build_value {
	my $self = shift;
	$self->col->canonicalize_value($self->_errors, $self->raw_value);
}

sub _build_inflated_value {
	my $self = shift;
	$self->col->inflate_value([], $self->raw_value);
}

1;
